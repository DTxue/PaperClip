import SwiftUI

struct AIKeySettingsSection: View {
    @Binding var apiKey: String
    @Binding var deepSeekAPIKey: String
    @Binding var isAPIKeyVisible: Bool
    @Binding var isDeepSeekAPIKeyVisible: Bool

    var body: some View {
        Section {
            SecureSettingsField(
                title: "火山方舟 API Key",
                systemImage: "key",
                tint: .blue,
                text: $apiKey,
                isVisible: $isAPIKeyVisible
            )

            SecureSettingsField(
                title: "DeepSeek API Key",
                systemImage: "key.fill",
                tint: .purple,
                text: $deepSeekAPIKey,
                isVisible: $isDeepSeekAPIKeyVisible
            )
        } header: { Text("API 密钥") } footer: {
            Text("密钥仅保存在本机 Keychain，供日记、知识库和 ENG 功能使用。")
        }
    }
}

struct DoubaoEndpointSettingsSection: View {
    @Binding var doubaoEndpointID: String

    var body: some View {
        Section {
            TextField("豆包模型或推理接入点 ID", text: $doubaoEndpointID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
        } header: { Text("豆包模型") } footer: {
            Text("豆包负责图片理解。默认使用 Doubao-Seed-2.1-pro（\(AIService.defaultDoubaoInferenceID)）。")
        }
    }
}

struct DeepSeekModelSettingsSection: View {
    var body: some View {
        Section {
            Text("已锁定使用官方默认配置")
                .foregroundStyle(.secondary)
        } header: { Text("DeepSeek V4 Pro") } footer: {
            Text("DeepSeek 请求默认使用官方 \(AIService.defaultDeepSeekInferenceID) 模型。")
        }
    }
}
