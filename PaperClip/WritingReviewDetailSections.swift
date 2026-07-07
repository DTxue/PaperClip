import SwiftUI

extension WritingReviewDetailView {
    func header(_ result: AIWritingReviewResult) -> some View {
        HStack {
            Label(review.language.title, systemImage: review.language.systemImage)
            Spacer()
            if !result.scoreText.isEmpty {
                Text(result.scoreText)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.green)
            }
        }
        .font(.headline)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    func textSection(_ title: String, _ text: String) -> some View {
        WritingReviewTextBlock(title: title, text: text)
    }

    @ViewBuilder
    func listSection(_ title: String, _ items: [String]) -> some View {
        let visibleItems = items.filter { !$0.isEmpty }
        if !visibleItems.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                ForEach(visibleItems, id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle")
                        .labelStyle(.titleAndIcon)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func adviceCards<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
