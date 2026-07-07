import SwiftUI

enum GeoDrawingTool: String, CaseIterable, Identifiable {
    case pan = "pan"
    case pointer = "pointer"
    case point = "point"
    case segment = "segment"
    case circle = "circle"
    case triangle = "triangle"
    case arrow = "arrow"
    case rightAngle = "rightAngle"
    case angleMark = "angleMark"
    case editLabel = "editLabel"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pan: return "拖动画布"
        case .pointer: return "选择"
        case .point: return "点"
        case .segment: return "线段"
        case .circle: return "圆"
        case .triangle: return "三角形"
        case .arrow: return "箭头"
        case .rightAngle: return "直角"
        case .angleMark: return "角"
        case .editLabel: return "改字母"
        }
    }

    var sfSymbol: String {
        switch self {
        case .pan: return "hand.draw"
        case .pointer: return "cursorarrow"
        case .point: return "circle.fill"
        case .segment: return "line.diagonal"
        case .circle: return "circle"
        case .triangle: return "triangle"
        case .arrow: return "arrow.up.right"
        case .rightAngle: return "l.square"
        case .angleMark: return "angle"
        case .editLabel: return "character.textbox"
        }
    }

    var requiredPoints: Int {
        switch self {
        case .pan, .pointer, .point, .editLabel: return 0
        case .segment, .circle, .arrow: return 2
        case .triangle, .rightAngle, .angleMark: return 3
        }
    }
}

enum ScratchGridStyle: String, CaseIterable {
    case none = "无网格"
    case square = "方格"
    case dot = "点阵"
}
