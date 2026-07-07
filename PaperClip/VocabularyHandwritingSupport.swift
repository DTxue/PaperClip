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
                autoreleasepool {
                    images.append(render(drawing))
                }
            }
            return images
        }.value
    }

    @MainActor
    static func renderOnMainActor(_ drawings: [PKDrawing]) -> [UIImage?] {
        drawings.map { drawing in
            autoreleasepool {
                render(drawing)
            }
        }
    }

    private static func render(_ drawing: PKDrawing) -> UIImage? {
        guard DrawingDataSupport.hasInk(drawing) else { return nil }
        guard let spec = HandwritingRenderGeometry.inkCropSpec(inkBounds: drawing.bounds) else {
            return nil
        }
        return ImageRenderSupport.opaqueImage(size: spec.outputSize) { context in
            ImageRenderSupport.fillWhiteBackground(
                in: CGRect(origin: .zero, size: spec.outputSize),
                context: context
            )
            drawing.image(from: spec.sourceRect, scale: spec.drawingScale)
                .draw(in: CGRect(origin: .zero, size: spec.outputSize))
        }
    }
}

/// 单词拼写业务需要在同一题目中保存自由手写轨迹，SwiftUI 没有等价画布。
/// 使用 Apple 官方 PKCanvasView 和 PKToolPicker；画笔、颜色、粗细、橡皮和套索均由系统提供。
/// `pencilOnly` 保留手指的页面操作，画布支持深色模式、VoiceOver 标签和窗口尺寸变化。
struct VocabularyHandwritingCanvas: View {
    @Binding var drawing: PKDrawing
    let isEnabled: Bool
    var reloadToken = 0

    var body: some View {
        PencilDrawingCanvas(
            drawing: $drawing,
            isEnabled: isEnabled,
            reloadToken: reloadToken,
            backgroundColor: .secondarySystemBackground,
            isOpaque: true,
            accessibilityLabel: "手写答案画布",
            toolAutosaveName: "PaperClip.VocabularyTools"
        )
    }
}
