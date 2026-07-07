import SwiftUI

struct VocabularyTileFlowLayout: Layout {
    var hSpacing: CGFloat = 8
    var vSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = makeRows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        guard !rows.isEmpty else { return .zero }
        let height = rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }.reduce(0, +) + CGFloat(rows.count - 1) * vSpacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = makeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y + (rowHeight - size.height) / 2), proposal: .unspecified)
                x += size.width + hSpacing
            }
            y += rowHeight + vSpacing
        }
    }

    private func makeRows(maxWidth: CGFloat, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        for subview in subviews {
            let width = subview.sizeThatFits(.unspecified).width
            if !rows[rows.endIndex - 1].isEmpty, rowWidth + hSpacing + width > maxWidth {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.endIndex - 1].append(subview)
            rowWidth += (rows[rows.endIndex - 1].count > 1 ? hSpacing : 0) + width
        }
        return rows.filter { !$0.isEmpty }
    }
}

extension View {
    func vocabularyTileStyle(placed: Bool) -> some View {
        self
            .font(.body)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(placed ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            .foregroundStyle(placed ? Color.accentColor : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        placed ? Color.accentColor.opacity(0.5) : Color(.separator).opacity(0.6),
                        lineWidth: 1.5
                    )
            }
    }
}
