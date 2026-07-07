import PencilKit
import SwiftUI

struct PaperResultContentView: View {
    let cards: [MistakeCard]
    let drawings: [UUID: PKDrawing]
    let selectedAnswers: [UUID: String]
    let textAnswers: [UUID: String]
    let isSubmitted: Bool
    let onSync: () -> Void
    @Binding var marks: [UUID: String]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                PaperResultSummarySection(snapshot: snapshot)

                PaperResultSyncSection(
                    isSubmitted: isSubmitted,
                    isDisabled: marks.isEmpty,
                    onSync: onSync
                )

                Divider()

                ForEach(cards.indices, id: \.self) { index in
                    let card = cards[index]
                    PaperResultItemView(
                        index: index + 1,
                        card: card,
                        drawing: drawings[card.id] ?? PKDrawing(),
                        selectedAnswer: selectedAnswers[card.id] ?? "",
                        textAnswer: textAnswers[card.id] ?? "",
                        mark: Binding(
                            get: { marks[card.id] ?? "" },
                            set: { marks[card.id] = $0 }
                        )
                    )
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
    }

    private var snapshot: PaperResultSnapshot {
        PaperResultSnapshot(cardCount: cards.count, marks: marks)
    }
}

private struct PaperResultSummarySection: View {
    let snapshot: PaperResultSnapshot

    var body: some View {
        HStack(spacing: 16) {
            PaperScoreTile(count: snapshot.gotItCount, label: "答对", color: .green, icon: "checkmark.circle.fill")
            PaperScoreTile(count: snapshot.notYetCount, label: "答错", color: .red, icon: "xmark.circle.fill")
            PaperScoreTile(count: snapshot.unmarkedCount, label: "待自评", color: .secondary, icon: "person.crop.circle.badge.questionmark")
        }
        .padding(.top, 12)
    }
}

private struct PaperResultSyncSection: View {
    let isSubmitted: Bool
    let isDisabled: Bool
    let onSync: () -> Void

    var body: some View {
        if isSubmitted {
            Label("已自动同步掌握状态到错题库", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.subheadline.weight(.medium))
        } else {
            Button(action: onSync) {
                Label("同步掌握状态到错题库", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 4)
            .disabled(isDisabled)
        }
    }
}
