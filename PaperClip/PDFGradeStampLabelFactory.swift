import UIKit

@MainActor
enum PDFGradeStampLabelFactory {
    static func makeLabel(for stamp: PDFGradeStamp) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 25, weight: .bold)
        label.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.86)
        label.layer.cornerRadius = 17
        label.layer.borderWidth = 2
        label.layer.masksToBounds = true
        label.layer.zPosition = 20
        label.isAccessibilityElement = true
        label.accessibilityLabel = stamp.isCorrect ? "正确印章" : "错误印章"
        return label
    }

    static func configure(_ label: UILabel, for stamp: PDFGradeStamp) {
        label.text = stamp.isCorrect ? "✓" : "✕"
        label.textColor = stamp.isCorrect ? .systemGreen : .systemRed
        label.layer.borderColor = label.textColor.cgColor
        label.alpha = stamp.confidence > 0 && stamp.confidence < 0.65 ? 0.72 : 1
    }
}
