import CoreGraphics
import Foundation

@main
struct LocalImageCacheKeyTests {
    static func main() {
        expect(
            LocalImageCacheKey.make(path: "/tmp/card.png", crop: nil, maxPixelSize: nil) == "/tmp/card.png@full@original",
            "original full-image requests should have a stable key"
        )
        expect(
            LocalImageCacheKey.make(path: "/tmp/card.png", crop: "0,0,0.5,0.5", maxPixelSize: 600) == "/tmp/card.png@0.0,0.0,0.5,0.5@600px",
            "cropped downsampled requests should include crop and pixel size"
        )
        expect(
            LocalImageCacheKey.make(path: "/tmp/card.png", crop: nil, maxPixelSize: 600.9) == "/tmp/card.png@full@600px",
            "pixel sizes should match existing integer truncation behavior"
        )
        expect(
            LocalImageCacheKey.make(path: "/tmp/card.png", crop: "0.10,0.20,0.30,0.40", maxPixelSize: 600)
                == "/tmp/card.png@0.1,0.2,0.3,0.4@600px",
            "equivalent crop strings should share one cache key"
        )
        expect(
            LocalImageCacheKey.make(path: "/tmp/card.png", crop: "bad", maxPixelSize: 600)
                == "/tmp/card.png@full@600px",
            "invalid crop strings should use the full-image key"
        )
        print("LocalImageCacheKeyTests: 5 passed")
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
