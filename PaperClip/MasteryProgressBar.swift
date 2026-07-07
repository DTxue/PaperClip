import SwiftUI

struct MasteryProgressBar: View {
    let summary: MasteryStatusSummary

    var body: some View {
        let currentSummary = summary
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                let w = proxy.size.width
                HStack(spacing: 0) {
                    ForEach(currentSummary.segments.reversed(), id: \.status) { segment in
                        if segment.count > 0 {
                            segment.status.progressBarColor
                                .frame(width: w * CGFloat(segment.ratio))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .frame(height: 10)
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    ForEach(currentSummary.segments.reversed(), id: \.status) { segment in
                        statLabel(segment)
                        Spacer()
                    }
                    masteryPercentage(summary: currentSummary)
                }

                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    GridRow {
                        statLabel(currentSummary.segments[2])
                        statLabel(currentSummary.segments[1])
                    }
                    GridRow {
                        statLabel(currentSummary.segments[0])
                        masteryPercentage(summary: currentSummary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("掌握进度：\(currentSummary.masteredPercent)%已掌握，共 \(currentSummary.total) 张错题")
    }

    private func statLabel(_ segment: MasteryStatusSegment) -> some View {
        Label {
            Text("\(segment.count) \(segment.label)")
        } icon: {
            Image(systemName: segment.systemImage)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(segment.status.progressTextColor)
    }

    private func masteryPercentage(summary: MasteryStatusSummary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(summary.masteredPercent)%")
                .font(.title3.bold().monospacedDigit())
            Text("掌握")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private extension MasteryStatus {
    var progressTextColor: Color {
        switch self {
        case .unmastered: .red
        case .review: .orange
        case .mastered: .green
        }
    }

    var progressBarColor: Color {
        switch self {
        case .unmastered: .red.opacity(0.65)
        case .review: .orange
        case .mastered: .green
        }
    }
}
