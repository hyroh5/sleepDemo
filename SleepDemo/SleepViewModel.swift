import AsleepSDK
import SwiftUI
import UIKit

@MainActor
final class SleepViewModel: NSObject, ObservableObject {
    enum Phase: Equatable {
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
    @Published var report: Asleep.Model.Report?

    private var config: Asleep.Config?
    private var manager: Asleep.SleepTrackingManager?
    private var timer: Timer?
    private var startedAt: Date?
    private let userIdKey = "asleepUserId"

    func prepare() {
        guard !Secrets.asleepAPIKey.isEmpty else {
            phase = .failed("Secrets.swift에 API 키를 입력하세요.")
            return
        }
        phase = .preparing
        Asleep.setup(apiKey: Secrets.asleepAPIKey, delegate: self)
    }

    func start() {
        guard let config else { return }
        uploadCount = 0
        elapsed = 0
        report = nil
        manager = Asleep.createSleepTrackingManager(config: config, delegate: self, recordingPath: nil)
        manager?.startTracking()
        startedAt = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(startedAt)
            }
        }
        phase = .tracking
    }

    func stop() {
        manager?.stopTracking()
        stopTimer()
        phase = .analyzing
    }

    func reset() {
        report = nil
        phase = .ready
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func fail(_ message: String) {
        stopTimer()
        phase = .failed(message)
    }

    private func loadReport(sessionId: String) {
        guard let config else { return }
        let reports = Asleep.createReports(config: config)
        Task {
            do {
                self.report = try await reports.report(sessionId: sessionId)
                self.phase = .result
            } catch {
                self.fail("리포트를 가져오지 못했습니다: \(error)")
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
    nonisolated func didCreate(sessionId: String) {}

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

    nonisolated func didInterrupt() {}
    nonisolated func didResume() {}

    nonisolated func micPermissionWasDenied() {
        Task { @MainActor in fail("마이크 권한이 필요합니다. 설정에서 허용해 주세요.") }
    }

    nonisolated func analysing(session: Asleep.Model.Session) {}
}
