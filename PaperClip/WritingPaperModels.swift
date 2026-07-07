import CoreGraphics
import Foundation

enum WritingPaperStyle: String, CaseIterable, Identifiable, Codable {
    case lined
    case grid

    var id: Self { self }

    var title: String {
        switch self {
        case .lined: "横线"
        case .grid: "方格"
        }
    }

    static func available(for language: WritingLanguage) -> [WritingPaperStyle] {
        switch language {
        case .chinese: [.lined, .grid]
        case .english: [.lined]
        }
    }
}

enum WritingPaperMetrics {
    static let geometryTolerance: Double = 0.5
    static let defaultWidth: Double = 820
    static let defaultHeight: Double = 1500
    static let minWidth: Double = 640
    static let maxWidth: Double = 1400
    static let minHeight: Double = 900
    static let maxHeight: Double = 2600
    static let legacyLineSpacing: Double = 42
    static let legacyGridSpacing: Double = 36
    static let defaultLineSpacing: Double = 48
    static let defaultGridSpacing: Double = 42
    static let minRulingSpacing: Double = 28
    static let maxRulingSpacing: Double = 72

    static var defaultSize: CGSize {
        CGSize(width: defaultWidth, height: defaultHeight)
    }

    static func defaultRulingSpacing(for style: WritingPaperStyle) -> Double {
        switch style {
        case .lined: defaultLineSpacing
        case .grid: defaultGridSpacing
        }
    }

    static func legacyRulingSpacing(for style: WritingPaperStyle) -> Double {
        switch style {
        case .lined: legacyLineSpacing
        case .grid: legacyGridSpacing
        }
    }

    static func clampedSize(width: Double, height: Double) -> CGSize {
        CGSize(
            width: min(max(width, minWidth), maxWidth),
            height: min(max(height, minHeight), maxHeight)
        )
    }

    static func clampedRulingSpacing(_ spacing: Double) -> Double {
        min(max(spacing, minRulingSpacing), maxRulingSpacing)
    }

    static func isClose(_ lhs: CGSize, to rhs: CGSize, tolerance: Double = geometryTolerance) -> Bool {
        abs(Double(lhs.width - rhs.width)) <= tolerance
            && abs(Double(lhs.height - rhs.height)) <= tolerance
    }

    static func isClose(_ lhs: Double, to rhs: Double, tolerance: Double = geometryTolerance) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}
