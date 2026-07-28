import SwiftUI

extension VocabularyFlashcardView {
    @ViewBuilder
    var flashcardSessionContent: some View {
        if sessionFinished {
            VocabularySessionCompleteView(
                title: "闪卡完成",
                message: "已完成 \(deck.kind.itemCountText(completedCardIDs.count))，共进行 \(round) 轮。",
                systemImage: "checkmark.circle.fill"
            )
        } else if roundFinished {
            roundCompleteView
        } else if queue.isEmpty {
            ContentUnavailableView("没有可学习的\(deck.kind.itemName)", systemImage: "rectangle.on.rectangle")
        } else if let card = current {
            currentCardStudyContent(card)
        }
    }

    func currentCardStudyContent(_ card: VocabularyCard) -> some View {
        VStack(spacing: 24) {
            VocabularyProgressHeader(index: index, total: queue.count)

            HStack {
                Text("第 \(round) 轮")
                Spacer()
                Text("已完成 \(completedCardIDs.count) / \(initialCount)")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)

            Picker("方向", selection: $direction) {
                ForEach(VocabularyDirection.allCases) { direction in
                    Text(direction.title(for: deck.kind)).tag(direction)
                }
            }
            .pickerStyle(.segmented)

            flashcard(card)

            HStack(spacing: 12) {
                ForEach(VocabularyReviewRating.allCases) { rating in
                    ratingButton(rating, cardID: card.id)
                }
            }

            Text("先回忆并显示答案，再按实际难度评分。左滑：忘记　右滑：记得")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
