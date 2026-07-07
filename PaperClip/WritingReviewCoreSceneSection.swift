import SwiftUI

extension WritingReviewDetailView {
    @ViewBuilder
    func coreSceneUpgradeSection(_ item: AIWritingReviewResult.CoreSceneUpgrade?) -> some View {
        if let item, !item.selectedScene.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("核心场景打磨示范")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.selectedScene)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.orange)
                    Text("核心作用：\(item.whySelected)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("原问题：\(item.originalProblem)")
                        .foregroundStyle(.red)

                    if !item.detailsToAdd.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("细节添加建议")
                                .font(.subheadline.weight(.semibold))
                            ForEach(0..<item.detailsToAdd.count, id: \.self) { idx in
                                Text("• [\(item.detailsToAdd[idx].detailType)] \(item.detailsToAdd[idx].specificAdvice)")
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("高分示范片段")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                        Text(item.highScoreRewrite)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                    }

                    if !item.methodBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("写法拆解")
                                .font(.subheadline.weight(.semibold))
                            ForEach(0..<item.methodBreakdown.count, id: \.self) { idx in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("[\(item.methodBreakdown[idx].method)] \(item.methodBreakdown[idx].exampleFromRewrite)")
                                        .font(.subheadline)
                                    Text("效果：\(item.methodBreakdown[idx].effect)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    if !item.studentCanImitateBy.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("可模仿写作动作")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.purple)
                            ForEach(item.studentCanImitateBy, id: \.self) { tip in
                                Text("• \(tip)")
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
