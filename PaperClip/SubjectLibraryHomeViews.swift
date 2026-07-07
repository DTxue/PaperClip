import SwiftUI

struct SubjectLibraryDashboard: View {
    let snapshot: SubjectLibrarySnapshot

    var body: some View {
        let summary = snapshot.masterySummary
        VStack(alignment: .leading, spacing: 16) {
            Text("学习概况")
                .font(.title2.bold())
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 14)],
                spacing: 14
            ) {
                DashTile(value: "\(summary.total)", label: "总错题", icon: "rectangle.stack.fill", color: .accentColor)
                DashTile(value: "\(summary.unmastered)", label: "待攻克", icon: "xmark.circle.fill", color: .red)
                DashTile(value: "\(summary.masteredPercent)%", label: "掌握率", icon: "checkmark.seal.fill", color: .green)
                DashTile(value: "+\(snapshot.todayCount)", label: "今日新增", icon: "plus.circle.fill", color: .orange)
            }
        }
    }
}

struct SubjectLibraryCard: View {
    let title: String
    let icon: String
    let paperCount: Int
    let mistakeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.accentColor)
                .frame(width: 52, height: 52)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))

            Text(title)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(paperCount == 0 ? "暂无试卷" : "\(paperCount) 份试卷")
                if paperCount > 0 && mistakeCount > 0 {
                    Text("·")
                }
                if mistakeCount > 0 {
                    Text("\(mistakeCount) 道错题")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.quaternary) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(paperCount)份试卷，\(mistakeCount)道错题")
        .accessibilityHint("查看该学科题库")
    }
}

private struct DashTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }
}
