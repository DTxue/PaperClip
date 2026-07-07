import SwiftUI

struct AIAnalysisImagePreview: View {
    let image: UIImage
    let accessibilityLabel: String

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(accessibilityLabel)
    }
}

struct AIRecognizingProgressView: View {
    let image: UIImage
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            AIAnalysisImagePreview(image: image, accessibilityLabel: "待识别的题目图片")
                .frame(maxHeight: 220)

            ProgressView("豆包正在识别题目…")
                .controlSize(.large)

            Text("识别完成后，请先核对题目内容。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("超过 90 秒会自动停止。")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button("取消", role: .cancel, action: onCancel)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AISolvingProgressView: View {
    let model: AIAnswerModel

    var body: some View {
        VStack(spacing: 16) {
            ProgressView("\(model.shortTitle)正在解析题目…")
                .controlSize(.large)

            Text("正在生成思路、步骤、答案和易错点。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AIAnalysisEmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("选择解析模型", systemImage: "cpu")
        } description: {
            Text("在左侧选择模型后开始解析")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
