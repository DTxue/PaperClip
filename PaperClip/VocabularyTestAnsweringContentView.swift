import SwiftUI
import PencilKit

struct VocabularyTestAnsweringContentView: View {
    let sessionMode: VocabularyTestMode?
    let snapshot: VocabularyTestViewSnapshot
    let batches: [VocabularyTestBatch]
    let activeBatch: VocabularyTestBatch?
    let currentBatchIndex: Int
    let currentIndex: Int
    let currentCard: VocabularyCard?
    @Binding var currentDrawing: PKDrawing
    let answerCanvasSession: VocabularyAnswerCanvasSession
    let currentDrawingReloadToken: Int
    let didFinishAnswering: Bool
    let onAdvance: () -> Void
    let onDrawingChanged: () -> Void

    var body: some View {
        let progress = VocabularyAnsweringProgressSnapshot(
            batches: batches,
            currentBatchIndex: currentBatchIndex,
            currentIndex: currentIndex,
            didFinishAnswering: didFinishAnswering
        )

        VStack(spacing: 20) {
            progressHeader(progress)

            if let card = currentCard {
                VocabularyTestDefinitionCard(definition: card.definition)
                VocabularyAnswerCanvas(
                    drawing: $currentDrawing,
                    session: answerCanvasSession,
                    reloadToken: currentDrawingReloadToken
                )
                VocabularyAnswerAdvanceButton(
                    title: actionTitle,
                    isLastInBatch: isLastInBatch,
                    onAdvance: onAdvance
                )
            }

            Spacer()
        }
        .padding(28)
        .onChange(of: currentDrawing.strokes.count) {
            onDrawingChanged()
        }
    }

    private var isExam: Bool {
        sessionMode == .exam
    }

    private var isLastInBatch: Bool {
        currentIndex + 1 == (activeBatch?.cards.count ?? 0)
    }

    private var isLastBatch: Bool {
        currentBatchIndex + 1 == batches.count
    }

    private var actionTitle: String {
        VocabularyAnsweringActionTitle.title(
            isExam: isExam,
            isLastInBatch: isLastInBatch,
            isLastBatch: isLastBatch
        )
    }

    @ViewBuilder
    private func progressHeader(_ progress: VocabularyAnsweringProgressSnapshot) -> some View {
        if isExam, let batch = activeBatch {
            VStack(alignment: .leading, spacing: 8) {
                VocabularyProgressHeader(index: currentIndex, total: batch.cards.count)
                HStack {
                    Text("全卷 \(progress.answeredQuestionCount) / \(progress.totalQuestionCount)")
                    Spacer()
                    Text("后台批阅 \(snapshot.gradedBatchCount) / \(batches.count) 组")
                }
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        } else if let batch = activeBatch {
            VocabularyProgressHeader(index: currentIndex, total: batch.cards.count)
        }
    }
}
