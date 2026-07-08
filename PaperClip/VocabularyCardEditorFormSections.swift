import SwiftUI

struct VocabularyCardEditorFormSections: View {
    @Binding var draft: VocabularyCardEditDraft

    var body: some View {
        Section("必填") {
            TextField("单词", text: $draft.term)
            TextField("释义", text: $draft.definition, axis: .vertical)
        }
        Section("扩展内容") {
            TextField("英文释义", text: $draft.englishDefinition, axis: .vertical)
            TextField("音标", text: $draft.phonetic)
            TextField("例句", text: $draft.example, axis: .vertical)
            TextField("词性", text: $draft.partOfSpeech)
            TextField("标签（逗号分隔）", text: $draft.tagsText)
            TextField("可接受答案（| 分隔）", text: $draft.alternativeAnswersText)
            TextField("备注", text: $draft.note, axis: .vertical)
        }
    }
}
