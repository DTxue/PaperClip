import SwiftUI
import PencilKit

// MARK: - FloatingScratchBoard
//
// 自定义理由：
// - SwiftUI/PencilKit 无浮动可移动画布
// - 无内置透明度调节、网格背景、几何图形绘制能力
// - 点优先架构：GeoPoint 独立存储，图形通过 pointIDs 引用，移动点时图形自动更新

struct FloatingScratchBoard: View {
    let onClose: () -> Void

    // 面板布局
    @State var clearToken = 0
    @State var panelSize = CGSize(width: 800, height: 440)
    @State var panelCenter: CGPoint?
    @GestureState var moveTranslation: CGSize = .zero
    @GestureState var resizeTranslation: CGSize = .zero

    // 背景
    @State var backgroundOpacity: Double = 0.92
    @State var showOpacitySlider = false

    // 网格
    @State var gridStyle: ScratchGridStyle = .none
    @State var gridSpacing: CGFloat = 24

    // 几何画板状态
    @State var canvas = GeoCanvas()
    @State var undoStack: [GeoCanvas] = []
    @State var redoStack: [GeoCanvas] = []
    @State var isGeometricMode = false
    @State var currentTool: GeoDrawingTool = .pointer
    @State var interactionState: GeoInteractionState = .idle
    @State var snapResult: SnapResult? = nil
    @State var selectedIDs: Set<UUID> = []
    @State var shapeStyle = GeoStyle()
    @State var dragSnapshot: GeoCanvas? = nil
    @State var selectedLetter: String = "A"
    @State var isSnappingEnabled = true
    @State var snapToExistingPoints = true
    @State var snapToExistingLines = true
    @State var snapToGrid = true
    @State var bypassSnapOnce = false
    @State var viewportOrigin = CGPoint.zero
    @State var handwriting = PKDrawing()

    let pointSnapDistance: CGFloat = 18
    let lineSnapDistance: CGFloat = 12
    let gridSnapDistance: CGFloat = 7
    let virtualCanvasOrigin = CGPoint(x: 2_048, y: 2_048)
    let virtualCanvasSize = CGSize(width: 6_144, height: 6_144)
}
