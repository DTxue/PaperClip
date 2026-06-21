import SwiftUI
import PDFKit
import PencilKit

enum PDFSelectionAction {
    case saveMistake
    case analyze
    case share
}

struct PDFKitCanvasView: UIViewRepresentable {
    let url: URL
    let drawings: [Int: Data]
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool
    let isSelectionMode: Bool
    let selectionAction: PDFSelectionAction?
    let selectionActionToken: Int
    let cancelSelectionToken: Int
    let undoToken: Int
    let redoToken: Int
    let clearAnswersToken: Int
    /// 变化时销毁所有 canvas 并从 drawings 重新加载，用于切换做题会话。
    let reloadDrawingsToken: Int
    let onDrawingChanged: (Int, Data) -> Void
    let onSelectionRectChanged: (CGRect?) -> Void
    let onCrop: (UIImage, Double, Double, PDFSelectionAction) -> Void
    let onError: (String) -> Void
    /// 每页画布的精确尺寸（页面索引 → canvas.frame.size），布局完成后回调，供导出合成使用。
    var onCanvasSizesChanged: (([Int: CGSize]) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PDFDrawingHostView {
        let host = PDFDrawingHostView()
        let pdfView = host.pdfView

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        } else {
            DispatchQueue.main.async {
                onError("文件不存在、已损坏，或不是有效的 PDF。")
            }
        }
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = .secondarySystemBackground

        let selectionGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSelection(_:))
        )
        selectionGesture.minimumNumberOfTouches = 1
        selectionGesture.maximumNumberOfTouches = 1
        #if targetEnvironment(simulator)
        selectionGesture.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.pencil.rawValue),
            NSNumber(value: UITouch.TouchType.direct.rawValue),
            NSNumber(value: UITouch.TouchType.indirect.rawValue),
            NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)
        ]
        #else
        selectionGesture.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.pencil.rawValue)
        ]
        #endif
        selectionGesture.delegate = context.coordinator
        selectionGesture.isEnabled = false
        pdfView.addGestureRecognizer(selectionGesture)

        context.coordinator.attach(
            host: host,
            selectionGesture: selectionGesture
        )
        host.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.scheduleCanvasLayout()
        }
        return host
    }

    static func dismantleUIView(
        _ host: PDFDrawingHostView,
        coordinator: Coordinator
    ) {
        coordinator.tearDown()
        host.onLayout = nil
    }

    func updateUIView(_ host: PDFDrawingHostView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        coordinator.selectionGesture?.isEnabled = isSelectionMode
        coordinator.configurePDFInteraction()
        coordinator.updateCanvases()
        coordinator.scheduleCanvasLayout()
        coordinator.updateToolPickerVisibility()

        if !isSelectionMode {
            coordinator.clearSelection(notify: false)
        }
        if coordinator.lastSelectionActionToken != selectionActionToken {
            if let selectionAction {
                coordinator.confirmSelection(action: selectionAction)
            }
            coordinator.lastSelectionActionToken = selectionActionToken
        }
        if coordinator.lastCancelSelectionToken != cancelSelectionToken {
            coordinator.clearSelection()
            coordinator.lastCancelSelectionToken = cancelSelectionToken
        }
        if coordinator.lastUndoToken != undoToken {
            coordinator.activeCanvas?.undoManager?.undo()
            coordinator.lastUndoToken = undoToken
        }
        if coordinator.lastRedoToken != redoToken {
            coordinator.activeCanvas?.undoManager?.redo()
            coordinator.lastRedoToken = redoToken
        }
        if coordinator.lastClearAnswersToken != clearAnswersToken {
            coordinator.clearAllDrawings()
            coordinator.lastClearAnswersToken = clearAnswersToken
        }
        if coordinator.lastReloadDrawingsToken != reloadDrawingsToken {
            coordinator.reloadAllCanvases()
            coordinator.lastReloadDrawingsToken = reloadDrawingsToken
        }
    }

    @MainActor
    final class Coordinator: NSObject,
        PKCanvasViewDelegate,
        UIGestureRecognizerDelegate
    {
        var parent: PDFKitCanvasView
        weak var host: PDFDrawingHostView?
        weak var pdfView: PDFView?
        weak var selectionGesture: UIPanGestureRecognizer?
        weak var activeCanvas: PKCanvasView?

        var canvases: [PDFPage: PKCanvasView] = [:]
        var pageIndexByCanvas: [ObjectIdentifier: Int] = [:]
        private let toolPicker = PKToolPicker()
        private var toolPickerCanvasIDs: Set<ObjectIdentifier> = []
        private weak var toolPickerResponder: PKCanvasView?
        var lastSelectionActionToken = 0
        var lastCancelSelectionToken = 0
        var lastUndoToken = 0
        var lastRedoToken = 0
        var lastClearAnswersToken = 0
        var lastReloadDrawingsToken = 0

        private var isCanvasLayoutScheduled = false
        private var selectionRect: CGRect?
        private var gestureStartPoint: CGPoint = .zero
        private var gestureStartRect: CGRect = .zero
        private var adjustment: SelectionAdjustment = .creating
        private let selectionLayer = CAShapeLayer()
        private let handleLayer = CAShapeLayer()

        private enum SelectionAdjustment {
            case creating
            case moving
            case resizing(SelectionHandle)
        }

        private enum SelectionHandle: CaseIterable {
            case topLeft
            case top
            case topRight
            case right
            case bottomRight
            case bottom
            case bottomLeft
            case left
        }

        init(parent: PDFKitCanvasView) {
            self.parent = parent
            super.init()
            toolPicker.stateAutosaveName = "PaperClip.PDFTools"

            selectionLayer.fillColor = UIColor.systemOrange.withAlphaComponent(0.12).cgColor
            selectionLayer.strokeColor = UIColor.systemOrange.cgColor
            selectionLayer.lineWidth = 2
            selectionLayer.lineDashPattern = [7, 5]

            handleLayer.fillColor = UIColor.systemBackground.cgColor
            handleLayer.strokeColor = UIColor.systemOrange.cgColor
            handleLayer.lineWidth = 2
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func attach(
            host: PDFDrawingHostView,
            selectionGesture: UIPanGestureRecognizer
        ) {
            self.host = host
            pdfView = host.pdfView
            self.selectionGesture = selectionGesture

            let center = NotificationCenter.default
            let notifications: [Notification.Name] = [
                .PDFViewPageChanged,
                .PDFViewScaleChanged,
                .PDFViewVisiblePagesChanged
            ]
            notifications.forEach { name in
                center.addObserver(
                    self,
                    selector: #selector(handlePDFViewChange),
                    name: name,
                    object: host.pdfView
                )
            }
            // App 回到前台（从其他 App 切回）时强制重新布局，
            // 避免 Stage Manager / Slide Over 窗口尺寸变化导致 PDF 显示不全。
            center.addObserver(
                self,
                selector: #selector(handleAppDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )

            configurePDFInteraction()
            scheduleCanvasLayout()
        }

        @objc private func handlePDFViewChange() {
            scheduleCanvasLayout()
        }

        @objc private func handleAppDidBecomeActive() {
            // 不直接操作 pdfView：didBecomeActive 触发时 UIKit 布局管道尚未稳定，
            // 此时 toggle autoScales 会与 PDFKit 自身的唤醒流程竞争，导致重算结果被覆盖。
            // 正确做法：通过 setNeedsLayout 将重算推迟到下一个 layoutSubviews，
            // 那里可以保证 pdfView.frame 已是最终值。
            host?.scheduleScaleReset()
            scheduleCanvasLayout()
        }

        func scheduleCanvasLayout() {
            guard !isCanvasLayoutScheduled else { return }
            isCanvasLayoutScheduled = true

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                isCanvasLayoutScheduled = false
                installVisibleCanvases()
                layoutCanvases()
                updateToolPickerVisibility()
            }
        }

        private func installVisibleCanvases() {
            guard let pdfView,
                  let document = pdfView.document,
                  let documentView = pdfView.documentView
            else { return }

            documentView.isUserInteractionEnabled = true
            var pages = pdfView.visiblePages
            if pages.isEmpty, let currentPage = pdfView.currentPage {
                pages = [currentPage]
            }

            let visiblePages = Set(pages)
            let pagesToRemove = canvases.keys.filter { !visiblePages.contains($0) }
            for page in pagesToRemove {
                removeCanvas(for: page)
            }

            for page in pages where canvases[page] == nil {
                let canvas = makeCanvas()
                let pageIndex = document.index(for: page)

                pageIndexByCanvas[ObjectIdentifier(canvas)] = pageIndex
                if let data = parent.drawings[pageIndex],
                   let drawing = try? PKDrawing(data: data) {
                    canvas.drawing = drawing
                }

                canvases[page] = canvas
                documentView.addSubview(canvas)
                registerWithToolPicker(canvas)
                configure(canvas)
            }
        }

        private func makeCanvas() -> PKCanvasView {
            let canvas = PKCanvasView()
            canvas.backgroundColor = .clear
            canvas.isOpaque = false
            canvas.drawingPolicy = .pencilOnly
            canvas.delegate = self
            canvas.isScrollEnabled = false
            canvas.bounces = false
            canvas.alwaysBounceHorizontal = false
            canvas.alwaysBounceVertical = false
            canvas.minimumZoomScale = 1
            canvas.maximumZoomScale = 1
            canvas.drawingGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.pencil.rawValue)
            ]
            canvas.drawingGestureRecognizer.cancelsTouchesInView = true
            canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 3)
            return canvas
        }

        private func layoutCanvases() {
            guard let pdfView,
                  let documentView = pdfView.documentView
            else { return }

            var sizes: [Int: CGSize] = [:]
            for (page, canvas) in canvases {
                let pageRect = pdfView.convert(page.bounds(for: .mediaBox), from: page)
                let frame = documentView.convert(pageRect, from: pdfView).standardized
                guard frame.width > 1, frame.height > 1 else { continue }

                canvas.frame = frame
                canvas.contentSize = frame.size
                documentView.bringSubviewToFront(canvas)
                configure(canvas)

                // 记录精确 canvas 尺寸（frame.size = mediaBox × scaleFactor）
                if let idx = pdfView.document?.index(for: page) {
                    sizes[idx] = frame.size
                }
            }

            // 上报每页精确 canvas 尺寸，供导出叠加使用
            let onCanvasSizesChanged = parent.onCanvasSizesChanged
            DispatchQueue.main.async {
                onCanvasSizesChanged?(sizes)
            }
        }

        func configurePDFInteraction() {
            guard let pdfView else { return }

            let nonPencilTouchTypes = [
                NSNumber(value: UITouch.TouchType.direct.rawValue),
                NSNumber(value: UITouch.TouchType.indirect.rawValue),
                NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)
            ]
            configurePDFGestures(
                in: pdfView,
                allowedTouchTypes: nonPencilTouchTypes
            )

            if let scrollView = pdfScrollView(in: pdfView) {
                scrollView.isScrollEnabled = !parent.isSelectionMode
                scrollView.delaysContentTouches = false
                scrollView.canCancelContentTouches = true
                scrollView.panGestureRecognizer.minimumNumberOfTouches = 1
            }
        }

        private func configurePDFGestures(
            in view: UIView,
            allowedTouchTypes: [NSNumber]
        ) {
            guard !(view is PKCanvasView) else { return }

            view.gestureRecognizers?.forEach { gesture in
                if gesture !== selectionGesture {
                    gesture.allowedTouchTypes = allowedTouchTypes
                }
            }
            view.subviews.forEach {
                configurePDFGestures(
                    in: $0,
                    allowedTouchTypes: allowedTouchTypes
                )
            }
        }

        private func pdfScrollView(in view: UIView) -> UIScrollView? {
            if let scrollView = view as? UIScrollView,
               !(scrollView is PKCanvasView) {
                return scrollView
            }
            for subview in view.subviews {
                if let scrollView = pdfScrollView(in: subview) {
                    return scrollView
                }
            }
            return nil
        }

        func updateCanvases() {
            canvases.values.forEach(configure)
        }

        private func registerWithToolPicker(_ canvas: PKCanvasView) {
            let canvasID = ObjectIdentifier(canvas)
            guard toolPickerCanvasIDs.insert(canvasID).inserted else { return }
            toolPicker.addObserver(canvas)
        }

        private func removeCanvas(for page: PDFPage) {
            guard let canvas = canvases.removeValue(forKey: page) else { return }
            let canvasID = ObjectIdentifier(canvas)

            if toolPickerResponder === canvas {
                toolPicker.setVisible(false, forFirstResponder: canvas)
                canvas.resignFirstResponder()
                toolPickerResponder = nil
            }
            if activeCanvas === canvas {
                activeCanvas = nil
            }

            canvas.delegate = nil
            toolPicker.removeObserver(canvas)
            toolPickerCanvasIDs.remove(canvasID)
            pageIndexByCanvas.removeValue(forKey: canvasID)
            canvas.removeFromSuperview()
        }

        func updateToolPickerVisibility() {
            guard pdfView != nil else { return }

            let shouldShow = parent.isWritingEnabled
                && !parent.isSelectionMode
                && parent.isDrawingVisible

            guard shouldShow else {
                if let responder = toolPickerResponder {
                    toolPicker.setVisible(false, forFirstResponder: responder)
                    responder.resignFirstResponder()
                }
                toolPickerResponder = nil
                return
            }

            guard let canvas = preferredCanvas() else {
                scheduleCanvasLayout()
                return
            }

            if let previousResponder = toolPickerResponder,
               previousResponder !== canvas {
                toolPicker.setVisible(false, forFirstResponder: previousResponder)
                previousResponder.resignFirstResponder()
            }
            registerWithToolPicker(canvas)
            toolPickerResponder = canvas
            DispatchQueue.main.async { [weak self, weak canvas] in
                guard let self, let canvas else { return }
                canvas.becomeFirstResponder()
                self.toolPicker.setVisible(true, forFirstResponder: canvas)
            }
        }

        private func preferredCanvas() -> PKCanvasView? {
            if let currentPage = pdfView?.currentPage,
               let canvas = canvases[currentPage] {
                return canvas
            }
            for page in pdfView?.visiblePages ?? [] {
                if let canvas = canvases[page] {
                    return canvas
                }
            }
            if let activeCanvas {
                return activeCanvas
            }
            return canvases.values.first
        }

        private func configure(_ canvas: PKCanvasView) {
            canvas.alpha = parent.isDrawingVisible ? 1 : 0
            let canDraw = parent.isWritingEnabled
                && !parent.isSelectionMode
                && parent.isDrawingVisible
            canvas.isUserInteractionEnabled = canDraw
            canvas.drawingGestureRecognizer.isEnabled = canDraw
            canvas.drawingGestureRecognizer.allowedTouchTypes = [
                NSNumber(value: UITouch.TouchType.pencil.rawValue)
            ]
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            activeCanvas = canvasView
            persist(canvasView)
        }

        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            activeCanvas = canvasView
            toolPickerResponder = canvasView
        }

        private func persist(_ canvas: PKCanvasView) {
            guard let index = pageIndexByCanvas[ObjectIdentifier(canvas)] else { return }
            parent.onDrawingChanged(index, canvas.drawing.dataRepresentation())
        }

        func clearAllDrawings() {
            canvases.values.forEach { canvas in
                canvas.delegate = nil
                canvas.drawing = PKDrawing()
                canvas.undoManager?.removeAllActions()
                canvas.delegate = self
            }
            activeCanvas = nil
        }

        /// 销毁全部 canvas 并从 parent.drawings 重新加载，切换做题会话时调用。
        func reloadAllCanvases() {
            for page in Array(canvases.keys) {
                removeCanvas(for: page)
            }
            activeCanvas = nil
            scheduleCanvasLayout()
        }

        func tearDown() {
            NotificationCenter.default.removeObserver(self)
            clearSelection(notify: false)
            for page in Array(canvases.keys) {
                removeCanvas(for: page)
            }
            selectionGesture = nil
            pdfView = nil
            host = nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            parent.isSelectionMode
        }

        @objc func handleSelection(_ gesture: UIPanGestureRecognizer) {
            guard let pdfView else { return }
            let point = gesture.location(in: pdfView)

            switch gesture.state {
            case .began:
                notifySelectionRect(nil)
                gestureStartPoint = point
                gestureStartRect = selectionRect ?? .zero

                if let selectionRect,
                   let handle = handle(at: point, in: selectionRect) {
                    adjustment = .resizing(handle)
                } else if let selectionRect,
                          selectionRect.insetBy(dx: -10, dy: -10).contains(point) {
                    adjustment = .moving
                } else {
                    adjustment = .creating
                    selectionRect = CGRect(origin: point, size: .zero)
                }
                installSelectionLayers(in: pdfView)
            case .changed:
                updateSelection(to: point, in: pdfView.bounds)
            case .ended:
                updateSelection(to: point, in: pdfView.bounds)
                guard let selectionRect,
                      selectionRect.width >= 32,
                      selectionRect.height >= 32
                else {
                    clearSelection()
                    return
                }
                notifySelectionRect(selectionRect)
            default:
                if selectionRect?.width ?? 0 < 32 || selectionRect?.height ?? 0 < 32 {
                    clearSelection()
                }
            }
        }

        func confirmSelection(action: PDFSelectionAction) {
            guard let pdfView,
                  let viewRect = selectionRect,
                  let page = pdfView.page(
                    for: CGPoint(x: viewRect.midX, y: viewRect.midY),
                    nearest: true
                  )
            else { return }

            let pageRect = pdfView.convert(viewRect, to: page)
            let boundedRect = pageRect.intersection(page.bounds(for: .mediaBox))
            guard boundedRect.width > 8,
                  boundedRect.height > 8,
                  let image = PDFCropRenderer.image(from: page, cropRect: boundedRect)
            else { return }

            clearSelection()
            let onCrop = parent.onCrop
            DispatchQueue.main.async {
                onCrop(
                    image,
                    boundedRect.width,
                    boundedRect.height,
                    action
                )
            }
        }

        func clearSelection(notify: Bool = true) {
            selectionRect = nil
            selectionLayer.removeFromSuperlayer()
            selectionLayer.path = nil
            handleLayer.removeFromSuperlayer()
            handleLayer.path = nil
            if notify {
                notifySelectionRect(nil)
            }
        }

        private func notifySelectionRect(_ rect: CGRect?) {
            let onSelectionRectChanged = parent.onSelectionRectChanged
            DispatchQueue.main.async {
                onSelectionRectChanged(rect)
            }
        }

        private func updateSelection(to point: CGPoint, in bounds: CGRect) {
            let proposedRect: CGRect
            switch adjustment {
            case .creating:
                proposedRect = normalizedRect(from: gestureStartPoint, to: point)
            case .moving:
                proposedRect = gestureStartRect.offsetBy(
                    dx: point.x - gestureStartPoint.x,
                    dy: point.y - gestureStartPoint.y
                )
            case let .resizing(handle):
                proposedRect = resizedRect(
                    gestureStartRect,
                    using: handle,
                    translation: CGPoint(
                        x: point.x - gestureStartPoint.x,
                        y: point.y - gestureStartPoint.y
                    )
                )
            }

            selectionRect = constrained(proposedRect, to: bounds)
            updateSelectionLayers()
        }

        private func installSelectionLayers(in pdfView: PDFView) {
            if selectionLayer.superlayer == nil {
                pdfView.layer.addSublayer(selectionLayer)
            }
            if handleLayer.superlayer == nil {
                pdfView.layer.addSublayer(handleLayer)
            }
            updateSelectionLayers()
        }

        private func updateSelectionLayers() {
            guard let selectionRect else { return }
            selectionLayer.path = UIBezierPath(rect: selectionRect).cgPath

            let handles = UIBezierPath()
            for handle in SelectionHandle.allCases {
                let center = point(for: handle, in: selectionRect)
                handles.append(
                    UIBezierPath(
                        ovalIn: CGRect(
                            x: center.x - 7,
                            y: center.y - 7,
                            width: 14,
                            height: 14
                        )
                    )
                )
            }
            handleLayer.path = handles.cgPath
        }

        private func handle(at point: CGPoint, in rect: CGRect) -> SelectionHandle? {
            SelectionHandle.allCases.first {
                let center = self.point(for: $0, in: rect)
                return hypot(point.x - center.x, point.y - center.y) <= 26
            }
        }

        private func point(for handle: SelectionHandle, in rect: CGRect) -> CGPoint {
            switch handle {
            case .topLeft: CGPoint(x: rect.minX, y: rect.minY)
            case .top: CGPoint(x: rect.midX, y: rect.minY)
            case .topRight: CGPoint(x: rect.maxX, y: rect.minY)
            case .right: CGPoint(x: rect.maxX, y: rect.midY)
            case .bottomRight: CGPoint(x: rect.maxX, y: rect.maxY)
            case .bottom: CGPoint(x: rect.midX, y: rect.maxY)
            case .bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
            case .left: CGPoint(x: rect.minX, y: rect.midY)
            }
        }

        private func resizedRect(
            _ rect: CGRect,
            using handle: SelectionHandle,
            translation: CGPoint
        ) -> CGRect {
            var left = rect.minX
            var right = rect.maxX
            var top = rect.minY
            var bottom = rect.maxY

            switch handle {
            case .topLeft:
                left += translation.x
                top += translation.y
            case .top:
                top += translation.y
            case .topRight:
                right += translation.x
                top += translation.y
            case .right:
                right += translation.x
            case .bottomRight:
                right += translation.x
                bottom += translation.y
            case .bottom:
                bottom += translation.y
            case .bottomLeft:
                left += translation.x
                bottom += translation.y
            case .left:
                left += translation.x
            }

            return normalizedRect(
                from: CGPoint(x: left, y: top),
                to: CGPoint(x: right, y: bottom)
            )
        }

        private func constrained(_ rect: CGRect, to bounds: CGRect) -> CGRect {
            guard !bounds.isEmpty else { return rect }

            var result = rect
            if result.width > bounds.width {
                result.origin.x = bounds.minX
                result.size.width = bounds.width
            } else {
                result.origin.x = min(max(result.minX, bounds.minX), bounds.maxX - result.width)
            }

            if result.height > bounds.height {
                result.origin.y = bounds.minY
                result.size.height = bounds.height
            } else {
                result.origin.y = min(max(result.minY, bounds.minY), bounds.maxY - result.height)
            }
            return result
        }

        private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
            CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
        }
    }
}

