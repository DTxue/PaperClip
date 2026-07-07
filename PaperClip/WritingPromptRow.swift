import SwiftUI

struct WritingPromptRow: View {
    let prompt: WritingPromptRowData
    let draft: WritingDraftRowData?
    let review: WritingReviewRowData?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(prompt.language.shortTitle, systemImage: prompt.language.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(prompt.studentGrade)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let review {
                    Text(review.scoreText.isEmpty ? "已批阅" : review.scoreText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else if let draft {
                    Text(draft.reviewStatus.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }

            Text(prompt.title)
                .font(.headline)
                .lineLimit(2)

            Text(prompt.requirement)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if let draft {
                Text("草稿更新：\(draft.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
