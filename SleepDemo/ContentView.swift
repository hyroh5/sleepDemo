import AsleepSDK
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SleepViewModel()
    @State private var dimmed = false
    @State private var savedBrightness: CGFloat = 0.5

    var body: some View {
        ZStack {
            content
            if dimmed {
                // 완전한 검은 화면. 화면을 탭하면 돌아온다.
                Color.black
                    .ignoresSafeArea()
                    .persistentSystemOverlays(.hidden)
                    .onTapGesture { setDimmed(false) }
            }
        }
        .statusBarHidden(dimmed)
        .onChange(of: vm.phase) { phase in
            if phase != .tracking { setDimmed(false) }
        }
    }

    private func setDimmed(_ on: Bool) {
        guard on != dimmed else { return }
        if on {
            savedBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 0
        } else {
            UIScreen.main.brightness = savedBrightness
        }
        dimmed = on
    }

    private var content: some View {
        VStack(spacing: 24) {
            switch vm.phase {
            case .preparing:
                ProgressView("준비 중…")
            case .ready:
                Text("폰을 베개 옆 가까이에 두고\n측정을 시작하세요.\n(최소 5분)")
                    .multilineTextAlignment(.center)
                Button("측정 시작", action: vm.start)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            case .tracking:
                Text(format(vm.elapsed))
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                Text("업로드 \(vm.uploadCount)회 · 중단 \(vm.interruptCount)회")
                    .foregroundStyle(.secondary)
                Text("잠금 버튼으로 화면을 끄지 말고 충전기에 꽂아 두세요.\n\"화면 어둡게\"를 누르면 검은 화면이 뜨고, 탭하면 돌아옵니다.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("화면 어둡게") { setDimmed(true) }
                    .buttonStyle(.bordered)
                Button("측정 종료", role: .destructive, action: vm.stop)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            case .analyzing:
                ProgressView("분석 중…")
            case .result:
                if let report = vm.report {
                    ReportView(report: report)
                }
                Button("다시 측정", action: vm.reset)
                    .buttonStyle(.bordered)
            case .failed(let message):
                Text(message).multilineTextAlignment(.center)
                Button("다시 시도", action: vm.prepare)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { vm.prepare() }
    }

    private func format(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d:%02d", s / 3600, s % 3600 / 60, s % 60)
    }
}

struct ReportView: View {
    let report: Asleep.Model.Report

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                row("누락 데이터 비율", String(format: "%.0f%%", report.missingDataRatio * 100))
                if let stat = report.stat {
                    row("수면 효율", stat.sleepEfficiency.map { String(format: "%.0f%%", $0 * 100) })
                    row("총 수면 시간", minutes(stat.timeInSleep))
                    row("깸", minutes(stat.timeInWake))
                    row("얕은 수면", minutes(stat.timeInLight))
                    row("깊은 수면", minutes(stat.timeInDeep))
                    row("REM", minutes(stat.timeInRem))
                    row("코골이 횟수", stat.snoringCount.map(String.init))
                    row("코골이 비율", stat.snoringRatio.map { String(format: "%.0f%%", $0 * 100) })
                } else {
                    Text("통계가 없습니다. (\(report.peculiarities.map { "\($0)" }.joined(separator: ", ")))")
                }
                if let stages = report.session.sleepStages, !stages.isEmpty {
                    Text("수면 단계").font(.headline).padding(.top)
                    StageBar(stages: stages)
                }
            }
            .padding()
        }
    }

    private func row(_ title: String, _ value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "-").foregroundStyle(.secondary)
        }
    }

    // SDK의 시간 값은 초 단위로 가정한다.
    private func minutes(_ seconds: Int?) -> String? {
        seconds.map { "\($0 / 60)분" }
    }
}

struct StageBar: View {
    let stages: [Int]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stages.enumerated()), id: \.offset) { _, s in
                Rectangle().fill(color(s))
            }
        }
        .frame(height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // -1 오류, 0 깸, 1 얕음, 2 깊음, 3 REM
    private func color(_ s: Int) -> Color {
        switch s {
        case 0: return .orange
        case 1: return .cyan
        case 2: return .indigo
        case 3: return .purple
        default: return .gray
        }
    }
}
