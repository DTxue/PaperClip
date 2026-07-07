import SwiftUI

struct WritingRecognitionReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editedText: String
    let onConfirm: (String) -> Void

    init(text: String, onConfirm: @escaping (String) -> Void) {
        _editedText = State(initialValue: text)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $editedText)
                        .frame(minHeight: 360)
                } header: {
                    Text("请确认豆包识别出的作文文本")
                } footer: {
                    Text("批阅会基于这里的文本进行；如果识别有误，请先修正。")
                }
            }
            .navigationTitle("确认识别文本")
            .navigationBarTitleDisplayMode(.inline)
            .editSheetToolbar(
                confirmTitle: "提交批阅",
                isConfirmDisabled: editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onCancel: { dismiss() },
                onConfirm: {
                    let confirmed = editedText
                    dismiss()
                    onConfirm(confirmed)
                }
            )
        }
    }
}
