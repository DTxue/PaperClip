import SwiftUI

struct AIAnalysisView: View {
    @Environment(\.dismiss) var dismiss

    let image: UIImage

    @State var phase: Phase = .recognizing
    @State var recognition: AIQuestionRecognition?
    @State var confirmedQuestion = ""
    @State var solution: AIQuestionSolution?
    @State var selectedModel: AIAnswerModel = .doubao
    @State var failureMessage = ""
    @State var failedOperation: Operation = .recognition
    @State var isEditingQuestion = false
    @State var operationTaskSlot = ViewTaskSlot()

    enum Phase {
        case recognizing
        case review
        case solving
        case result
        case failure
    }

    enum Operation {
        case recognition
        case solution
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .recognizing:
                    recognizingView
                case .review, .solving, .result:
                    splitView
                case .failure:
                    failureView
                }
            }
            .navigationTitle(phase == .recognizing ? "识别题目" : "AI 解析")
            .navigationBarTitleDisplayMode(.inline)
            .doneToolbar { dismiss() }
        }
        .task {
            guard recognition == nil else { return }
            startRecognition()
        }
        .onDisappear {
            cancelOperation()
        }
        .sheet(isPresented: $isEditingQuestion) {
            NavigationStack {
                Form {
                    Section {
                        TextEditor(text: $confirmedQuestion)
                            .font(.body)
                            .frame(minHeight: 300)
                    } header: {
                        Text("题目文本")
                    } footer: {
                        Text("公式请保留 LaTeX 标记，例如 $a^2$。")
                    }
                }
                .navigationTitle("编辑识别内容")
                .navigationBarTitleDisplayMode(.inline)
                .editSheetToolbar(
                    confirmTitle: "完成",
                    isConfirmDisabled: confirmedQuestion
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty,
                    onCancel: {
                        if let recognition {
                            confirmedQuestion = recognition.recognizedQuestion
                        }
                        isEditingQuestion = false
                    },
                    onConfirm: {
                        isEditingQuestion = false
                    }
                )
            }
        }
        .presentationSizing(.page)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

}
