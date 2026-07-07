import SwiftUI

struct PaperAnswerAreaSection<Content: View, Actions: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let actions: Actions
    @ViewBuilder let content: Content

    init(
        _ title: String,
        systemImage: String,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.actions = actions()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                actions
            }

            content
        }
        .padding(.top, 4)
    }
}

extension PaperAnswerAreaSection where Actions == EmptyView {
    init(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title,
            systemImage: systemImage,
            actions: EmptyView.init,
            content: content
        )
    }
}

struct PaperAnswerIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
