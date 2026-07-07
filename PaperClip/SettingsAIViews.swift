import SwiftUI

struct AISettingsView: View {
    @State var apiKey: String
    @State var doubaoEndpointID: String
    @State var deepSeekAPIKey: String
    @State var lastSavedSettings: AISettingsSnapshot
    @State private var isAPIKeyVisible = false
    @State private var isDeepSeekAPIKeyVisible = false
    @State var isTestingConnection = false
    @State var connectionTestAlert: AppAlert?
    @State var settingsSaveAction = DebouncedAction()
    @State var connectionTestTaskSlot = ViewTaskSlot()

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

            AIConnectionTestSection(
                isTestingConnection: isTestingConnection,
                canTestDoubao: canTestDoubaoConnection,
                canTestDeepSeek: canTestDeepSeekConnection,
                onTestDoubao: startDoubaoConnectionTest,
                onTestDeepSeek: startDeepSeekConnectionTest
            )

            AIAnalysisFlowSection()
        }
        .navigationTitle("AI 解析设置")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: currentSettingsSnapshot) {
            cancelConnectionTest()
            scheduleSettingsSave()
        }
        .onDisappear {
            settingsSaveAction.cancel()
            cancelConnectionTest()
            saveSettings()
        }
        .appAlert($connectionTestAlert)
    }
}
