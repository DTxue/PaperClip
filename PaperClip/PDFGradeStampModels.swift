import CoreGraphics
import Foundation

struct PDFGradeStamp: Identifiable, Equatable {
    let id: UUID
    let pageIndex: Int
    let isCorrect: Bool
    let normalizedAnchor: CGPoint
    let confidence: Double
}

struct PDFGradeStampIndex {
    private var stampsByPage: [Int: [PDFGradeStamp]] = [:]
    private var indexedStamps: [PDFGradeStamp] = []

    mutating func updateIfNeeded(_ stamps: [PDFGradeStamp]) {
        guard indexedStamps != stamps else { return }

        var index: [Int: [PDFGradeStamp]] = [:]
        index.reserveCapacity(stamps.count)
        for stamp in stamps {
            index[stamp.pageIndex, default: []].append(stamp)
        }
        stampsByPage = index
        indexedStamps = stamps
    }

    func stamps(on pageIndices: Set<Int>) -> [PDFGradeStamp] {
        var visibleStamps: [PDFGradeStamp] = []
        for pageIndex in pageIndices {
            visibleStamps.append(contentsOf: stampsByPage[pageIndex] ?? [])
        }
        return visibleStamps
    }

    mutating func removeAll() {
        stampsByPage.removeAll()
        indexedStamps.removeAll()
    }
}
