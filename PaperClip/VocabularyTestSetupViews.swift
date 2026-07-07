import SwiftUI

extension VocabularyTestView {
    func setupView(_ snapshot: VocabularyTestViewSnapshot) -> some View {
        let minimumQuestionCount = VocabularyTestQuestionCount.minimum(
            maximumQuestionCount: snapshot.maximumQuestionCount
        )
        let resolvedQuestionCount = VocabularyTestQuestionCount.clamped(
            questionCount,
            maximumQuestionCount: snapshot.maximumQuestionCount
        )

        return Form {
            Section("题量") {
                LabeledContent("题目数量") {
                    Text("\(resolvedQuestionCount) 题")
                        .monospacedDigit()
                }

                if VocabularyTestQuestionCount.allowsSlider(
                    maximumQuestionCount: snapshot.maximumQuestionCount
                ) {
                    Slider(
                        value: questionCountSliderValue(maximumQuestionCount: snapshot.maximumQuestionCount),
                        in: Double(minimumQuestionCount)...Double(snapshot.maximumQuestionCount),
                        step: 1
                    )
                    .disabled(snapshot.deckCards.isEmpty)
                    .accessibilityLabel("题目数量")
                    .accessibilityValue("\(resolvedQuestionCount) 题")
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button {
                        startTest()
                    } label: {
                        Label("开始测验", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .disabled(snapshot.deckCards.isEmpty)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } footer: {
                Text("使用 Apple Pencil 手写英文答案，完成后由 AI 统一批改。题量至少为词集总数的 60%。")
            }
        }
        .onAppear {
            questionCount = VocabularyTestQuestionCount.clamped(
                questionCount,
                maximumQuestionCount: snapshot.maximumQuestionCount
            )
        }
        .onChange(of: snapshot.deckCards.count) {
            questionCount = VocabularyTestQuestionCount.clamped(
                questionCount,
                maximumQuestionCount: snapshot.maximumQuestionCount
            )
        }
    }
}
