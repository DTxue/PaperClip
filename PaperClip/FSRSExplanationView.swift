import SwiftUI

struct FSRSExplanationView: View {
    private let projectURL = URL(string: "https://github.com/open-spaced-repetition")

    var body: some View {
        Form {
            Section {
                LabeledContent("当前算法", value: "FSRS-6")
                LabeledContent("参数数量", value: "21")
                LabeledContent("默认目标保持率", value: "90%")
                LabeledContent("当前使用范围", value: "单词功能")
            } header: {
                Text("当前配置")
            } footer: {
                Text("FSRS-6 目前用于 ENG 词集复习。每个词集可以单独调整每日新词数量和目标保持率。")
            }

            Section {
                Text("FSRS（Free Spaced Repetition Scheduler）根据每次复习结果，估算记忆的难度、稳定度和当前可提取率，再安排下一次复习时间。")
                Text("目标是在尽量减少复习次数的同时，把预计记住的概率维持在词集设定的目标保持率附近。")
            } header: {
                Text("工作原理")
            }

            Section {
                itemRows(FSRSExplanationContent.stateItems)
            } header: {
                Text("核心状态")
            }

            Section {
                itemRows(FSRSExplanationContent.ratingItems)
            } header: {
                Text("四级评分")
            } footer: {
                Text("“困难”仍然表示答对。只要没有独立回忆出来，就应选择“忘记”，否则算法会高估记忆强度。")
            }

            Section {
                ForEach(FSRSExplanationContent.implementationItems) { item in
                    Label(item.title, systemImage: item.systemImage)
                }
            } header: {
                Text("PaperClip 的实现")
            } footer: {
                Text("所有调度计算和复习记录均保存在设备本地，不需要联网。")
            }

            Section {
                Text("FSRS 预测的是同一记忆内容能否被再次提取，并不直接衡量理解深度或迁移能力。评分应基于真实回忆结果，不要因为熟悉卡面而选择较高等级。")
                if let projectURL {
                    Link("查看 FSRS 开源项目", destination: projectURL)
                }
            } header: {
                Text("使用说明")
            }
        }
        .navigationTitle("FSRS-6")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func itemRows(_ items: [FSRSExplanationItem]) -> some View {
        ForEach(items) { item in
            infoRow(item)
        }
    }

    private func infoRow(_ item: FSRSExplanationItem) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                Text(item.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundStyle(item.color)
        }
    }
}
