import AsleepSDK
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SleepViewModel()
    @State private var dimmed = false
    @State private var savedBrightness: CGFloat = 0.5
    @State private var showHistory = false
    @State private var showSettings = false

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
        .sheet(isPresented: $showHistory) {
            HistoryView(store: vm.store, refetch: { vm.refetch(sessionId: $0) })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: vm.settings, onSave: vm.prepare)
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
            case .needsKey:
                Text("Asleep API 키를 입력해야 시작할 수 있습니다.")
                    .multilineTextAlignment(.center)
                Button("API 키 입력") { showSettings = true }
                    .buttonStyle(.borderedProminent)
            case .preparing:
                ProgressView("준비 중…")
            case .ready:
                Text("폰을 베개 옆 가까이에 두고\n측정을 시작하세요.\n(최소 5분)")
                    .multilineTextAlignment(.center)
                Button("측정 시작", action: vm.start)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("이전 기록") { showHistory = true }
                    .buttonStyle(.bordered)
                Button("설정 (\(vm.settings.environment))") { showSettings = true }
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
                Button("설정") { showSettings = true }
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
