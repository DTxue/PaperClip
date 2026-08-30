import Foundation

enum PDFExamActivationDefaults {
    static let isWritingEnabled = true
    static let isDrawingVisible = true
}

struct PDFExamGradingActionState: Equatable {
    let isEnabled: Bool
    let title: String
    let systemImage: String

    init(
        status: ExamAttemptStatus?,
        isSubmitting: Bool,
        pageProgress: PDFExamPageProgress? = nil,
        currentPageIndex: Int? = nil,
        resumeTarget: PDFExamResumeTarget? = nil
    ) {
        isEnabled = status?.canRequestGrading == true && !isSubmitting
        if case let .retryGrading(pageIndex)? = resumeTarget {
            title = "重试第 \(pageIndex + 1) 页"
            systemImage = "arrow.clockwise.circle"
        } else if let resumeTarget,
                  status == .inProgress,
                  let pageIndex = resumeTarget.pageIndex {
            title = "提交第 \(pageIndex + 1) 页"
            systemImage = "checkmark.seal"
        } else if let pageProgress,
           let currentPageIndex,
           pageProgress.isAwaitingGrading(pageIndex: currentPageIndex) {
            title = "重试第 \(currentPageIndex + 1) 页"
            systemImage = "arrow.clockwise.circle"
        } else if let pageProgress,
           status == .inProgress,
           let pageIndex = pageProgress.nextUnsubmittedPageIndex {
            title = "提交第 \(pageIndex + 1) 页"
            systemImage = "checkmark.seal"
        } else if let pageProgress,
                  status == .submitted,
                  let pageIndex = pageProgress.pageIndices.first(where: {
                      pageProgress.submittedPageIndices.contains($0)
                          && !pageProgress.gradedPageIndices.contains($0)
                  }) {
            title = "重试第 \(pageIndex + 1) 页"
            systemImage = "arrow.clockwise.circle"
        } else {
            title = status == .submitted ? "重新批阅" : "交卷"
            systemImage = status == .submitted ? "arrow.clockwise.circle" : "checkmark.seal"
        }
    }
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
