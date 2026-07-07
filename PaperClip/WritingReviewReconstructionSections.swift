import SwiftUI

extension WritingReviewDetailView {
    @ViewBuilder
    func revisedStructurePlanSection(_ items: [AIWritingReviewResult.RevisedStructurePlan]?) -> some View {
        if let items, !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("结构重组计划表")
                    .font(.headline)
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.part)
                            .font(.subheadline.weight(.semibold))
                        Text(item.content)
                        Text("详略建议：\(item.lengthAdvice) ｜ 全文作用：\(item.purpose)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    @ViewBuilder
    func studentRevisionTasksSection(_ items: [AIWritingReviewResult.StudentRevisionTask]?) -> some View {
        if let items, !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("课后二次修改任务")
                    .font(.headline)
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.task)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                        Text("修改范围：\(item.targetParagraph)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("操作指引：\(item.instruction)")
                        Text("修改示例：\(item.example)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("提升能力：\(item.purpose)")
                            .font(.footnote)
                            .foregroundStyle(.purple)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
