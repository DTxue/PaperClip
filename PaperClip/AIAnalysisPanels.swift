import SwiftUI

extension AIAnalysisView {
    var recognizingView: some View {
        AIRecognizingProgressView(image: image) { dismiss() }
    }

    var splitView: some View {
        VStack(spacing: 0) {
            AIAnalysisImagePreview(image: image, accessibilityLabel: "已识别的题目图片")
                .frame(maxHeight: 160)
                .padding(.horizontal)
                .padding(.vertical, 12)

            Divider()

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    leftPanel
                        .frame(minWidth: 360)
                    Divider()
                    rightPanel
                        .frame(minWidth: 360)
                }

                VStack(spacing: 0) {
                    leftPanel
                    Divider()
                    rightPanel
                        .frame(minHeight: 420)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    var leftPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let recognition {
                    AIRecognitionSummaryView(recognition: recognition)

                    RecognitionPreviewView(question: confirmedQuestion)

                    HStack {
                        Button {
                            isEditingQuestion = true
                        } label: {
                            Label("编辑识别内容", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button {
                            startRecognition()
                        } label: {
                            Label("重新识别", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Label("解析模型", systemImage: "cpu")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        modelButton(.doubao, isEnabled: true)
                        modelButton(.deepSeek, isEnabled: AIService.isDeepSeekConfigured)
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
    }

}
