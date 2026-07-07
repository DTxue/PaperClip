import Foundation

enum PDFExamActivationDefaults {
    static let isWritingEnabled = true
    static let isDrawingVisible = true
}

struct LatestLayersByPage<Layer> {
    let latest: [Int: Layer]
    let duplicates: [Layer]
}

func latestLayersByPage<Layer>(
    _ layers: [Layer],
    pageIndex: (Layer) -> Int,
    updatedAt: (Layer) -> Date
) -> LatestLayersByPage<Layer> {
    var latest: [Int: Layer] = [:]
    var duplicates: [Layer] = []

    for layer in layers {
        let page = pageIndex(layer)
        guard let existing = latest[page] else {
            latest[page] = layer
            continue
        }

        if updatedAt(layer) > updatedAt(existing) {
            duplicates.append(existing)
            latest[page] = layer
        } else {
            duplicates.append(layer)
        }
    }

    return LatestLayersByPage(latest: latest, duplicates: duplicates)
}

struct PDFAnswerLayerWritePlan {
    let changedDrawingDataByPage: [Int: Data]
    let completedPageIndices: Set<Int>

    var hasChanges: Bool {
        !changedDrawingDataByPage.isEmpty
    }

    static func make(
        currentDrawingDataByPage: [Int: Data],
        pendingDrawingDataByPage: [Int: Data]
    ) -> PDFAnswerLayerWritePlan {
        let changed = pendingDrawingDataByPage.filter { pageIndex, drawingData in
            currentDrawingDataByPage[pageIndex] != drawingData
        }
        return PDFAnswerLayerWritePlan(
            changedDrawingDataByPage: changed,
            completedPageIndices: Set(pendingDrawingDataByPage.keys)
        )
    }
}
