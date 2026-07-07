import SwiftUI

extension WritingWorkspaceView {
    @ViewBuilder
    var latestReviewSection: some View {
        if !recentReviews.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("批阅记录")
                    .font(.headline)
                ForEach(recentReviews) { review in
                    Button {
                        presentedReview = review
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(review.scoreText.isEmpty ? "作文批阅" : "作文批阅 · \(review.scoreText)")
                                    .font(.subheadline.weight(.semibold))
                                Text(review.summaryText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
