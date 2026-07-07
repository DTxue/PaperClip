import SwiftUI

struct MistakeCardTile: View {
    let card: MistakeCardRowData
    let practiceRoundCount: Int

    private var showTextPreview: Bool {
        card.recognitionStatus == RecognitionStatus.completed.rawValue
            && !card.recognizedText.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                previewArea
                VStack(spacing: 4) {
                    RecognitionStatusBadge(status: card.recognitionStatus)
                    if practiceRoundCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "pencil.and.list.clipboard").imageScale(.small)
                            Text("×\(practiceRoundCount)")
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(.orange, in: Capsule())
                    }
                }
                .padding(8)
            }

            HStack {
                Text(card.subject.isEmpty ? "未分类" : card.subject).font(.headline)
                Spacer()
                StatusBadge(status: card.status)
            }
            Text(card.metadataText)
            .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            if !card.sourceDocumentTitle.isEmpty {
                Text(card.sourceDocumentTitle).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
            }
            Text(card.createdAt, format: .dateTime.year().month().day())
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.quaternary) }
    }

    @ViewBuilder
    private var previewArea: some View {
        if showTextPreview {
            RecognitionPreviewView(question: card.recognizedText, isEmbedded: true)
                .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 180, alignment: .topLeading)
                .clipped()
                .padding(12)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("题目预览：\(card.recognizedText)")
        } else {
            CardImage(url: card.imageURL, maxPixelSize: 600)
                .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 180)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct RecognitionStatusBadge: View {
    let status: String

    var body: some View {
        switch status {
        case RecognitionStatus.pending.rawValue, RecognitionStatus.processing.rawValue:
            ProgressView()
                .controlSize(.mini)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityLabel("识别中")
        case RecognitionStatus.failed.rawValue:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
                .imageScale(.medium)
                .padding(4)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityLabel("识别失败")
        default:
            EmptyView()
        }
    }
}
