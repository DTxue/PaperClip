import SwiftUI

extension PDFExamPageSelectionView {
    var selectionSnapshot: PDFPageExportSelectionSnapshot {
        PDFPageExportSelectionSnapshot(
            pageCount: pageCount,
            selectedIndices: selectedIndices,
            isRendering: false
        )
    }

    @MainActor
    func generateThumbnailIfNeeded(for index: Int) async {
        guard let pageCount,
              (0..<pageCount).contains(index),
              pageThumbnails[index] == nil,
              !renderingThumbnailIndices.contains(index)
        else { return }

        renderingThumbnailIndices.insert(index)
        defer { renderingThumbnailIndices.remove(index) }

        let documentURL = documentURL
        let image = await PDFPageDocumentReader.pageThumbnail(
            at: documentURL,
            index: index,
            size: CGSize(width: 180, height: 240)
        )
        guard !Task.isCancelled,
              self.pageCount == pageCount,
              index < pageCount
        else { return }
        pageThumbnails[index] = image
    }

    @MainActor
    func loadPageCount() async {
        pageCount = nil
        pageThumbnails = [:]
        renderingThumbnailIndices = []
        selectedIndices = decision.target.pageIndex.map { Set([$0]) } ?? []

        let documentURL = documentURL
        let loadedPageCount = await PDFPageDocumentReader.pageCount(at: documentURL)
        guard !Task.isCancelled else { return }
        pageCount = loadedPageCount
    }
}
