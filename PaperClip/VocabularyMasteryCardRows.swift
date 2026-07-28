import SwiftUI

struct VocabularyMasteryCardRow: View {
    let row: VocabularyMasteryRowData
    let kind: VocabularyDeckKind

    var body: some View {
        DisclosureGroup {
            VStack(spacing: 14) {
                VocabularyMasteryDirectionView(
                    title: VocabularyDirection.termToDefinition.title(for: kind),
                    state: row.termState,
                    fsrs: row.termFSRS,
                    weightedResult: row.termWeightedResult,
                    mastery: row.termMastery
                )
                Divider()
                VocabularyMasteryDirectionView(
                    title: VocabularyDirection.definitionToTerm.title(for: kind),
                    state: row.definitionState,
                    fsrs: row.definitionFSRS,
                    weightedResult: row.definitionWeightedResult,
                    mastery: row.definitionMastery
                )
            }
            .padding(.vertical, 8)
        } label: {
            VocabularyMasteryCardSummary(row: row)
        }
    }
}

private struct VocabularyMasteryCardSummary: View {
    let row: VocabularyMasteryRowData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(row.card.term)
                        .font(.headline)
                    Text(row.card.definition)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(VocabularyStudySessionFormat.percent(row.averageMastery))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(VocabularyMasteryStyle.masteryColor(row.averageMastery))
            }
            ProgressView(value: row.averageMastery)
        }
        .padding(.vertical, 4)
    }
}

enum VocabularyMasteryStyle {
    static func masteryColor(_ value: Double) -> Color {
        if value >= 0.85 { return .green }
        if value >= 0.6 { return .orange }
        return .red
    }

    static func stageTitle(_ value: String) -> String {
        switch value {
        case VocabularyMemoryStage.learning.rawValue: "学习中"
        case VocabularyMemoryStage.review.rawValue: "复习中"
        case VocabularyMemoryStage.relearning.rawValue: "重学中"
        default: "新内容"
        }
    }
}
