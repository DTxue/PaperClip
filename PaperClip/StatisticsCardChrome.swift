import SwiftUI

struct StatCard<Content: View>: View {
    @Environment(\.paperClipAppPalette) private var palette

    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.secondaryTextColor)
            content
        }
        .padding(18)
        .background(palette.panelBackgroundColor, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(palette.borderColor.opacity(0.7))
        }
    }
}

struct MasteryDistributionBar: View {
    let summary: MasteryStatusSummary

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            HStack(spacing: 2) {
                ForEach(summary.segments, id: \.status) { segment in
                    if segment.count > 0 {
                        segment.status.statisticsBarColor
                            .frame(width: width * CGFloat(segment.ratio))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .frame(height: 12)
    }
}

struct StatisticsCardEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .frame(maxWidth: .infinity, minHeight: 120)
    }
}

extension MasteryStatus {
    var statisticsTextColor: Color {
        switch self {
        case .unmastered: .red
        case .review: .orange
        case .mastered: .green
        }
    }

    var statisticsBarColor: Color {
        switch self {
        case .unmastered: .red.opacity(0.7)
        case .review: .orange
        case .mastered: .green
        }
    }
}
