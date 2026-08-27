import SwiftUI
import PencilKit
import UIKit

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

struct VocabularyPencilOnlyActionButton: UIViewRepresentable {
    let title: String
    let systemImage: String
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> VocabularyPencilOnlyButton {
        let button = VocabularyPencilOnlyButton(type: .system)
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.activate),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ button: VocabularyPencilOnlyButton, context: Context) {
        context.coordinator.action = action
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: systemImage)
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 6
        button.configuration = configuration
        button.accessibilityLabel = title
        button.accessibilityHint = "使用 Apple Pencil 点击"
    }

    @MainActor
    final class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func activate() {
            action()
        }
    }
}

final class VocabularyPencilOnlyButton: UIButton {
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard touch.type == .pencil else { return false }
        return super.beginTracking(touch, with: event)
    }

    override func accessibilityActivate() -> Bool {
        sendActions(for: .touchUpInside)
        return true
    }
}

struct VocabularyAnswerAdvanceUndoBanner: View {
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label("已进入下一题", systemImage: "arrow.right.circle")
            Divider()
                .frame(height: 20)
            Button("撤销", action: undo)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 8, y: 3)
        .accessibilityElement(children: .contain)
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
