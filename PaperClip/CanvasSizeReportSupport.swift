import CoreGraphics

enum CanvasSizeReportSupport {
    static let defaultTolerance: CGFloat = 0.5
    static let minimumReportableDimension: CGFloat = 1

    static func reportableSize(_ size: CGSize) -> CGSize? {
        guard size.width > minimumReportableDimension,
              size.height > minimumReportableDimension
        else { return nil }
        return size
    }

    static func hasMeaningfulChange(
        from oldSizes: [Int: CGSize],
        to newSizes: [Int: CGSize],
        tolerance: CGFloat = defaultTolerance
    ) -> Bool {
        guard oldSizes.count == newSizes.count else { return true }

        for (pageIndex, newSize) in newSizes {
            guard let oldSize = oldSizes[pageIndex],
                  isClose(oldSize, to: newSize, tolerance: tolerance)
            else {
                return true
            }
        }
        return false
    }

    static func isClose(_ lhs: CGSize, to rhs: CGSize, tolerance: CGFloat = defaultTolerance) -> Bool {
        abs(lhs.width - rhs.width) <= tolerance
            && abs(lhs.height - rhs.height) <= tolerance
    }
}
