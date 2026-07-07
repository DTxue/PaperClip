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

struct ConnectionTestButton: View {
    let title: String
    let systemImage: String
    let isTesting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isTesting {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在测试…")
                } else {
                    Label(title, systemImage: systemImage)
                }
                Spacer()
            }
        }
    }
}
