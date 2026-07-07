import SwiftUI

struct VocabularyDeckSettingsSnapshot {
    let cards: [VocabularyCard]
    let freshCacheCount: Int

    init(cards: [VocabularyCard], freshCacheCount: Int) {
        self.cards = cards
        self.freshCacheCount = freshCacheCount
    }
}

struct VocabularyDeckDeleteRequest: Identifiable, Sendable {
    let id: UUID
    let title: String
}

struct VocabularyDeckSchedulingSection: View {
    @Binding var dailyNewLimit: Int
    @Binding var desiredRetention: Double

    var body: some View {
        Section {
            LabeledContent("调度算法", value: "FSRS-6 · 21 参数")
            Stepper("每日新词：\(dailyNewLimit)", value: $dailyNewLimit, in: 1...100)
            Slider(value: $desiredRetention, in: 0.8...0.97, step: 0.01) {
                Text("目标保持率")
            } minimumValueLabel: {
                Text("80%")
            } maximumValueLabel: {
                Text("97%")
            }
            LabeledContent("目标保持率") {
                Text("\(Int((desiredRetention * 100).rounded()))%")
                    .monospacedDigit()
            }
        } header: {
            Text("记忆调度")
        } footer: {
            Text("FSRS-6 分别维护正向和反向记忆的难度、稳定度与可提取率，并使用 1/10 分钟学习步进、10 分钟重学步进和间隔扰动。保持率越高，复习越频繁。")
        }
    }
}

struct VocabularyDeckDangerSection: View {
    let onDelete: () -> Void

    var body: some View {
        Section {
            Button(role: .destructive, action: onDelete) {
                Label("删除词集", systemImage: "trash")
            }
        } header: {
            Text("危险操作")
        } footer: {
            Text("删除词集会同时删除其中的单词、复习记录和手写记录。")
        }
    }
}
