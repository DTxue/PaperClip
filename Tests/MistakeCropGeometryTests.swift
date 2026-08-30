import CoreGraphics
import Foundation

@main
enum MistakeCropGeometryTests {
    static func main() {
        let fitted = MistakeCropGeometry.aspectFitRect(
            imageSize: CGSize(width: 400, height: 200),
            containerSize: CGSize(width: 300, height: 300)
        )
        expect(fitted == CGRect(x: 0, y: 75, width: 300, height: 150), "aspect-fit rect is centered")

        let normalized = MistakeCropGeometry.normalizedSelection(
            CGRect(x: 75, y: 112.5, width: 150, height: 75),
            in: fitted
        )
        expect(normalized == CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5), "selection normalizes inside the image")
        expect(
            MistakeCropGeometry.selectionRect(from: normalized!, in: fitted)
                == CGRect(x: 75, y: 112.5, width: 150, height: 75),
            "normalized selection maps back to display coordinates"
        )

        let moved = MistakeCropGeometry.moving(
            CGRect(x: 40, y: 100, width: 100, height: 60),
            translation: CGSize(width: -100, height: 200),
            within: fitted
        )
        expect(moved == CGRect(x: 0, y: 165, width: 100, height: 60), "moving stays inside the image")

        let resized = MistakeCropGeometry.resizing(
            CGRect(x: 50, y: 100, width: 100, height: 80),
            handle: .topLeading,
            translation: CGSize(width: 90, height: 90),
            within: fitted,
            minimumSize: 44
        )
        expect(resized == CGRect(x: 106, y: 136, width: 44, height: 44), "resizing enforces the minimum size")

        let pixels = MistakeCropGeometry.pixelCropRect(
            normalizedSelection: CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.8),
            pixelSize: CGSize(width: 1200, height: 800)
        )
        expect(pixels == CGRect(x: 300, y: 80, width: 600, height: 640), "normalized selection maps to pixels")

        let clippedPixels = MistakeCropGeometry.pixelCropRect(
            normalizedSelection: CGRect(x: -0.2, y: 0.8, width: 0.5, height: 0.5),
            pixelSize: CGSize(width: 100, height: 100)
        )
        expect(clippedPixels == CGRect(x: 0, y: 80, width: 30, height: 20), "pixel crop is clipped to the source image")

        print("MistakeCropGeometryTests: 7 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
