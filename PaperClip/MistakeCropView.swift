import SwiftUI
import UIKit

private struct MistakeImageCropWork: @unchecked Sendable {
    let image: UIImage
    let normalizedSelection: CGRect
}

struct MistakeCropSource: Identifiable {
    let id = UUID()
    let image: UIImage
    let originalFileName: String

    init(image: UIImage, originalFileName: String) {
        self.image = image
        self.originalFileName = originalFileName
    }
}

struct MistakeCropView: View {
    let source: MistakeCropSource
    let onComplete: (Data) -> Void
    let onCancel: () -> Void

    @State private var normalizedSelection = CGRect(x: 0.08, y: 0.08, width: 0.84, height: 0.84)
    @State private var gestureStart: CGRect?
    @State private var isCropping = false
    @State private var cropWorker: Task<Data, Error>?
    @State private var cropCompletionTask: Task<Void, Never>?
    @State private var alert: AppAlert?

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let imageRect = MistakeCropGeometry.aspectFitRect(
                    imageSize: source.image.size,
                    containerSize: proxy.size
                )
                let selection = MistakeCropGeometry.selectionRect(
                    from: normalizedSelection,
                    in: imageRect
                )

                ZStack {
                    Color.black

                    Image(uiImage: source.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageRect.width, height: imageRect.height)
                        .position(x: imageRect.midX, y: imageRect.midY)

                    selectionMask(imageRect: imageRect, selection: selection)

                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .overlay {
                            Rectangle()
                                .stroke(.white, lineWidth: 2)
                        }
                        .frame(width: selection.width, height: selection.height)
                        .position(x: selection.midX, y: selection.midY)
                        .contentShape(Rectangle())
                        .gesture(moveGesture(selection: selection, imageRect: imageRect))

                    cropHandle(.topLeading, selection: selection, imageRect: imageRect)
                    cropHandle(.topTrailing, selection: selection, imageRect: imageRect)
                    cropHandle(.bottomLeading, selection: selection, imageRect: imageRect)
                    cropHandle(.bottomTrailing, selection: selection, imageRect: imageRect)

                    if isCropping {
                        ProgressView("正在裁剪…")
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Image(systemName: "hand.draw")
                    Text("拖动选框或四角控制点，只保留一道错题。")
                    Spacer()
                    Button("重置") {
                        normalizedSelection = CGRect(x: 0.08, y: 0.08, width: 0.84, height: 0.84)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.black.opacity(0.9))
            }
            .navigationTitle("框选错题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onCancel() }
                        .disabled(isCropping)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("使用框选区域") { crop() }
                        .disabled(isCropping)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            cropCompletionTask?.cancel()
            cropWorker?.cancel()
        }
        .appAlert($alert)
    }

    private func selectionMask(imageRect: CGRect, selection: CGRect) -> some View {
        Path { path in
            path.addRect(imageRect)
            path.addRect(selection)
        }
        .fill(.black.opacity(0.58), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    private func cropHandle(
        _ handle: MistakeCropHandle,
        selection: CGRect,
        imageRect: CGRect
    ) -> some View {
        let point = handlePoint(handle, selection: selection)
        return Circle()
            .fill(.white)
            .overlay {
                Circle().stroke(.black.opacity(0.45), lineWidth: 1)
            }
            .frame(width: 28, height: 28)
            .contentShape(Circle().scale(1.8))
            .position(point)
            .highPriorityGesture(
                resizeGesture(handle: handle, selection: selection, imageRect: imageRect)
            )
    }

    private func handlePoint(_ handle: MistakeCropHandle, selection: CGRect) -> CGPoint {
        switch handle {
        case .topLeading: CGPoint(x: selection.minX, y: selection.minY)
        case .topTrailing: CGPoint(x: selection.maxX, y: selection.minY)
        case .bottomLeading: CGPoint(x: selection.minX, y: selection.maxY)
        case .bottomTrailing: CGPoint(x: selection.maxX, y: selection.maxY)
        }
    }

    private func moveGesture(selection: CGRect, imageRect: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let start = gestureStart ?? selection
                if gestureStart == nil { gestureStart = start }
                let moved = MistakeCropGeometry.moving(
                    start,
                    translation: value.translation,
                    within: imageRect
                )
                normalizedSelection = MistakeCropGeometry.normalizedSelection(moved, in: imageRect)
                    ?? normalizedSelection
            }
            .onEnded { _ in gestureStart = nil }
    }

    private func resizeGesture(
        handle: MistakeCropHandle,
        selection: CGRect,
        imageRect: CGRect
    ) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let start = gestureStart ?? selection
                if gestureStart == nil { gestureStart = start }
                let resized = MistakeCropGeometry.resizing(
                    start,
                    handle: handle,
                    translation: value.translation,
                    within: imageRect
                )
                normalizedSelection = MistakeCropGeometry.normalizedSelection(resized, in: imageRect)
                    ?? normalizedSelection
            }
            .onEnded { _ in gestureStart = nil }
    }

    private func crop() {
        isCropping = true
        let work = MistakeImageCropWork(
            image: source.image,
            normalizedSelection: normalizedSelection
        )
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            return try MistakeImageCropper.cropJPEG(
                work.image,
                normalizedSelection: work.normalizedSelection
            )
        }
        cropWorker = worker
        cropCompletionTask = Task {
            do {
                let data = try await worker.value
                try Task.checkCancellation()
                cropWorker = nil
                cropCompletionTask = nil
                onComplete(data)
            } catch is CancellationError {
                cropWorker = nil
                cropCompletionTask = nil
                isCropping = false
            } catch {
                cropWorker = nil
                cropCompletionTask = nil
                isCropping = false
                alert = AppAlert(title: "框选错题失败", error: error)
            }
        }
    }
}

enum MistakeImageCropper {
    static func cropJPEG(
        _ source: UIImage,
        normalizedSelection: CGRect
    ) throws -> Data {
        try Task.checkCancellation()
        let image = orientationUpImage(source)
        try Task.checkCancellation()
        guard let cgImage = image.cgImage else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        guard let cropRect = MistakeCropGeometry.pixelCropRect(
            normalizedSelection: normalizedSelection,
            pixelSize: pixelSize
        ),
        cropRect.width >= 1,
        cropRect.height >= 1,
        let croppedCGImage = cgImage.cropping(to: cropRect)
        else {
            throw CocoaError(.fileReadInvalidFileName)
        }

        try Task.checkCancellation()
        let cropped = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: .up)
        guard let data = cropped.jpegData(compressionQuality: 0.95) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try Task.checkCancellation()
        return data
    }

    static func orientationUpImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
