import SwiftUI

struct NewWritingPromptFormSections: View {
    @Binding var studentGrade: String
    @Binding var requirementInput: String
    let isGenerating: Bool
    let onGenerate: () -> Void

    private var draft: WritingPromptGenerationDraft {
        WritingPromptGenerationDraft(
            language: .chinese,
            studentGrade: studentGrade,
            requirementInput: requirementInput
        )
    }

    var body: some View {
        Section("年级") {
            Picker("年级", selection: $studentGrade) {
                ForEach(WritingGradeOptions.all, id: \.self) { grade in
                    Text(grade).tag(grade)
                }
            }
        }

        Section {
            TextEditor(text: $requirementInput)
                .frame(minHeight: 150)
                .textInputAutocapitalization(.never)
        } header: {
            Text("写作要求")
        } footer: {
            Text("例如：初二，记叙文，主题是一次让我成长的经历，600字左右。")
        }

        Section {
            Button(action: onGenerate) {
                HStack {
                    Spacer()
                    if isGenerating {
                        ProgressView()
                            .controlSize(.small)
                        Text("正在生成…")
                    } else {
                        Label("生成写作题", systemImage: "sparkles")
                    }
                    Spacer()
                }
            }
            .disabled(isGenerating || !draft.canGenerate)
        }
    }
}
