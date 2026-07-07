import SwiftUI
import SwiftData

extension MistakeCardEditorView {
    func refreshRelatedCandidateCards() {
        let subject = card.subject
        let cardID = card.id
        do {
            relatedCandidateCards = try modelContext.fetchRelatedMistakeCards(
                subject: subject,
                excluding: cardID,
                propertiesToFetch: MistakeCardRowData.propertiesToFetch
            ).map(MistakeCardRowData.init)
        } catch {
            relatedCandidateCards = []
            alert = AppAlert(title: "无法读取相关错题", error: error)
        }
    }

    var thumbnailView: some View {
        ZStack(alignment: .bottomTrailing) {
            CardImage(url: card.imageURL, maxPixelSize: 300)
                .frame(width: 88, height: 72)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button { isCropPresented = true } label: {
                Image(systemName: draftQuestionCrop != nil ? "crop.rotate" : "crop")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(
                        draftQuestionCrop != nil ? Color.accentColor : Color.secondary.opacity(0.85),
                        in: RoundedRectangle(cornerRadius: 4)
                    )
            }
            .buttonStyle(.plain)
            .padding(4)
            .accessibilityLabel(draftQuestionCrop != nil ? "重新框选题目图片区域" : "框选题目图片区域")
        }
    }

    @ViewBuilder
    var recognitionSection: some View {
        let status = RecognitionStatus(rawValue: card.recognitionStatus) ?? .completed

        switch status {
        case .completed where !card.recognizedText.isEmpty:
            Section("AI 识别结果") {
                RecognitionPreviewView(question: card.recognizedText, isEmbedded: true)
            }
        case .processing:
            Section("AI 识别结果") {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("正在识别…").foregroundStyle(.secondary)
                }
            }
        case .failed:
            Section("AI 识别结果") {
                HStack {
                    Label("识别失败", systemImage: "exclamationmark.circle").foregroundStyle(.orange)
                    Spacer()
                    Button("重试") {
                        do {
                            try MistakeCardRecognitionTransaction.markPending(card, in: modelContext)
                            MistakeCardRecognitionService.shared.enqueue(
                                cardID: card.id,
                                imagePath: card.imageURL.path
                            )
                        } catch {
                            alert = AppAlert(title: "无法重新识别", error: error)
                        }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }
        case .pending:
            Section("AI 识别结果") {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("等待识别…").foregroundStyle(.secondary)
                }
            }
        default:
            EmptyView()
        }
    }
}
