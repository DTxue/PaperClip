import PDFKit
import UIKit

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

        let shouldResetScale = pendingScaleReset || bounds != lastBounds
        // 在 layoutSubviews 内执行 autoScales toggle 是唯一能保证
        // pdfView.frame 已为最终值的时机（UIKit 在此之前完成所有 frame 更新）。
        // 触发条件：bounds 变化（旋转/分屏）或外部显式请求（App 回到前台）。
        if shouldResetScale {
            pendingScaleReset = false
            lastBounds = bounds
            if pdfView.autoScales {
                pdfView.autoScales = false
                pdfView.autoScales = true
            }
        }

        if shouldResetScale {
            onLayout?()
        }
    }

    /// 请求在下一个布局周期重算 PDF 缩放比例。
    /// 使用 setNeedsLayout() 将重算推迟到 layoutSubviews，
    /// 避免在 UIKit 布局管道尚未稳定时与 PDFKit 内部唤醒流程竞争。
    func scheduleScaleReset() {
        pendingScaleReset = true
        setNeedsLayout()
    }
}
