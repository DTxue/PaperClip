import SwiftUI
import PencilKit
import UIKit

struct VocabularyAnsweringProgressSnapshot {
    let answeredQuestionCount: Int
    let totalQuestionCount: Int

    init(
        batches: [VocabularyTestBatch],
        currentBatchIndex: Int,
        currentIndex: Int,
        didFinishAnswering: Bool
    ) {
        var answered = 0
        var total = 0

        for batchIndex in batches.indices {
            let count = batches[batchIndex].cards.count
            total += count
            if batchIndex < currentBatchIndex
                || (didFinishAnswering && batchIndex == currentBatchIndex) {
                answered += count
            } else if batchIndex == currentBatchIndex {
                answered += currentIndex
            }
        }

        answeredQuestionCount = answered
        totalQuestionCount = total
    }
}

enum VocabularyHandwritingImageRenderer {
    static func render(_ drawings: [PKDrawing]) async -> [UIImage?] {
        await Task.detached(priority: .userInitiated) {
            var images: [UIImage?] = []
            images.reserveCapacity(drawings.count)
            for drawing in drawings {
                guard !Task.isCancelled else { return images }
                images.append(await renderForRecognition(drawing))
            }
            return images
        }.value
    }

    @MainActor
    static func renderOnMainActor(_ drawings: [PKDrawing]) -> [UIImage?] {
        drawings.map { drawing in
            autoreleasepool {
                renderSynchronously(drawing)
            }
        }
    }

    private static func renderForRecognition(_ drawing: PKDrawing) async -> UIImage? {
        guard DrawingDataSupport.hasInk(drawing) else { return nil }
        guard let spec = HandwritingRenderGeometry.inkCropSpec(inkBounds: drawing.bounds) else {
            return nil
        }
        guard let bitmap = makeBitmap(size: spec.outputSize) else { return nil }

        fillWhite(bitmap.context, size: spec.outputSize)
        await normalizedForRecognition(drawing).draw(
            in: bitmap.context,
            frame: CGRect(origin: .zero, size: spec.outputSize),
            from: spec.sourceRect,
            darkUserInterfaceStyle: false
        )

        return visibleImage(from: bitmap)
    }

    private static func renderSynchronously(_ drawing: PKDrawing) -> UIImage? {
        guard DrawingDataSupport.hasInk(drawing) else { return nil }
        guard let spec = HandwritingRenderGeometry.inkCropSpec(inkBounds: drawing.bounds) else {
            return nil
        }
        let image = ImageRenderSupport.opaqueImage(size: spec.outputSize) { context in
            ImageRenderSupport.fillWhiteBackground(
                in: CGRect(origin: .zero, size: spec.outputSize),
                context: context
            )
            normalizedForRecognition(drawing)
                .image(from: spec.sourceRect, scale: spec.drawingScale)
                .draw(in: CGRect(origin: .zero, size: spec.outputSize))
        }
        return containsVisibleInk(image) ? image : nil
    }

    private static func normalizedForRecognition(_ drawing: PKDrawing) -> PKDrawing {
        PKDrawing(strokes: drawing.strokes.map { originalStroke in
            var stroke = originalStroke
            var ink = stroke.ink
            ink.color = .black
            stroke.ink = ink
            return stroke
        })
    }

    private static func makeBitmap(size: CGSize) -> (
        context: CGContext,
        width: Int,
        height: Int
    )? {
        let width = Int(size.width.rounded())
        let height = Int(size.height.rounded())
        guard width > 0, height > 0 else { return nil }
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else { return nil }
        return (context, width, height)
    }

    private static func fillWhite(_ context: CGContext, size: CGSize) {
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
    }

