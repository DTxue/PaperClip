import CoreGraphics
import Foundation

enum LocalImageCacheKey {
    static func make(path: String, crop: String?, maxPixelSize: CGFloat?) -> String {
        let pixelKey = maxPixelSize.map { "@\(Int($0))px" } ?? "@original"
        return "\(path)@\(cropKey(crop))\(pixelKey)"
    }

    private static func cropKey(_ crop: String?) -> String {
        guard let crop,
              let rect = NormalizedCropString.parse(crop),
              rect.width > 0,
              rect.height > 0
        else {
            return "full"
        }
        return NormalizedCropString.format(rect)
    }
}
