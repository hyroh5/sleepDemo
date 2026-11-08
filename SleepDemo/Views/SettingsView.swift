import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = ""
    @State private var environment = "test"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API 키", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("환경", selection: $environment) {
                        ForEach(SettingsStore.environments, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("키는 이 기기의 Keychain에만 저장됩니다. 환경은 키의 종류와 같아야 하고, 기록에 함께 저장됩니다. 환경을 바꾸면 사용자 등록이 새로 됩니다.")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        settings.save(apiKey: apiKey, environment: environment)
                        dismiss()
                        onSave()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                apiKey = settings.apiKey
                environment = settings.environment
            }
        }
    }
}
