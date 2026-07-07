import SwiftUI
import SwiftData

struct WritingReviewDetailLoader: View {
    @Environment(\.modelContext) private var modelContext
    let reviewID: UUID
    var onReReview: (() -> Void)? = nil
    @State private var review: WritingReview?
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let review {
                WritingReviewDetailView(review: review, onReReview: onReReview)
            } else {
                ContentUnavailableView(
                    "无法打开批阅记录",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("这条批阅记录可能已被删除。")
                )
                .navigationTitle("作文批阅")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .appAlert($alert)
        .task(id: reviewID) {
            loadReview()
        }
    }

    private func loadReview() {
        do {
            review = try modelContext.fetchWritingReview(id: reviewID)
        } catch {
            review = nil
            alert = AppAlert(title: "无法读取作文批阅", error: error)
        }
    }
}
