import SwiftUI

struct VocabularyStudySessionRowView: View {
    let session: VocabularyStudySessionRowData

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(session.kind, systemImage: systemImage)
                        .font(.headline)
                    Spacer()
                    Text("错误率 \(VocabularyStudySessionFormat.percent(session.errorRate))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(session.errorRate > 0.2 ? Color.orange : Color.green)
                }

                HStack {
                    Text(session.endedAt, format: .dateTime.month().day().hour().minute())
                    Text("·")
                    Text(VocabularyStudySessionFormat.duration(session.duration))
                    Text("·")
                    Text("\(session.correctCount) / \(session.totalCount)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private var systemImage: String {
        switch session.kind {
        case "闪卡": "rectangle.on.rectangle"
        case "学习": "brain.head.profile"
        case "测验": "checklist"
        default: "chart.bar"
        }
    }
}
