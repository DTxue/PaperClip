import SwiftUI

extension AIAnalysisView {
    @ViewBuilder
    var rightPanel: some View {
        Group {
            switch phase {
            case .review:
                AIAnalysisEmptyState()
            case .solving:
                AISolvingProgressView(model: selectedModel)
            case .result:
                if let recognition, let solution {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Label(
                                "由 \(selectedModel.title) 完成解析",
                                systemImage: selectedModel.systemImage
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                            AnalysisDocumentView(
                                analysis: AIQuestionAnalysis(
                                    recognition: recognition,
                                    confirmedQuestion: confirmedQuestion,
                                    solution: solution
                                )
                            )
                        }
                        .padding()
                    }
                }
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
    }

    func modelButton(
        _ model: AIAnswerModel,
        isEnabled: Bool
    ) -> some View {
        AIModelSelectionButton(
            model: model,
            phase: phase,
            selectedModel: selectedModel,
            isEnabled: isEnabled
        ) {
            selectedModel = model
            startSolving(using: model)
        }
    }

    var failureView: some View {
        AIAnalysisFailureView(
            message: failureMessage,
            canReturnToRecognition: recognition != nil
        ) {
            retryFailedOperation()
        } returnToRecognition: {
            phase = .review
        }
    }
}
