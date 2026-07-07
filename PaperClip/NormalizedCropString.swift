import CoreGraphics
import Foundation

enum NormalizedCropString {
    static func parse(_ string: String) -> CGRect? {
        let parts = string.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }

    static func format(_ rect: CGRect) -> String {
        "\(rect.minX),\(rect.minY),\(rect.width),\(rect.height)"
    }
}
