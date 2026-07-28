import SwiftUI

struct VocabularyCardEditorFormSections: View {
    @Binding var draft: VocabularyCardEditDraft
    let kind: VocabularyDeckKind

    var body: some View {
        Section("必填") {
            TextField(
                kind.usesWordSpecificFeatures ? "单词" : "英文短语或句子",
                text: $draft.term,
                axis: kind.usesWordSpecificFeatures ? .horizontal : .vertical
            )
            TextField("中文释义", text: $draft.definition, axis: .vertical)
        }
        Section("扩展内容") {
            if kind.usesWordSpecificFeatures {
                TextField("英文释义", text: $draft.englishDefinition, axis: .vertical)
                TextField("音标", text: $draft.phonetic)
                TextField("例句", text: $draft.example, axis: .vertical)
                TextField("词性", text: $draft.partOfSpeech)
            }
            TextField("标签（逗号分隔）", text: $draft.tagsText)
            TextField("可接受答案（| 分隔）", text: $draft.alternativeAnswersText)
            TextField("备注", text: $draft.note, axis: .vertical)
        }
    }
}
