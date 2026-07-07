import SwiftUI

struct DiaryReadSection: View {
    let icon: String
    let color: Color
    let title: String
    let original: String
    let ai: String?

    init(
        icon: String,
        color: Color,
        title: String,
        original: String,
        ai: String? = nil
    ) {
        self.icon = icon
        self.color = color
        self.title = title
        self.original = original
        self.ai = ai
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            Text(original)
                .font(.body)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))

            if let ai, !ai.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI 整理")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(ai)
                        .font(.body)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.2))
                }
            }
        }
    }
}