    private static func visibleImage(
        from bitmap: (context: CGContext, width: Int, height: Int)
    ) -> UIImage? {
        guard containsVisibleInk(
            context: bitmap.context,
            width: bitmap.width,
            height: bitmap.height
        ),
        let cgImage = bitmap.context.makeImage()
        else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private static func containsVisibleInk(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage,
              let bitmap = makeBitmap(size: image.size)
        else { return false }
        fillWhite(bitmap.context, size: image.size)
        bitmap.context.draw(
            cgImage,
            in: CGRect(origin: .zero, size: image.size)
        )
        return containsVisibleInk(
            context: bitmap.context,
            width: bitmap.width,
            height: bitmap.height
        )
    }

    private static func containsVisibleInk(
        context: CGContext,
        width: Int,
        height: Int
    ) -> Bool {
        guard let data = context.data else { return false }
        let bytes = data.assumingMemoryBound(to: UInt8.self)
        let bytesPerRow = context.bytesPerRow
        for row in 0..<height {
            let rowStart = row * bytesPerRow
            for column in 0..<width {
                let offset = rowStart + column * 4
                if bytes[offset] < 245
                    || bytes[offset + 1] < 245
                    || bytes[offset + 2] < 245 {
                    return true
                }
            }
        }
        return false
    }
}

@MainActor
final class VocabularyAnswerCanvasSession {
    private weak var canvas: PKCanvasView?
    private var latestDrawing = PKDrawing()

    func attach(_ canvas: PKCanvasView) {
        self.canvas = canvas
        latestDrawing = canvas.drawing
    }

    func detach(_ canvas: PKCanvasView) {
        guard self.canvas === canvas else { return }
        latestDrawing = canvas.drawing
        self.canvas = nil
    }

    func drawingDidChange(_ drawing: PKDrawing) {
        latestDrawing = drawing
    }

    func snapshot(fallback: PKDrawing) -> PKDrawing {
        if let canvas {
            latestDrawing = canvas.drawing
            return canvas.drawing
        }
        return DrawingDataSupport.hasInk(latestDrawing) ? latestDrawing : fallback
    }

    func prepare(_ drawing: PKDrawing) {
        latestDrawing = drawing
    }
}

/// 单词测验使用独立的 PencilKit adapter。提交时由 `VocabularyAnswerCanvasSession`
/// 直接读取活动 `PKCanvasView`，不依赖 SwiftUI Binding 是否已完成一轮状态传播。
struct VocabularyHandwritingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let session: VocabularyAnswerCanvasSession
    let isEnabled: Bool
    var reloadToken = 0

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.configureSharedPencilCanvas(
            backgroundColor: .secondarySystemBackground,
            isOpaque: true,
            viewport: nil
        )
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.accessibilityLabel = "手写答案画布"
        context.coordinator.lastReloadToken = reloadToken
        context.coordinator.toolPickerController.register(canvas)
        session.attach(canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.isUserInteractionEnabled = isEnabled
        context.coordinator.toolPickerController.updateVisibility(
            isEnabled: isEnabled,
            for: canvas
        )
        session.attach(canvas)

        guard context.coordinator.lastReloadToken != reloadToken else { return }
        canvas.delegate = nil
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        session.prepare(drawing)
        context.coordinator.lastReloadToken = reloadToken
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            drawing: $drawing,
            session: session
        )
    }

    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        coordinator.session.detach(canvas)
        coordinator.toolPickerController.dismantle(canvas)
        canvas.delegate = nil
    }

    @MainActor
    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private var drawing: Binding<PKDrawing>
        let session: VocabularyAnswerCanvasSession
        let toolPickerController = SharedPencilToolPickerController(
            toolAutosaveName: "PaperClip.VocabularyTools"
        )
        var lastReloadToken = 0

        init(
            drawing: Binding<PKDrawing>,
            session: VocabularyAnswerCanvasSession
        ) {
            self.drawing = drawing
            self.session = session
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let liveDrawing = canvasView.drawing
            session.drawingDidChange(liveDrawing)
            drawing.wrappedValue = liveDrawing
        }
    }
}
