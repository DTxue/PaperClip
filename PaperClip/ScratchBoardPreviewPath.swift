import SwiftUI

enum ScratchBoardPreviewPath {
    static func path(
        tool: GeoDrawingTool,
        staged: [CGPoint],
        preview: CGPoint
    ) -> Path? {
        var path = Path()
        switch tool {
        case .segment, .arrow, .circle:
            guard staged.count == 1 else { return nil }
            path.move(to: staged[0])
            path.addLine(to: preview)
        case .triangle:
            if staged.count == 1 {
                path.move(to: staged[0])
                path.addLine(to: preview)
            } else if staged.count == 2 {
                path.move(to: staged[0])
                path.addLine(to: staged[1])
                path.move(to: staged[1])
                path.addLine(to: preview)
                path.move(to: preview)
                path.addLine(to: staged[0])
            } else {
                return nil
            }
        case .rightAngle, .angleMark:
            guard !staged.isEmpty else { return nil }
            path.move(to: staged[0])
            path.addLine(to: preview)
            if staged.count >= 2 {
                path.move(to: staged[1])
                path.addLine(to: preview)
            }
        default:
            return nil
        }
        return path
    }
}
