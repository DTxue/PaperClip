import SwiftUI

struct QuestionCropView: View {
    let image: UIImage
    let existingCrop: String?
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    // 归一化选区（0–1 范围）
    @State private var normRect: CGRect
    // 图片在本地坐标系中的实际帧
    @State private var fittedFrame: CGRect = .zero

    @State private var dragSession: CropDragSession = .idle

    init(image: UIImage, existingCrop: String?, onSave: @escaping (String) -> Void) {
        self.image = image
        self.existingCrop = existingCrop
        self.onSave = onSave
        _normRect = State(initialValue: NormalizedCropGeometry.initialRect(from: existingCrop))
    }

    // 选区在本地坐标系中的绝对矩形
    private var selectionRect: CGRect {
        normRect.rect(in: fittedFrame)
    }

    var body: some View {
        GeometryReader { geo in
            let frame = NormalizedCropGeometry.fittedFrame(imageSize: image.size, viewSize: geo.size)
            ZStack {
                Color.black

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)

                if fittedFrame != .zero {
                    CropDimmingOverlay(imageFrame: fittedFrame, normRect: normRect)
                        .allowsHitTesting(false)

                    cropInteractionLayer
                }
            }
            .onAppear { updateFittedFrame(frame) }
            .onChange(of: geo.size) { _, newSize in
                updateFittedFrame(NormalizedCropGeometry.fittedFrame(imageSize: image.size, viewSize: newSize))
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) { bottomBar }
        .overlay(alignment: .top) {
            QuestionCropInstructionBanner()
        }
    }

    private func updateFittedFrame(_ frame: CGRect) {
        guard fittedFrame != frame else { return }
        fittedFrame = frame
    }

    // MARK: 交互层（移动 + 四角缩放）

    @ViewBuilder
    private var cropInteractionLayer: some View {
        QuestionCropInteractionLayer(
            selectionRect: selectionRect,
            fittedFrame: fittedFrame,
            normRect: $normRect,
            dragSession: $dragSession
        )
    }

    // MARK: 工具方法

    private var bottomBar: some View {
        QuestionCropBottomBar(
            canClear: existingCrop != nil,
            onCancel: { dismiss() },
            onClear: {
                onSave("")   // 空字符串信号：调用者设为 nil
                dismiss()
            },
            onReset: {
                normRect = NormalizedCropGeometry.defaultRect
            },
            onConfirm: {
                onSave(NormalizedCropString.format(normRect))
                dismiss()
            }
        )
    }
}
