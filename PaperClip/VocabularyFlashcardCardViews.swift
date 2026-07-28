import SwiftUI

extension VocabularyFlashcardView {
    var roundCompleteView: some View {
        VStack(spacing: 24) {
            ContentUnavailableView {
                Label("第 \(round) 轮完成", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
            } description: {
                Text("本轮完成 \(roundKnownCount) 个，忘记 \(roundLearningCount) 个。")
            }

            Button("继续学习 \(deck.kind.itemCountText(nextRound.count))", systemImage: "arrow.clockwise") {
                startNextRound()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func flashcard(_ card: VocabularyCard) -> some View {
        Button {
            revealCard()
        } label: {
            VStack(spacing: 18) {
                Text(prompt(for: card))
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
                if deck.kind.usesWordSpecificFeatures,
                   direction == .termToDefinition,
                   !card.englishDefinition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(card.englishDefinition)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.tint)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.top, 2)
                }
                if deck.kind.usesWordSpecificFeatures,
                   direction == .termToDefinition,
                   !card.phonetic.isEmpty {
                    Text(card.phonetic)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                if isRevealed {
                    Divider()
                    Text(answer(for: card))
                        .font(.title2)
                        .multilineTextAlignment(.center)
                    if deck.kind.usesWordSpecificFeatures, !card.example.isEmpty {
                        Text(card.example)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Label("轻点显示答案", systemImage: "hand.tap")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 720, minHeight: 360)
            .padding(32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.background)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(swipeCardTint)
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(swipeCardBorderColor, lineWidth: swipeColorProgress > 0 ? 2 : 1)
        }
        .overlay(alignment: .top) {
            HStack {
                swipeChoiceBadge(.good)
                Spacer()
                swipeChoiceBadge(.again)
            }
            .padding(14)
            .allowsHitTesting(false)
        }
        .rotationEffect(.degrees(Double(max(-8, min(8, cardOffset.width / 45)))))
        .scaleEffect(swipeCardScale)
        .opacity(cardEntryOpacity * swipeCardOpacity)
        .offset(x: cardOffset.width + cardEntryOffset, y: cardOffset.height)
        .gesture(swipeGesture(cardID: card.id))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRevealed ? "\(prompt(for: card))，答案：\(answer(for: card))" : prompt(for: card))
        .accessibilityHint(isRevealed ? "选择忘记、困难、记得或简单" : "轻点显示答案")
        .accessibilityAction {
            revealCard()
        }
        .accessibilityAction(named: VocabularyReviewRating.again.title) {
            performRating(.again, cardID: card.id)
        }
        .accessibilityAction(named: VocabularyReviewRating.good.title) {
            performRating(.good, cardID: card.id)
        }
    }

}
