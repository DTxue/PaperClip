import SwiftUI

struct ReviewPageSelectionView: View {
    let pageCount: Int
    @Binding var selectedPages: Set<Int>
    let answeredPageSet: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("已选择 \(selectedPages.count) / \(ReviewSubmissionRenderer.maximumPageCount) 页")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            PDFPageSelectionGrid(
                pageCount: pageCount,
                selectedIndices: $selectedPages,
                style: .row,
                maxSelectionCount: ReviewSubmissionRenderer.maximumPageCount,
                supplement: { pageIndex in
                    answeredPageSet.contains(pageIndex)
                        ? PDFPageSelectionSupplement(title: "有手写答案", systemImage: "pencil")
                        : nil
                }
            )

            Text("仅合成原 PDF 页面和当前练习的正式手写答案，不包含草稿板、错题框或其他界面元素。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .overlay {
            if pageCount == 0 {
                ContentUnavailableView(
                    "无法读取页面",
                    systemImage: "doc.questionmark",
                    description: Text("当前 PDF 没有可提交的页面。")
                )
            }
        }
    }
}

struct ReviewLongImagePreview: View {
    let image: UIImage
    var accessibilityLabel = "待分享的批阅长图"

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 900)
                .background(.white)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
                .padding(20)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .accessibilityLabel(accessibilityLabel)
    }
}
