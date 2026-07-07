import SwiftUI

struct NewWritingPromptFormSections: View {
    @Binding var language: WritingLanguage
    @Binding var studentGrade: String
    @Binding var requirementInput: String
    let isGenerating: Bool
    let onGenerate: () -> Void

    private var draft: WritingPromptGenerationDraft {
        WritingPromptGenerationDraft(
            language: language,
            studentGrade: studentGrade,
            requirementInput: requirementInput
        )
    }

    var body: some View {
        Section("写作类型") {
            Picker("类型", selection: $language) {
                ForEach(WritingLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            Picker("年级", selection: $studentGrade) {
                ForEach(WritingGradeOptions.all, id: \.self) { grade in
                    Text(grade).tag(grade)
                }
            }
        }

        Section {
            TextEditor(text: $requirementInput)
                .frame(minHeight: 150)
                .textInputAutocapitalization(language == .english ? .sentences : .never)
        } header: {
            Text("写作要求")
        } footer: {
            Text(footerText)
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

    private var footerText: String {
        language == .chinese
            ? "例如：初二，记叙文，主题是一次让我成长的经历，600字左右。"
            : "For example: Grade 8, write about a memorable challenge, 120 words, use richer vocabulary."
    }
}
