import SwiftUI
import PencilKit

struct VocabularyTestDefinitionCard: View {
    let definition: String

    var body: some View {
        Text(definition)
            .font(.title2.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct VocabularyAnswerAdvanceButton: View {
    let title: String
    let isLastInBatch: Bool
    let onAdvance: () -> Void

    var body: some View {
        Button(title, systemImage: isLastInBatch ? "checkmark.circle.fill" : "arrow.right") {
            onAdvance()
        }
        .buttonStyle(.borderedProminent)
    }
}

struct VocabularyAnswerCanvas: View {
    @Binding var drawing: PKDrawing
    let session: VocabularyAnswerCanvasSession
    let reloadToken: Int

    var body: some View {
        ZStack {
            VocabularyHandwritingCanvas(
                drawing: $drawing,
                session: session,
                isEnabled: true,
                reloadToken: reloadToken
            )
            GeometryReader { geo in
                let lineColor = Color(.label).opacity(0.25)
                Rectangle()
                    .fill(lineColor)
                    .frame(height: 1)
                    .offset(y: geo.size.height * 0.36)
                Rectangle()
                    .fill(lineColor)
                    .frame(height: 1)
                    .offset(y: geo.size.height * 0.76)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(.quaternary) }
    }
}
