import UIKit

@MainActor
final class PDFSelectionLayerCoordinator {
    private let selectionLayer = CAShapeLayer()
    private let handleLayer = CAShapeLayer()

    init() {
        selectionLayer.fillColor = UIColor.systemOrange.withAlphaComponent(0.12).cgColor
        selectionLayer.strokeColor = UIColor.systemOrange.cgColor
        selectionLayer.lineWidth = 2
        selectionLayer.lineDashPattern = [7, 5]

        handleLayer.fillColor = UIColor.systemBackground.cgColor
        handleLayer.strokeColor = UIColor.systemOrange.cgColor
        handleLayer.lineWidth = 2
    }

    func install(in layer: CALayer) {
        if selectionLayer.superlayer == nil {
            layer.addSublayer(selectionLayer)
        }
        if handleLayer.superlayer == nil {
            layer.addSublayer(handleLayer)
        }
    }

    func update(_ rect: CGRect) {
        selectionLayer.path = UIBezierPath(rect: rect).cgPath

        let handles = UIBezierPath()
        for handle in PDFSelectionHandle.allCases {
            let center = PDFSelectionGeometry.point(for: handle, in: rect)
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

    func clear() {
        selectionLayer.removeFromSuperlayer()
        selectionLayer.path = nil
        handleLayer.removeFromSuperlayer()
        handleLayer.path = nil
    }
}
