import SwiftUI

enum PDFPageSelectionGridStyle {
    case compact
    case thumbnail
    case row

    var minimumCellWidth: CGFloat {
        switch self {
        case .compact: 80
        case .thumbnail: 116
        case .row: 320
        }
    }

    var columns: [GridItem] {
        switch self {
        case .compact, .thumbnail:
            [GridItem(.adaptive(minimum: minimumCellWidth), spacing: spacing)]
        case .row:
            [GridItem(.flexible(), spacing: spacing)]
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: 10
        case .thumbnail: 14
        case .row: 8
        }
    }

    var bottomPadding: CGFloat {
        switch self {
        case .compact: 64
        case .thumbnail, .row: 0
        }
    }
}

struct PDFPageSelectionSupplement {
    let title: String
    let systemImage: String
}
