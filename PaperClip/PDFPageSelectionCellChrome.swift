import SwiftUI
import UIKit

struct PDFPageSelectionIcon: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isSelected ? Color.accentColor : Color(uiColor: .systemGray3))
    }
}

struct PDFPageSelectionTitle: View {
    let index: Int
    let isSelected: Bool

    var body: some View {
        Text(PDFPageIndexDisplay.pageTitle(forZeroBasedIndex: index))
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
    }
}

struct PDFPageThumbnailView: View {
    let thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .background(.white)
            } else {
                Rectangle()
                    .fill(.quaternary)
            }
        }
        .frame(height: 142)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

extension View {
    func selectionSurface(
        isSelected: Bool,
        cornerRadius: CGFloat = 8,
        selectedOpacity: Double,
        defaultFill: Color = Color(uiColor: .secondarySystemBackground),
        defaultStroke: Color = Color(uiColor: .separator)
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isSelected ? Color.accentColor.opacity(selectedOpacity) : defaultFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isSelected ? Color.accentColor : defaultStroke, lineWidth: isSelected ? 2 : 0.5)
        }
    }
}
