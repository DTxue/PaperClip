import SwiftUI

struct PaperCardSelectionRow: View {
    let card: MistakeCardRowData
    let isSelected: Bool
    let toggleSelection: () -> Void

    var body: some View {
        Button(action: toggleSelection) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(card.subject)
                            .font(.subheadline.weight(.medium))
                        Text(card.resolvedQuestionType.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !card.tagPreviewText.isEmpty {
                            Text(card.tagPreviewText)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    if !card.recognizedText.isEmpty {
                        Text(card.recognizedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(card.createdAt, format: .dateTime.year().month().day())
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
                StatusBadge(status: card.status)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.subject) \(isSelected ? "已选" : "未选")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
