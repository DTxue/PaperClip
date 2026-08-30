import CoreGraphics

enum PDFExamGradingSupport {
    struct RawStampAnchor {
        let pageIndex: Int
        let x: Double
        let y: Double
    }

    private enum CoordinateScale {
        case normalized
        case percentage
        case thousand
        case pixels(Double)

        func normalize(_ value: Double) -> CGFloat {
            switch self {
            case .normalized:
                CGFloat(value)
            case .percentage:
                CGFloat(value / 100)
            case .thousand:
                CGFloat(value / 1_000)
            case .pixels(let extent):
                CGFloat(value / extent)
            }
        }
    }

    static func clampedStampAnchor(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0.04), 0.96),
            y: min(max(point.y, 0.04), 0.96)
        )
    }

    static func normalizedPointString(_ point: CGPoint) -> String {
        "\(Double(point.x)),\(Double(point.y))"
    }

    static func normalizedStampAnchorString(_ point: CGPoint) -> String {
        normalizedPointString(clampedStampAnchor(point))
    }

    static func normalizedStampAnchorString(x: Double, y: Double) -> String {
        normalizedStampAnchorString(x: x, y: y, pagePixelSize: nil)
    }

    static func normalizedStampAnchorString(
        x: Double,
        y: Double,
        pagePixelSize: CGSize?
    ) -> String {
        let point: CGPoint
        if let pagePixelSize,
           pagePixelSize.width > 0,
           pagePixelSize.height > 0,
           x > 100 || y > 100 {
            point = CGPoint(
                x: normalizedPixelCoordinate(
                    x,
                    extent: Double(pagePixelSize.width)
                ),
                y: normalizedPixelCoordinate(
                    y,
                    extent: Double(pagePixelSize.height)
                )
            )
        } else {
            point = CGPoint(
                x: normalizedModelCoordinate(x),
                y: normalizedModelCoordinate(y)
            )
        }
        return normalizedStampAnchorString(
            point
        )
    }

    static func normalizedStampAnchorStrings(
        _ anchors: [RawStampAnchor],
        pagePixelSizes: [Int: CGSize]
    ) -> [String] {
        var normalized = Array(repeating: "", count: anchors.count)
        let indicesByPage = Dictionary(grouping: anchors.indices) {
            anchors[$0].pageIndex
        }

        for (pageIndex, indices) in indicesByPage {
            let maximumX = maximumAbsoluteCoordinate(
                indices.map { anchors[$0].x }
            )
            let maximumY = maximumAbsoluteCoordinate(
                indices.map { anchors[$0].y }
            )
            let pageUsesPixels = max(maximumX, maximumY) > 1_000
            let pixelSize = pagePixelSizes[pageIndex]
            let xScale = coordinateScale(
                maximum: maximumX,
                pixelExtent: pixelSize.map { Double($0.width) },
                pageUsesPixels: pageUsesPixels
            )
            let yScale = coordinateScale(
                maximum: maximumY,
                pixelExtent: pixelSize.map { Double($0.height) },
                pageUsesPixels: pageUsesPixels
            )

            for index in indices {
                let anchor = anchors[index]
                normalized[index] = normalizedStampAnchorString(
                    CGPoint(
                        x: xScale.normalize(anchor.x),
                        y: yScale.normalize(anchor.y)
                    )
                )
            }
        }

        return normalized
    }

    private static func maximumAbsoluteCoordinate(_ values: [Double]) -> Double {
        values
            .filter(\.isFinite)
            .map(abs)
            .max() ?? 0
    }

    private static func coordinateScale(
        maximum: Double,
        pixelExtent: Double?,
        pageUsesPixels: Bool
    ) -> CoordinateScale {
        if maximum <= 1 {
            return .normalized
        }
        if pageUsesPixels,
           let pixelExtent,
           pixelExtent > 0 {
            return .pixels(pixelExtent)
        }
        if maximum <= 100 {
            return .percentage
        }
        if maximum <= 1_000 {
            return .thousand
        }
        if let pixelExtent,
           pixelExtent > 0 {
            return .pixels(pixelExtent)
        }
        return .thousand
    }

    private static func normalizedModelCoordinate(_ value: Double) -> CGFloat {
        // 视觉模型偶尔会把单个坐标轴返回为 0...100 百分比。
        guard value > 1, value <= 100 else {
            return CGFloat(value)
        }
        return CGFloat(value / 100)
    }

    private static func normalizedPixelCoordinate(
        _ value: Double,
        extent: Double
    ) -> CGFloat {
        guard value > 1 else {
            return CGFloat(value)
        }
        return CGFloat(value / extent)
    }
}
