import SwiftUI

extension WritingReviewDetailView {
    @ViewBuilder
    func blueprintSection(_ item: AIWritingReviewResult.WritingBlueprint?) -> some View {
        if let item {
            VStack(alignment: .leading, spacing: 10) {
                Text("作文重构蓝图")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    textSection("真正应完成的写作任务", item.realWritingTask)
                    textSection("不可只停留在", item.notJustAbout)
                    textSection("更高级思想内核", item.deeperMeaning)
                    if !item.emotionalArc.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("情感起伏变化曲线")
                                .font(.subheadline.weight(.semibold))
                            ForEach(0..<item.emotionalArc.count, id: \.self) { idx in
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text(item.emotionalArc[idx])
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最该详写的核心场景")
                            .font(.subheadline.weight(.semibold))
                        Text(item.coreSceneToBuild.scene)
                        Text("场景作用：\(item.coreSceneToBuild.whyThisSceneMatters)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if !item.coreSceneToBuild.detailsToAdd.isEmpty {
                            Text("可补充细节：\(item.coreSceneToBuild.detailsToAddText)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("原文材料剪裁与取舍")
                            .font(.subheadline.weight(.semibold))
                        Text("【详写】\(item.materialArrangement.shouldBeDetailed)")
                        Text("【略写】\(item.materialArrangement.shouldBeBrief)")
                        if !item.materialArrangement.shouldBeRemovedOrMerged.isEmpty {
                            Text("【删除/合并】\(item.materialArrangement.shouldBeRemovedOrMerged)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
