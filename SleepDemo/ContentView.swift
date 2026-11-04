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
                Button("샘플 결과 보기", action: vm.showSample)
                    .buttonStyle(.bordered)
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
                if let summary = vm.summary {
                    ReportView(summary: summary)
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
    let summary: ReportSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if summary.isSample {
                    Text("샘플 데이터 · 실제 측정값이 아닙니다")
                        .font(.footnote.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange.opacity(0.25)))
                }
                ForEach(Array(summary.rows.enumerated()), id: \.offset) { _, r in
                    HStack {
                        Text(r.title)
                        Spacer()
                        Text(r.value).foregroundStyle(.secondary)
                    }
                }
                if let reason = summary.emptyReason {
                    Text(reason)
                }
                if !summary.stages.isEmpty {
                    Text("수면 단계").font(.headline).padding(.top)
                    StageBar(stages: summary.stages)
                    HStack(spacing: 12) {
                        legend("깸", .orange)
                        legend("얕음", .cyan)
                        legend("깊음", .indigo)
                        legend("REM", .purple)
                    }
                    .font(.caption)
                }
            }
            .padding()
        }
    }

    private func legend(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
        }
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
