import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("学习") {
                NavigationLink {
                    LearningSettingsView()
                } label: {
                    Label("学习设置", systemImage: "graduationcap")
                }
            }
            Section("功能") {
                NavigationLink {
                    AISettingsView()
                } label: {
                    Label("AI 解析设置", systemImage: "brain")
                }
            }
        }
        .navigationTitle("设置")
    }
}

// MARK: - Learning Settings

struct LearningSettingsView: View {
    @AppStorage("defaultGrade") private var defaultGrade = Grade.grade7.rawValue
    @AppStorage("defaultSemester") private var defaultSemester = Semester.first.rawValue
    @AppStorage("preferredSubjects") private var preferredSubjectsRaw = ""

    private var selectedSubjects: Set<String> {
        Set(preferredSubjectsRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    var body: some View {
        Form {
            Section {
                Picker("年级", selection: $defaultGrade) {
                    ForEach(Grade.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("学期", selection: $defaultSemester) {
                    ForEach(Semester.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
            } header: {
                Text("新建错题卡默认值")
            } footer: {
                Text("框选错题时自动填入的年级和学期，可在编辑错题卡时修改。")
            }

            Section {
                ForEach(Subject.allCases) { subject in
                    Toggle(subject.rawValue, isOn: Binding(
                        get: { selectedSubjects.contains(subject.rawValue) },
                        set: { isOn in
                            var set = selectedSubjects
                            if isOn { set.insert(subject.rawValue) } else { set.remove(subject.rawValue) }
                            preferredSubjectsRaw = set.sorted().joined(separator: ",")
                        }
                    ))
                }
            } header: {
                Text("常用学科")
            } footer: {
                if selectedSubjects.isEmpty {
                    Text("未勾选任何学科，编辑器将显示全部学科。")
                } else {
                    Text("编辑器学科选择器只显示已勾选的 \(selectedSubjects.count) 个学科。有数据的学科始终在错题库中可见。")
                }
            }
        }
        .navigationTitle("学习设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AISettingsView: View {
    @State private var apiKey: String
    @State private var doubaoEndpointID: String
    @State private var deepSeekEndpointID: String
    @State private var isAPIKeyVisible = false
    @State private var isTestingConnection = false
    @State private var connectionTestResult: ConnectionTestResult?

    private struct ConnectionTestResult: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    init() {
        _apiKey = State(initialValue: KeychainService.load(for: .doubaoAPIKey) ?? "")
        let storedModel = KeychainService.load(for: .doubaoModelID)
            ?? KeychainService.load(for: .doubaoVisionEndpoint)
        _doubaoEndpointID = State(
            initialValue: AIService.migratedDoubaoInferenceID(storedModel)
        )
        _deepSeekEndpointID = State(
            initialValue: KeychainService.load(for: .deepSeekModelID)
                ?? AIService.defaultDeepSeekInferenceID
        )
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "key")
                        .foregroundStyle(.blue)
                        .frame(width: 28)

                    Group {
                        if isAPIKeyVisible {
                            TextField("火山方舟 API Key", text: $apiKey)
                        } else {
                            SecureField("火山方舟 API Key", text: $apiKey)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button {
                        isAPIKeyVisible.toggle()
                    } label: {
                        Image(systemName: isAPIKeyVisible ? "eye.slash" : "eye")
                    }
                    .accessibilityLabel(isAPIKeyVisible ? "隐藏 API Key" : "显示 API Key")
                }
            } header: {
                Text("API 密钥")
            } footer: {
                Text("密钥仅保存在本机 Keychain。题目图片只发送给豆包进行识别；确认后的题目文字按你的选择发送给豆包或 DeepSeek 解析。")
            }

            Section {
                TextField("豆包推理接入点 ID", text: $doubaoEndpointID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
            } header: {
                Text("图片理解接入点")
            } footer: {
                Text("豆包负责图片识别，也可在题目确认后负责解析。默认使用 \(AIService.defaultDoubaoInferenceID)。")
            }

            Section {
                TextField("DeepSeek 推理接入点 ID", text: $deepSeekEndpointID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
            } header: {
                Text("DeepSeek V4 Pro")
            } footer: {
                Text("默认使用火山方舟 DeepSeek V4 Pro 接入点 \(AIService.defaultDeepSeekInferenceID)。")
            }

            Section {
                Button {
                    Task {
                        await testDoubaoConnection()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isTestingConnection {
                            ProgressView()
                                .controlSize(.small)
                            Text("正在测试…")
                        } else {
                            Label("测试豆包连接", systemImage: "network")
                        }
                        Spacer()
                    }
                }
                .disabled(
                    isTestingConnection
                        || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || doubaoEndpointID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                Button {
                    Task {
                        await testDeepSeekConnection()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label("测试 DeepSeek 连接", systemImage: "brain.head.profile")
                        Spacer()
                    }
                }
                .disabled(
                    isTestingConnection
                        || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || deepSeekEndpointID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            } footer: {
                Text("豆包测试会上传本地生成的简单题目图片；DeepSeek 测试只发送测试题目文字。两项测试都不会读取或上传 PDF。")
            }

            Section("解析流程") {
                Label("框选 PDF 中的一道题目", systemImage: "viewfinder")
                Label("豆包识别图片，学生确认题目内容", systemImage: "text.viewfinder")
                Label("选择豆包或 DeepSeek 完成解析", systemImage: "brain")
                Label("返回思路、步骤、答案和易错点", systemImage: "checklist")
            }
        }
        .navigationTitle("AI 解析设置")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: apiKey)          { saveSettings() }
        .onChange(of: doubaoEndpointID) { saveSettings() }
        .onChange(of: deepSeekEndpointID) { saveSettings() }
        .alert(item: $connectionTestResult) { result in
            Alert(
                title: Text(result.title),
                message: Text(result.message),
                dismissButton: .default(Text("好"))
            )
        }
    }

    private func saveSettings() {
        apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        doubaoEndpointID = AIService.migratedDoubaoInferenceID(doubaoEndpointID)
        deepSeekEndpointID = deepSeekEndpointID.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        KeychainService.save(apiKey, for: .doubaoAPIKey)
        KeychainService.save(doubaoEndpointID, for: .doubaoModelID)
        KeychainService.save(deepSeekEndpointID, for: .deepSeekModelID)
    }

    @MainActor
    private func testDoubaoConnection() async {
        saveSettings()
        isTestingConnection = true
        defer { isTestingConnection = false }

        do {
            let result = try await AIService.recognize(image: connectionTestImage())
            connectionTestResult = ConnectionTestResult(
                title: "连接成功",
                message: "豆包已成功识别测试题目：\(result.recognizedQuestion)"
            )
        } catch {
            connectionTestResult = ConnectionTestResult(
                title: "连接失败",
                message: error.localizedDescription
            )
        }
    }

    @MainActor
    private func testDeepSeekConnection() async {
        saveSettings()
        isTestingConnection = true
        defer { isTestingConnection = false }

        let recognition = AIQuestionRecognition(
            recognizedQuestion: "计算：1 + 1 = ?",
            subject: "数学",
            questionType: "计算题",
            knowledgePoints: ["整数加法"]
        )

        do {
            let result = try await AIService.solve(
                question: recognition.recognizedQuestion,
                recognition: recognition,
                using: .deepSeek
            )
            connectionTestResult = ConnectionTestResult(
                title: "连接成功",
                message: "DeepSeek 已成功解析测试题目：\(result.finalAnswer)"
            )
        } catch {
            connectionTestResult = ConnectionTestResult(
                title: "连接失败",
                message: error.localizedDescription
            )
        }
    }

    private func connectionTestImage() -> UIImage {
        let size = CGSize(width: 900, height: 360)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let text = "计算：1 + 1 = ?"
            text.draw(
                at: CGPoint(x: 80, y: 115),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 72, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
            )
        }
    }
}
