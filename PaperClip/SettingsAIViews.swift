import SwiftUI

struct AISettingsView: View {
    @State var apiKey: String
    @State var doubaoEndpointID: String
    @State var deepSeekAPIKey: String
    @State var lastSavedSettings: AISettingsSnapshot
    @State private var isAPIKeyVisible = false
    @State private var isDeepSeekAPIKeyVisible = false
    @State var settingsSaveAction = DebouncedAction()

    init() {
        let apiKey = KeychainService.load(for: .doubaoAPIKey) ?? ""
        let doubaoEndpointID = AIService.migratedDoubaoInferenceID(
            AIService.storedDoubaoInferenceID()
        )
        let deepSeekAPIKey = KeychainService.load(for: .deepSeekAPIKey) ?? ""
        let settings = AISettingsSnapshot(
            apiKey: apiKey,
            doubaoEndpointID: doubaoEndpointID,
            deepSeekAPIKey: deepSeekAPIKey
        )

        _apiKey = State(initialValue: apiKey)
        _doubaoEndpointID = State(initialValue: doubaoEndpointID)
        _deepSeekAPIKey = State(initialValue: deepSeekAPIKey)
        _lastSavedSettings = State(initialValue: settings)
    }

    var body: some View {
        Form {
            AIKeySettingsSection(
                apiKey: $apiKey,
                deepSeekAPIKey: $deepSeekAPIKey,
                isAPIKeyVisible: $isAPIKeyVisible,
                isDeepSeekAPIKeyVisible: $isDeepSeekAPIKeyVisible
            )

            DoubaoEndpointSettingsSection(doubaoEndpointID: $doubaoEndpointID)

            DeepSeekModelSettingsSection()

        }
        .navigationTitle("AI 解析设置")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: currentSettingsSnapshot) {
            scheduleSettingsSave()
        }
        .onDisappear {
            settingsSaveAction.cancel()
            saveSettings()
        }
    }
}
