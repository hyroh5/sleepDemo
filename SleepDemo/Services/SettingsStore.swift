import Foundation

/// 앱 안에서 입력받는 설정. API 키는 Keychain, 환경(test/live)은 UserDefaults에 둔다.
@MainActor
final class SettingsStore: ObservableObject {
    static let environments = ["test", "live"]

    @Published private(set) var apiKey: String
    @Published private(set) var environment: String

    private let keyAccount = "asleepAPIKey"
    private let environmentKey = "asleepEnvironment"

    init() {
        apiKey = KeychainStore.get(keyAccount) ?? ""
        let saved = UserDefaults.standard.string(forKey: environmentKey)
        environment = saved.flatMap { Self.environments.contains($0) ? $0 : nil } ?? "test"
    }

    func save(apiKey: String, environment: String) {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainStore.set(trimmed, account: keyAccount)
        UserDefaults.standard.set(environment, forKey: environmentKey)
        self.apiKey = trimmed
        self.environment = environment
    }
}
