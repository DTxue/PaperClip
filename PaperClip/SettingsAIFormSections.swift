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
            Text("密钥仅保存在本机 Keychain。题目图片只发送给豆包进行识别；确认后的题目文字按你的选择发送给豆包或 DeepSeek 解析。")
        }
    }
}

struct DoubaoEndpointSettingsSection: View {
    @Binding var doubaoEndpointID: String

    var body: some View {
        Section {
            TextField("豆包推理接入点 ID", text: $doubaoEndpointID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
        } header: { Text("图片理解接入点") } footer: {
            Text("豆包负责图片识别，也可在题目确认后负责解析。默认使用 \(AIService.defaultDoubaoInferenceID)。")
        }
    }
}

struct DeepSeekModelSettingsSection: View {
    var body: some View {
        Section {
            Text("已锁定使用官方默认配置")
                .foregroundStyle(.secondary)
        } header: { Text("DeepSeek V4 Pro") } footer: {
            Text("系统批阅作文将默认使用 DeepSeek 官方 \(AIService.defaultDeepSeekInferenceID) 模型。")
        }
    }
}

struct AIConnectionTestSection: View {
    let isTestingConnection: Bool
    let canTestDoubao: Bool
    let canTestDeepSeek: Bool
    let onTestDoubao: () -> Void
    let onTestDeepSeek: () -> Void

    var body: some View {
        Section {
            ConnectionTestButton(
                title: "测试豆包连接",
                systemImage: "network",
                isTesting: isTestingConnection,
                action: onTestDoubao
            )
            .disabled(!canTestDoubao)

            ConnectionTestButton(
                title: "测试 DeepSeek 连接",
                systemImage: "brain.head.profile",
                isTesting: isTestingConnection,
                action: onTestDeepSeek
            )
            .disabled(!canTestDeepSeek)
        } footer: {
            Text("豆包测试会上传本地生成的简单题目图片；DeepSeek 测试只发送测试题目文字。两项测试都不会读取或上传 PDF。")
        }
    }
}

struct AIAnalysisFlowSection: View {
    var body: some View {
        Section("解析流程") {
            Label("框选 PDF 中的一道题目", systemImage: "viewfinder")
            Label("豆包识别图片，学生确认题目内容", systemImage: "text.viewfinder")
            Label("选择豆包或 DeepSeek 完成解析", systemImage: "brain")
            Label("返回思路、步骤、答案和易错点", systemImage: "checklist")
        }
    }
}
