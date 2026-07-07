import CoreGraphics
import Foundation

@discardableResult
func assert(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        print("FAIL: \(message)")
        exit(1)
    }
    return true
}

func assertEqual(_ lhs: CGFloat, _ rhs: CGFloat, accuracy: CGFloat = 0.0001, _ message: String) {
    assert(abs(lhs - rhs) <= accuracy, message)
}

func testPointLabelsAndReuse() {
    var canvas = GeoCanvas()
    let first = canvas.addPoint(at: CGPoint(x: 0, y: 0))
    let second = canvas.addPoint(at: CGPoint(x: 10, y: 0), automaticallyLabel: false)
    assert(first.label == "A", "first label")
    assert(second.label.isEmpty, "manual no-label point")
    let reused = canvas.getOrCreatePoint(near: CGPoint(x: 0.5, y: 0), threshold: 1)
    assert(reused.id == first.id, "near point should reuse existing")
    let created = canvas.getOrCreatePoint(near: CGPoint(x: 3, y: 0), threshold: 1)
    assert(created.id != first.id, "far point should create")
    assert(
        canvas.nearestPoint(to: CGPoint(x: 10.5, y: 0), threshold: 2, requireLabel: true) == nil,
        "nearest point should optionally require labels"
    )
    assert(
        canvas.nearestPoint(to: CGPoint(x: 0.5, y: 0), threshold: 2, excludingPoint: first.id) == nil,
        "nearest point should support excluding a dragged point"
    )
}

func testPointLabelsAfterAlphabet() {
    var canvas = GeoCanvas()
    for index in 0..<26 {
        let unicode = UnicodeScalar(Int(UnicodeScalar("A").value) + index)!
        canvas.points.append(GeoPoint(position: .zero, label: String(Character(unicode))))
    }

    let overflow = canvas.addPoint(at: CGPoint(x: 1, y: 1))
    assert(overflow.label == "P1", "labels after alphabet should use P1")
}

func testProjectionAndNearestLine() {
    var canvas = GeoCanvas()
    let a = canvas.addPoint(at: CGPoint(x: 0, y: 0))
    let b = canvas.addPoint(at: CGPoint(x: 10, y: 0))
    canvas.shapes.append(GeoShape(kind: .segment, pointIDs: [a.id, b.id], style: GeoStyle()))

    let projected = GeoShapeGeometry.projectedPoint(CGPoint(x: 4, y: 3), onSegmentFrom: a.position, to: b.position)
    assertEqual(projected.x, 4, "projected x")
    assertEqual(projected.y, 0, "projected y")
    assertEqual(
        GeoShapeGeometry.distanceSquared(CGPoint(x: 1, y: 1), CGPoint(x: 4, y: 5)),
        25,
        "distance squared"
    )
    assert(
        GeoShapeGeometry.isPoint(CGPoint(x: 4, y: 1), within: 2, ofSegmentFrom: a.position, to: b.position),
        "segment threshold helper"
    )
    let snap = canvas.nearestLinePosition(to: CGPoint(x: 4, y: 2), threshold: 3)
    assert(snap != nil, "line snap should find point")
    assertEqual(snap!.x, 4, "line snap x")
    assertEqual(snap!.y, 0, "line snap y")
}

func testHitTestingAndCascadeDelete() {
    var canvas = GeoCanvas()
    let a = canvas.addPoint(at: CGPoint(x: 0, y: 0))
    let b = canvas.addPoint(at: CGPoint(x: 10, y: 0))
    let segment = GeoShape(kind: .segment, pointIDs: [a.id, b.id], style: GeoStyle())
    canvas.shapes.append(segment)

    assert(canvas.hitShape(at: CGPoint(x: 5, y: 1), threshold: 2) == segment.id, "segment hit")
    canvas.delete(pointIDs: [a.id], shapeIDs: [])
    assert(canvas.points.count == 1, "point cascade delete")
    assert(canvas.shapes.isEmpty, "shape cascade delete")
}

