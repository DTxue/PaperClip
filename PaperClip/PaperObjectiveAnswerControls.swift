import SwiftUI

struct PaperMultipleChoiceOptions: View {
    let options: [String]
    @Binding var selectedAnswer: String

    private var selectedOptionLabels: Set<String> {
        PaperObjectiveAnswerSelection.labels(in: selectedAnswer)
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Toggle(
                    option,
                    isOn: Binding(
                        get: { selectedOptionLabels.contains(option) },
                        set: { update(option, isSelected: $0) }
                    )
                )
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .accessibilityLabel("选项 \(option)")
            }
        }
    }

    private func update(_ option: String, isSelected: Bool) {
        var labels = selectedOptionLabels
        if isSelected {
            labels.insert(option)
        } else {
            labels.remove(option)
        }
        selectedAnswer = PaperObjectiveAnswerSelection.answer(from: labels, orderedBy: options)
    }
}

struct PaperSingleChoicePicker: View {
    let index: Int
    let options: [String]
    @Binding var selectedAnswer: String

    var body: some View {
        Picker("答案", selection: $selectedAnswer) {
            Text("未选").tag("")
            ForEach(options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("第 \(index) 题答案")
    }
}
