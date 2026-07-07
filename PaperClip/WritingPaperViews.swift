import SwiftUI
import PencilKit

enum WritingWorkspacePhase: Equatable {
    case idle
    case recognizing
    case grading

    var title: String {
        switch self {
        case .idle: ""
        case .recognizing: "豆包正在识别作文…"
        case .grading: "DeepSeek 正在批阅作文…"
        }
    }

    var isWorking: Bool {
        self != .idle
    }
}

struct WritingPaperSettingsSnapshot: Equatable {
    let style: WritingPaperStyle
    let blackPaperMode: Bool
    let width: Double
    let height: Double
    let rulingSpacing: Double
}

struct WritingPaperCanvasView: View {
    let drawingStore: WritingDrawingStore
    let paperSize: CGSize
    let paperStyle: WritingPaperStyle
    let blackPaperMode: Bool
    let rulingSpacing: Double
    let reloadToken: Int
    let onDrawingChanged: () -> Void

    var body: some View {
        ZStack {
            WritingPaperBackground(
                style: paperStyle,
                blackPaperMode: blackPaperMode,
                rulingSpacing: rulingSpacing
            )
            WritingPencilCanvas(
                drawing: Binding(
                    get: { drawingStore.drawing },
                    set: { newDrawing in
                        drawingStore.drawing = newDrawing
                        onDrawingChanged()
                    }
                ),
                blackPaperMode: blackPaperMode,
                reloadToken: reloadToken
            )
        }
        .frame(width: paperSize.width, height: paperSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("写作手写区域")
    }
}
