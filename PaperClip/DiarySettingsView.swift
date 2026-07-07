import SwiftUI

struct DiarySettingsView: View {
    @AppStorage("diaryAIModel") private var diaryAIModel = AIAnswerModel.doubao.rawValue

    private var selectedModel: AIAnswerModel {
        AIAnswerModel(rawValue: diaryAIModel) ?? .doubao
    }

    var body: some View {
        Form {
            Section {
                Picker("AI 模型", selection: $diaryAIModel) {
                    ForEach(AIAnswerModel.allCases) { model in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.title)
                            Text(modelDescription(model))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(model.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("知识点提取与解析")
            } footer: {
                Text("选择的模型将用于 AI 整理时提取知识点，以及后续的逐条 AI 解析。当前选择：\(selectedModel.title)。")
            }

            Section("功能说明") {
                Label("AI 整理：从日记原文中拆分、归纳知识点", systemImage: "list.bullet.clipboard")
                Label("AI 解析：为每个知识点生成本质、公式、考点、易错陷阱等", systemImage: "sparkles")
            }
        }
        .navigationTitle("日记设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func modelDescription(_ model: AIAnswerModel) -> String {
        switch model {
        case .doubao: return "速度快，适合知识提取"
        case .deepSeek: return "推理强，适合深度解析"
        }
    }
}
