import SwiftUI

struct MistakeStatusTypeFilters: View {
    @Binding var selectedStatus: String
    @Binding var selectedQuestionType: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                statusPicker
                questionTypePicker
            }

            VStack(alignment: .leading, spacing: 12) {
                statusPicker
                questionTypePicker
            }
        }
    }

    private var statusPicker: some View {
        Picker("状态", selection: $selectedStatus) {
            Text("全部状态").tag("")
            ForEach(MasteryStatus.allCases) { status in
                Text(status.rawValue).tag(status.rawValue)
            }
        }
        .frame(maxWidth: 240)
    }

    private var questionTypePicker: some View {
        Picker("题型", selection: $selectedQuestionType) {
            Text("全部题型").tag("")
            ForEach(QuestionType.allCases) { type in
                Label(type.rawValue, systemImage: type.systemImage)
                    .tag(type.rawValue)
            }
        }
        .frame(maxWidth: 240)
    }
}
