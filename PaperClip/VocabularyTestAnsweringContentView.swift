import SwiftUI
import PencilKit

struct VocabularyTestAnsweringContentView: View {
    let handwritingTestKind: VocabularyHandwritingTestKind
    let usesChineseCharacterByCharacterRecognition: Bool
    let activeBatch: VocabularyTestBatch?
    let currentIndex: Int
    let currentCard: VocabularyCard?
    @Binding var currentDrawing: PKDrawing
    let answerCanvasSession: VocabularyAnswerCanvasSession
    let currentDrawingReloadToken: Int

    var body: some View {
        VStack(spacing: 20) {
            if let batch = activeBatch {
                VocabularyProgressHeader(index: currentIndex, total: batch.cards.count)
            }

            if let card = currentCard {
                VocabularyTestDefinitionCard(
                    definition: handwritingTestKind.prompt(
                        term: card.term,
                        definition: card.definition
                    )
                )
                VocabularyAnswerCanvas(
                    drawing: $currentDrawing,
                    session: answerCanvasSession,
                    usesChineseCharacterByCharacterRecognition: usesChineseCharacterByCharacterRecognition,
                    reloadToken: currentDrawingReloadToken
                )
            }

            Spacer()
        }
        .padding(28)
    }

}
