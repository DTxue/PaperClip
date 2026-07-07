import SwiftUI
import UIKit

struct PDFPageSelectionGrid: View {
    let pageCount: Int
    @Binding var selectedIndices: Set<Int>
    var style: PDFPageSelectionGridStyle = .compact
    var maxSelectionCount: Int?
    var thumbnail: (Int) -> UIImage? = { _ in nil }
    var supplement: (Int) -> PDFPageSelectionSupplement? = { _ in nil }
    var onPageAppear: (Int) async -> Void = { _ in }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: style.columns,
                spacing: style.spacing
            ) {
                ForEach(0..<pageCount, id: \.self) { index in
                    PDFPageSelectionCell(
                        index: index,
                        isSelected: selectedIndices.contains(index),
                        isEnabled: canToggle(index),
                        style: style,
                        thumbnail: thumbnail(index),
                        supplement: supplement(index)
                    ) {
                        toggleSelection(at: index)
                    }
                    .task {
                        await onPageAppear(index)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, style.bottomPadding)
        }
    }

    private func toggleSelection(at index: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedIndices = PDFPageExportSelectionSupport.toggledPageSelection(
                index: index,
                selectedIndices: selectedIndices,
                maxSelectionCount: maxSelectionCount
            )
        }
    }

    private func canToggle(_ index: Int) -> Bool {
        PDFPageExportSelectionSupport.canTogglePage(
            index: index,
            selectedIndices: selectedIndices,
            maxSelectionCount: maxSelectionCount
        )
    }
}
