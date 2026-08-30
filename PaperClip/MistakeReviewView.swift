import SwiftUI
import SwiftData
import PencilKit

struct MistakeReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: MistakeLibraryItem
    let attachments: [MistakeAttachment]

    @State private var drawing = PKDrawing()
    @State private var isReadyToAssess = false
    @State private var note = ""
    @State private var isSaving = false
    @State private var alert: AppAlert?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !attachments.isEmpty {
                        VStack(spacing: 14) {
                            ForEach(attachments) { attachment in
                                MistakeAttachmentThumbnail(fileName: attachment.fileName)
                                    .frame(maxWidth: .infinity, maxHeight: 520)
                                    .background(Color.secondary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }

                    if item.questionText.isEmpty {
                        Text("请根据题目图片作答。")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        MistakeQuestionTextView(text: item.questionText)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("草稿与作答")
                            .font(.headline)
                        PencilDrawingCanvas(
                            drawing: $drawing,
                            backgroundColor: .secondarySystemBackground,
                            isOpaque: true,
                            accessibilityLabel: "错题重做画布",
                            toolAutosaveName: "MistakeReview"
                        )
                        .frame(minHeight: 380)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.separator, lineWidth: 0.5)
                        }
                    }

                    if isReadyToAssess {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("完成自评").font(.headline)
                            Text("请根据课堂讲解、课本或原题答案判断本次是否已经掌握。")
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                        TextField("本次备注（可选）", text: $note, axis: .vertical)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Button {
                                finish(.incorrect)
                            } label: {
                                Label("还不会", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                finish(.correct)
                            } label: {
                                Label("做对了", systemImage: "checkmark")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Button {
                            withAnimation { isReadyToAssess = true }
                        } label: {
                            Label("完成作答，开始自评", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(24)
            }
            .navigationTitle("重做错题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("退出") { dismiss() }
                }
            }
            .disabled(isSaving)
        }
        .appAlert($alert)
    }

    private func finish(_ outcome: MistakeReviewOutcome) {
        isSaving = true
        do {
            try MistakeLibraryPersistence.recordReview(
                for: item,
                outcome: outcome,
                drawing: drawing,
                note: note,
                in: modelContext
            )
            dismiss()
        } catch {
            modelContext.rollback()
            alert = AppAlert(title: "保存重做记录失败", error: error)
            isSaving = false
        }
    }
}
