import SwiftUI

extension MistakeCardEditorView {
    var metadataSection: some View {
        MistakeCardMetadataSection(
            sourceDocumentTitle: card.sourceDocumentTitle,
            subjects: subjectsForPicker,
            grade: $draftGrade,
            subject: $draftSubject,
            semester: $draftSemester
        ) {
            thumbnailView
        }
    }

    var questionTypeSection: some View {
        Section("题型分类") {
            Picker("题型", selection: $draftQuestionType) {
                ForEach(QuestionType.allCases) { type in
                    Label(type.rawValue, systemImage: type.systemImage)
                        .tag(type.rawValue)
                }
            }
            .pickerStyle(.menu)

            Text("AI 会自动判断题型；你可以在此手动修改，出卷时将按该题型生成对应答题区域。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    var answerSection: some View {
        Section("正确答案") {
            TextField(
                "AI 尚未生成答案，可在此手动填写",
                text: $draftCorrectAnswer,
                axis: .vertical
            )
            .lineLimit(2...8)

            if !draftCorrectAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                RecognitionPreviewView(question: draftCorrectAnswer, isEmbedded: true)
                    .accessibilityLabel("正确答案：\(draftCorrectAnswer)")
            }

            Text("选择题填写选项字母，判断题填写“正确”或“错误”；公式可使用 LaTeX。交卷时将用此答案批改。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    func tagSection(_ currentDraftTags: [String]) -> some View {
        Section("知识点标签") {
            if currentDraftTags.isEmpty {
                Text("暂无标签").font(.subheadline).foregroundStyle(.tertiary)
            } else {
                KnowledgeTagLayout(spacing: 8) {
                    ForEach(currentDraftTags, id: \.self) { tag in
                        EditableMistakeTag(title: tag) { removeTag(tag) }
                    }
                }
            }
            HStack {
                TextField("新增标签（逗号分隔）", text: $newTagText)
                    .submitLabel(.done)
                    .onSubmit(addTags)
                Button("添加", action: addTags)
                    .disabled(
                        newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
            }
        }
    }

}
