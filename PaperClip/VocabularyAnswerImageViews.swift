import SwiftUI

struct VocabularyAnswerThumbnail: View {
    let image: UIImage
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("查看答题图片")
    }
}

struct VocabularyAnswerImagePreview: View {
    let image: UIImage
    let close: () -> Void

    var body: some View {
        NavigationStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
                .navigationTitle("手写内容")
                .navigationBarTitleDisplayMode(.inline)
                .doneToolbar(action: close)
        }
    }
}
