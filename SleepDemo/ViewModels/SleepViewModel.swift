import AsleepSDK
import SwiftUI
import UIKit

@MainActor
final class SleepViewModel: NSObject, ObservableObject {
    enum Phase: Equatable {
        case needsKey
        case preparing
        case ready
        case tracking
        case analyzing
        case result
        case failed(String)
    }

    @Published var phase: Phase = .preparing
    @Published var elapsed: TimeInterval = 0
    @Published var uploadCount = 0
    @Published var interruptCount = 0
    @Published var summary: ReportSummary?

    private var config: Asleep.Config?
    private var manager: Asleep.SleepTrackingManager?
    private var timer: Timer?
    private var startedAt: Date?
    private var endedAt: Date?
    let store = RecordStore()
    let settings = SettingsStore()
    // test/live는 사용자 데이터가 따로 관리되므로 환경마다 userId를 따로 저장한다.
    private var userIdKey: String { "asleepUserId.\(settings.environment)" }

    func prepare() {
        guard !settings.apiKey.isEmpty else {
            phase = .needsKey
            return
        }
        phase = .preparing
        Asleep.setup(apiKey: settings.apiKey, delegate: self)
    }

    func start() {
        guard let config else { return }
        uploadCount = 0
        interruptCount = 0
        elapsed = 0
        summary = nil
        manager = Asleep.createSleepTrackingManager(config: config, delegate: self, recordingPath: nil)
        manager?.startTracking()
        startedAt = Date()
        endedAt = nil
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(startedAt)
            }
        }
        // 화면이 잠기면 업로드가 끊겨서 측정 중에는 화면을 켜 둔다.
        UIApplication.shared.isIdleTimerDisabled = true
        phase = .tracking
    }

    func stop() {
        manager?.stopTracking()
        endedAt = Date()
        stopTimer()
        phase = .analyzing
    }

    func showSample() {
        summary = .sample
        phase = .result
    }

    func reset() {
        summary = nil
        phase = .ready
    }

    private func stopTimer() {
        UIApplication.shared.isIdleTimerDisabled = false
        timer?.invalidate()
        timer = nil
    }

    private func fail(_ message: String) {
        stopTimer()
        phase = .failed(message)
    }

    /// 기록 화면에서 호출. 화면 상태(phase)는 건드리지 않고 저장소만 갱신한다.
    func refetch(sessionId: String) {
        loadReport(sessionId: sessionId, showResult: false)
    }

    private func loadReport(sessionId: String, showResult: Bool = true) {
        guard let config else { return }
        let reports = Asleep.createReports(config: config)
        Task {
            do {
                let report = try await reports.report(sessionId: sessionId)
                let old = store.record(id: sessionId)
                let record = SleepRecord(
                    report: report,
                    startedAt: old?.startedAt ?? self.startedAt ?? Date(),
                    endedAt: old?.endedAt ?? self.endedAt ?? Date(),
                    // 다시 조회할 때도 처음 측정한 환경을 유지한다.
                    environment: old?.environment ?? settings.environment
                )
                store.upsert(record)
                if showResult {
                    self.summary = ReportSummary(record: record)
                    self.phase = .result
                }
            } catch {
                // 세션은 pending으로 저장돼 있어서 기록 화면에서 다시 조회할 수 있다.
                if showResult { self.fail("리포트를 가져오지 못했습니다. 이전 기록에서 다시 조회할 수 있습니다: \(error)") }
            }
        }
    }
}

extension SleepViewModel: AsleepSetupDelegate, AsleepConfigDelegate {
    nonisolated func setupDidComplete() {
        Task { @MainActor in
            Asleep.initAsleepConfig(userId: UserDefaults.standard.string(forKey: userIdKey), delegate: self)
        }
    }

    nonisolated func setupDidFail(error: Asleep.AsleepError) {
        Task { @MainActor in fail("SDK 설정 실패: \(error)") }
    }

    nonisolated func setupInProgress(progress: Int) {}

    nonisolated func userDidJoin(userId: String, config: Asleep.Config) {
        Task { @MainActor in
            UserDefaults.standard.set(userId, forKey: userIdKey)
            self.config = config
            phase = .ready
        }
    }

    nonisolated func didFailUserJoin(error: Asleep.AsleepError) {
        Task { @MainActor in fail("사용자 등록 실패: \(error)") }
    }

    nonisolated func userDidDelete(userId: String) {}
}

extension SleepViewModel: AsleepCompletableTrackingDelegate {
    nonisolated func didCreate() {}
    nonisolated func didCreate(sessionId: String) {
        // 리포트를 못 받아도 나중에 조회할 수 있도록 세션 ID부터 저장한다.
        Task { @MainActor in
            store.upsert(SleepRecord(pendingId: sessionId, startedAt: startedAt ?? Date(), environment: settings.environment))
        }
    }

    nonisolated func didUpload(sequence: Int) {
        Task { @MainActor in uploadCount = sequence }
    }

    nonisolated func didClose(sessionId: String) {}

    nonisolated func didComplete(session: Asleep.Model.Session) {
        Task { @MainActor in loadReport(sessionId: session.id) }
    }

    nonisolated func didFail(error: Asleep.AsleepError) {
        Task { @MainActor in
            // 분석 대기 시간 초과는 측정 실패가 아니라서 세션 ID로 나중에 조회해야 한다.
            fail("측정 오류: \(error)")
        }
    }

    nonisolated func didInterrupt() {
        Task { @MainActor in interruptCount += 1 }
    }
    nonisolated func didResume() {}

    nonisolated func micPermissionWasDenied() {
        Task { @MainActor in fail("마이크 권한이 필요합니다. 설정에서 허용해 주세요.") }
    }

    nonisolated func analysing(session: Asleep.Model.Session) {}
}
