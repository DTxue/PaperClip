import SwiftUI

// MARK: - 几何画板数据模型（点优先架构）
//
// 业务需求说明（均无系统等价实现）：
// 1. 透明度可调的浮动面板
// 2. 方格/点阵网格背景
// 3. 点优先几何图形绘制：GeoPoint 是独立实体，GeoShape 通过 pointIDs 引用点
//    移动点时所有依赖该点的图形自动更新（无需额外代码）
// 4. 已有点标签修改（A-Z, α-ω 等），不创建独立文字对象
// 已评估：辅助功能、深色模式、多窗口、系统手势、Apple Pencil 分流。

struct GeoStyle {
    var color: Color = .blue
    var lineWidth: CGFloat = 2
}

struct GeoPoint: Identifiable, Equatable {
    var id = UUID()
    var position: CGPoint
    var label: String
}

enum GeoShapeKind {
    case segment           // pointIDs: [p1, p2]
    case circle            // pointIDs: [center, rim]
    case polygon           // pointIDs: [v0...vN], 闭合多边形
    case arrow             // pointIDs: [from, to]
    case rightAngleMark    // pointIDs: [arm1, vertex, arm2]
    case angleMark         // pointIDs: [arm1, vertex, arm2]
}

struct GeoShape: Identifiable {
    var id = UUID()
    var kind: GeoShapeKind
    var pointIDs: [UUID]
    var style: GeoStyle
}

struct GeoCanvas {
    var points: [GeoPoint] = []
    var shapes: [GeoShape] = []

    func point(_ id: UUID) -> GeoPoint? { points.first { $0.id == id } }
    func pos(_ id: UUID) -> CGPoint { point(id)?.position ?? .zero }
}
