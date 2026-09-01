import SwiftUI

struct AISettingsSnapshot: Equatable {
    let apiKey: String
    let doubaoEndpointID: String
    let deepSeekAPIKey: String
}

struct SecureSettingsField: View {
    let title: String
    let systemImage: String
    let tint: Color
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 28)

            Group {
                if isVisible {
                    TextField(title, text: $text)
                } else {
                    SecureField(title, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
            }
            .accessibilityLabel(isVisible ? "隐藏 \(title)" : "显示 \(title)")
        }
    }
}