func testCircleSnapAndHit() {
    var canvas = GeoCanvas()
    let center = canvas.addPoint(at: CGPoint(x: 0, y: 0))
    let rim = canvas.addPoint(at: CGPoint(x: 10, y: 0))
    let circle = GeoShape(kind: .circle, pointIDs: [center.id, rim.id], style: GeoStyle())
    canvas.shapes.append(circle)

    let snap = canvas.nearestLinePosition(to: CGPoint(x: 0, y: 12), threshold: 3)
    assert(snap != nil, "circle snap")
    assertEqual(snap!.x, 0, "circle snap x")
    assertEqual(snap!.y, 10, "circle snap y")
    assert(
        GeoShapeGeometry.isPoint(CGPoint(x: 0, y: 9), within: 2, ofCircleCenter: center.position, rim: rim.position),
        "circle threshold helper"
    )
    assert(canvas.hitShape(at: CGPoint(x: 0, y: 9), threshold: 2) == circle.id, "circle hit")
}

func testAngleHitTestingChecksBothArms() {
    var canvas = GeoCanvas()
    let a = canvas.addPoint(at: CGPoint(x: 0, y: 0))
    let vertex = canvas.addPoint(at: CGPoint(x: 10, y: 0))
    let b = canvas.addPoint(at: CGPoint(x: 10, y: 10))
    let angle = GeoShape(kind: .angleMark, pointIDs: [a.id, vertex.id, b.id], style: GeoStyle())
    canvas.shapes.append(angle)

    assert(canvas.hitShape(at: CGPoint(x: 10, y: 5), threshold: 1.5) == angle.id, "angle second arm hit")
}

func testPolygonHitAndNearestLineUseClosedEdges() {
    var canvas = GeoCanvas()
    let a = canvas.addPoint(at: CGPoint(x: 0, y: 0))
    let b = canvas.addPoint(at: CGPoint(x: 10, y: 0))
    let c = canvas.addPoint(at: CGPoint(x: 10, y: 10))
    let polygon = GeoShape(kind: .polygon, pointIDs: [a.id, b.id, c.id], style: GeoStyle())
    canvas.shapes.append(polygon)

    assert(canvas.hitShape(at: CGPoint(x: 5, y: 5), threshold: 1.5) == polygon.id, "polygon closing edge hit")
    let snap = canvas.nearestLinePosition(to: CGPoint(x: 5, y: 4), threshold: 2)
    assert(snap != nil, "polygon closing edge snap")
    assertEqual(snap!.x, 4.5, "polygon closing edge snap x")
    assertEqual(snap!.y, 4.5, "polygon closing edge snap y")
}

func testPanelGeometryConstrainsSizeAndCenter() {
    let available = CGSize(width: 500, height: 360)
    let constrainedSize = ScratchBoardPanelGeometry.constrainedSize(
        CGSize(width: 900, height: 80),
        in: available
    )
    assertEqual(constrainedSize.width, 476, "panel width should fit available size with edge insets")
    assertEqual(constrainedSize.height, 200, "panel height should respect minimum height")

    let constrainedCenter = ScratchBoardPanelGeometry.constrainedCenter(
        CGPoint(x: 20, y: 900),
        panelSize: constrainedSize,
        in: available
    )
    assertEqual(constrainedCenter.x, 250, "oversized panel should center horizontally when bounds invert")
    assertEqual(constrainedCenter.y, 248, "panel center should clamp to bottom edge")
}

func testPanelGeometryComputesEffectiveLayout() {
    let available = CGSize(width: 1_000, height: 800)
    let panelSize = CGSize(width: 400, height: 300)
    let displayedSize = ScratchBoardPanelGeometry.effectiveSize(
        panelSize: panelSize,
        resizeTranslation: CGSize(width: 120, height: -180),
        availableSize: available
    )
    assertEqual(displayedSize.width, 520, "effective width should include resize translation")
    assertEqual(displayedSize.height, 200, "effective height should clamp to minimum")

    let center = ScratchBoardPanelGeometry.effectiveCenter(
        panelSize: panelSize,
        panelCenter: CGPoint(x: 300, y: 300),
        moveTranslation: CGSize(width: 50, height: -20),
        displayedSize: displayedSize,
        availableSize: available
    )
    assertEqual(center.x, 410, "effective center should include move and resize delta")
    assertEqual(center.y, 230, "effective center should include move and resize delta")
}