final class PDFDrawingHostView: UIView {
    let pdfView = PDFView()
    var onLayout: (() -> Void)?

    private var lastBounds: CGRect = .zero
    /// 标记需要在下一次 layoutSubviews 中重算 PDF 缩放比例。
    /// 由 scheduleScaleReset() 设置，确保重算在 frame 稳定后执行。
    private var pendingScaleReset = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        addSubview(pdfView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pdfView.frame = bounds

        // 在 layoutSubviews 内执行 autoScales toggle 是唯一能保证
        // pdfView.frame 已为最终值的时机（UIKit 在此之前完成所有 frame 更新）。
        // 触发条件：bounds 变化（旋转/分屏）或外部显式请求（App 回到前台）。
        if pendingScaleReset || bounds != lastBounds {
            pendingScaleReset = false
            lastBounds = bounds
            if pdfView.autoScales {
                pdfView.autoScales = false
                pdfView.autoScales = true
            }
        }

        onLayout?()
    }

    /// 请求在下一个布局周期重算 PDF 缩放比例。
    /// 使用 setNeedsLayout() 将重算推迟到 layoutSubviews，
    /// 避免在 UIKit 布局管道尚未稳定时与 PDFKit 内部唤醒流程竞争。
    func scheduleScaleReset() {
        pendingScaleReset = true
        setNeedsLayout()
    }
}

enum PDFCropRenderer {
    static func image(from page: PDFPage, cropRect: CGRect) -> UIImage? {
        let pageBounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2
        let thumbnailSize = CGSize(width: pageBounds.width * scale, height: pageBounds.height * scale)
        let fullImage = page.thumbnail(of: thumbnailSize, for: .mediaBox)
        guard let cgImage = fullImage.cgImage else { return nil }

        let imageScaleX = CGFloat(cgImage.width) / pageBounds.width
        let imageScaleY = CGFloat(cgImage.height) / pageBounds.height
        let crop = CGRect(
            x: (cropRect.minX - pageBounds.minX) * imageScaleX,
            y: (pageBounds.maxY - cropRect.maxY) * imageScaleY,
            width: cropRect.width * imageScaleX,
            height: cropRect.height * imageScaleY
        ).integral.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard crop.width > 0, crop.height > 0,
              let cropped = cgImage.cropping(to: crop)
        else { return nil }
        return UIImage(cgImage: cropped)
    }
}
