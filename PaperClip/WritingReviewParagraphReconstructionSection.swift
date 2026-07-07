import SwiftUI

extension WritingReviewDetailView {
    @ViewBuilder
    func paragraphReconstructionSection(_ items: [AIWritingReviewResult.ParagraphReconstruction]?) -> some View {
        if let items, !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("段落高分重构")
                    .font(.headline)
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.section)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.blue)
                        Text("对应原文段：\(item.relatedOriginalParagraphs)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("真正内容：\(item.extractedContent)")
                        Text("全文作用：\(item.writingFunction)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("目前问题：\(item.currentProblem)")
                            .foregroundStyle(.red)
                        Text("重构策略：\(item.rewriteStrategy)")
                        Text("剪裁：保留 [\(item.keepMaterial)] ｜ 压缩 [\(item.compressOrMergeMaterial)] ｜ 扩写 [\(item.expandMaterial)]")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("高分重构示范")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                            Text(item.highScoreRewrite)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        }

                        Text("重构解析：\(item.whyThisRewriteIsBetter)")
                        Text("可模仿写法：\(item.studentCanLearn)")
                            .font(.subheadline.weight(.semibold))
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