func testPanelGeometryCommitsGestureLayouts() {
    let available = CGSize(width: 1_000, height: 800)
    let panelSize = CGSize(width: 400, height: 300)

    let movedCenter = ScratchBoardPanelGeometry.committedMoveCenter(
        panelSize: panelSize,
        panelCenter: CGPoint(x: 300, y: 300),
        moveTranslation: CGSize(width: 80, height: -40),
        availableSize: available
    )
    assertEqual(movedCenter.x, 380, "committed move should add x translation")
    assertEqual(movedCenter.y, 260, "committed move should add y translation")

    let resizedLayout = ScratchBoardPanelGeometry.committedResizeLayout(
        panelSize: panelSize,
        panelCenter: CGPoint(x: 300, y: 300),
        resizeTranslation: CGSize(width: 120, height: -180),
        availableSize: available
    )
    assertEqual(resizedLayout.size.width, 520, "committed resize should update width")
    assertEqual(resizedLayout.size.height, 200, "committed resize should clamp height")
    assertEqual(resizedLayout.center.x, 360, "committed resize should keep top-left stable on x")
    assertEqual(resizedLayout.center.y, 250, "committed resize should keep top-left stable on y")
}

func testViewportLogicPansConstrainsAndDetectsTaps() {
    let origin = ScratchBoardViewportLogic.pannedOrigin(
        startOrigin: CGPoint(x: 100, y: 50),
        translation: CGSize(width: 30, height: -20),
        limit: 2_048
    )
    assertEqual(origin.x, 70, "pan should subtract x translation")
    assertEqual(origin.y, 70, "pan should subtract y translation")

    let constrained = ScratchBoardViewportLogic.constrainedOrigin(
        CGPoint(x: 3_000, y: -4_000),
        limit: 2_048
    )
    assertEqual(constrained.x, 2_048, "viewport x should clamp to positive limit")
    assertEqual(constrained.y, -2_048, "viewport y should clamp to negative limit")
    assert(ScratchBoardViewportLogic.isTap(translation: CGSize(width: 3, height: 4)), "short translation should be a tap")
    assert(!ScratchBoardViewportLogic.isTap(translation: CGSize(width: 8, height: 0)), "threshold distance should not be a tap")
}

func testPreviewPathAvailabilityMatchesToolProgress() {
    let a = CGPoint(x: 0, y: 0)
    let b = CGPoint(x: 10, y: 0)
    let c = CGPoint(x: 10, y: 10)

    assert(ScratchBoardPreviewPath.path(tool: .segment, staged: [a], preview: b) != nil, "segment preview needs one point")
    assert(ScratchBoardPreviewPath.path(tool: .segment, staged: [], preview: b) == nil, "segment preview rejects no staged point")
    assert(ScratchBoardPreviewPath.path(tool: .triangle, staged: [a, b], preview: c) != nil, "triangle preview supports two points")
    assert(ScratchBoardPreviewPath.path(tool: .rightAngle, staged: [a], preview: b) != nil, "angle preview supports one arm")
    assert(ScratchBoardPreviewPath.path(tool: .pointer, staged: [a], preview: b) == nil, "pointer has no preview path")
}

@main
enum ScratchBoardGeometryTestRunner {
    static func main() {
        testPointLabelsAndReuse()
        testPointLabelsAfterAlphabet()
        testProjectionAndNearestLine()
        testHitTestingAndCascadeDelete()
        testCircleSnapAndHit()
        testAngleHitTestingChecksBothArms()
        testPolygonHitAndNearestLineUseClosedEdges()
        testPanelGeometryConstrainsSizeAndCenter()
        testPanelGeometryComputesEffectiveLayout()
        testPanelGeometryCommitsGestureLayouts()
        testViewportLogicPansConstrainsAndDetectsTaps()
        testPreviewPathAvailabilityMatchesToolProgress()
        print("ScratchBoardGeometryTests: 28 passed")
    }
}
