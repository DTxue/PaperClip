import SwiftUI

// MARK: - 写作设置

struct WritingSettingsView: View {
    @State private var selectedPrompt = WritingPromptConfiguration.chineseReview
    @State private var promptText = WritingPromptConfiguration.resolvedPrompt(for: .chineseReview)
    @State private var promptSaveAction = DebouncedAction()
    @State private var suppressNextPromptAutosave = false

    var body: some View {
        Form {
            Section {
                Picker("提示词", selection: $selectedPrompt) {
                    ForEach(WritingPromptConfiguration.availableCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("提示词")
            } footer: {
                Text("命题使用 DeepSeek 生成写作题；批阅先用豆包识别手写，再用 DeepSeek 根据这里的提示词批阅。")
            }

            Section {
                TextEditor(text: $promptText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 420)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                HStack {
                    Button("恢复当前默认") {
                        let defaultPrompt = selectedPrompt.defaultValue
                        replacePromptText(defaultPrompt, autosave: false)
                        WritingPromptConfiguration.save(defaultPrompt, for: selectedPrompt)
                    }
                    Spacer()
                    Button("恢复全部默认", role: .destructive) {
                        for item in WritingPromptConfiguration.availableCases {
                            UserDefaults.standard.removeObject(forKey: item.storageKey)
                        }
                        replacePromptText(selectedPrompt.defaultValue, autosave: false)
                    }
                }
            } header: {
                Text(selectedPrompt.title)
            } footer: {
                Text("可用变量：{studentGrade}、{requirementInput}、{writingRequirement}、{recognizedText}、{fullScore}。")
            }

            Section("批阅目标") {
                Label("中文批阅按远高于当前年级的标准，强制输出“好词好句”和局部示范修改。", systemImage: "character.book.closed")
                Label("批阅前会展示豆包识别文本，用户确认后再提交 DeepSeek。", systemImage: "text.viewfinder")
            }
        }
        .navigationTitle("写作设置")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPrompt) { oldValue, newValue in
            promptSaveAction.cancel()
            WritingPromptConfiguration.save(promptText, for: oldValue)
            replacePromptText(
                WritingPromptConfiguration.resolvedPrompt(for: newValue),
                autosave: false
            )
        }
        .onChange(of: promptText) { _, newValue in
            if suppressNextPromptAutosave {
                suppressNextPromptAutosave = false
                return
            }
            schedulePromptSave(newValue)
        }
        .onDisappear {
            promptSaveAction.cancel()
            WritingPromptConfiguration.save(promptText, for: selectedPrompt)
        }
    }

    private func schedulePromptSave(_ text: String) {
        let prompt = selectedPrompt
        promptSaveAction.schedule(after: .milliseconds(600)) {
            WritingPromptConfiguration.save(text, for: prompt)
        }
    }

    private func replacePromptText(_ text: String, autosave: Bool) {
        guard promptText != text else {
            if autosave {
                WritingPromptConfiguration.save(text, for: selectedPrompt)
            }
            return
        }
        suppressNextPromptAutosave = !autosave
        promptText = text
    }
}
