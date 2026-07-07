import SwiftUI

struct AIAnalysisFailureView: View {
    let message: String
    let canReturnToRecognition: Bool
    let retry: () -> Void
    let returnToRecognition: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("操作失败", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("重试", action: retry)
                .buttonStyle(.borderedProminent)

            if canReturnToRecognition {
                Button("返回识别结果", action: returnToRecognition)
            }
        }
    }
}
