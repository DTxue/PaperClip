import SwiftUI

struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status {
        case MasteryStatus.mastered.rawValue: .green
        case MasteryStatus.review.rawValue: .orange
        default: .red
        }
    }

    var body: some View {
        Text(status)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct EditableMistakeTag: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Text(title).lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill").imageScale(.small)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("移除标签 \(title)")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Color.accentColor)
        .padding(.leading, 11)
        .padding(.trailing, 7)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
        .overlay { Capsule().stroke(Color.accentColor.opacity(0.25), lineWidth: 1) }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .contain)
    }
}
