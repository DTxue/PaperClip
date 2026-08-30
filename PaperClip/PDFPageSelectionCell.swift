import SwiftUI
import UIKit

struct PDFPageSelectionCell: View {
    let index: Int
    let isSelected: Bool
    let isEnabled: Bool
    let style: PDFPageSelectionGridStyle
    let thumbnail: UIImage?
    let supplement: PDFPageSelectionSupplement?
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            switch style {
            case .compact:
                compactContent
            case .thumbnail:
                thumbnailContent
            case .row:
                rowContent
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var compactContent: some View {
        VStack(spacing: 4) {
            PDFPageSelectionIcon(isSelected: isSelected)
                .font(.system(size: 18))
            PDFPageSelectionTitle(index: index, isSelected: isSelected)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .selectionSurface(
            isSelected: isSelected,
            cornerRadius: 10,
            selectedOpacity: 0.15,
            defaultFill: Color(uiColor: .systemGray6),
            defaultStroke: Color(uiColor: .systemGray4)
        )
        .frame(height: 72)
    }

    private var thumbnailContent: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                PDFPageThumbnailView(thumbnail: thumbnail)

                PDFPageSelectionIcon(isSelected: isSelected)
                    .font(.title3)
                    .padding(6)
            }

            PDFPageSelectionTitle(index: index, isSelected: isSelected)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let supplement {
                Label(supplement.title, systemImage: supplement.systemImage)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .selectionSurface(
            isSelected: isSelected,
            cornerRadius: 8,
            selectedOpacity: 0.12
        )
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            PDFPageSelectionIcon(isSelected: isSelected)
                .font(.title3)

            PDFPageSelectionTitle(index: index, isSelected: isSelected)

            Spacer()

            if let supplement {
                Label(supplement.title, systemImage: supplement.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.10) : Color(uiColor: .secondarySystemBackground))
        )
    }

    private var accessibilityLabel: String {
        PDFPageIndexDisplay.selectionAccessibilityLabel(zeroBasedIndex: index, isSelected: isSelected, supplementTitle: supplement?.title)
    }
}
