import SwiftUI

struct MistakeFilterHeader: View {
    let title: String
    let systemImage: String
    let clearTitle: String
    let clearTint: Color
    let isClearVisible: Bool
    let clear: () -> Void

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if isClearVisible {
                Spacer()
                Button(clearTitle, action: clear)
                    .font(.caption)
                    .foregroundStyle(clearTint)
            }
        }
    }
}
