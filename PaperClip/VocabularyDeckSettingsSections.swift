import SwiftUI

struct VocabularyDeckSettingsSnapshot {
    let cards: [VocabularyCard]
    let freshCacheCount: Int

    var englishDefinitionCount: Int {
        cards.filter { !$0.englishDefinition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var missingEnglishDefinitionCount: Int {
        cards.count - englishDefinitionCount
    }

    init(cards: [VocabularyCard], freshCacheCount: Int) {
        self.cards = cards
        self.freshCacheCount = freshCacheCount
    }
}

struct VocabularyDeckEnglishDefinitionSection: View {
    let snapshot: VocabularyDeckSettingsSnapshot
    let isGenerating: Bool
    let generatedCount: Int
    let generateError: String?
    let onGenerate: () -> Void

    var body: some View {
        Section {
            LabeledContent("英文释义") {
                Text("\(snapshot.englishDefinitionCount) / \(snapshot.cards.count) 已生成")
                    .foregroundStyle(snapshot.missingEnglishDefinitionCount == 0 ? .green : .secondary)
            }
            if isGenerating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("正在生成 \(generatedCount) / \(snapshot.missingEnglishDefinitionCount)...")
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("用 DeepSeek 生成英文释义", systemImage: "sparkles", action: onGenerate)
                    .disabled(snapshot.cards.isEmpty || snapshot.missingEnglishDefinitionCount == 0)
            }
            if let generateError {
                Text(generateError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("英文释义")
        } footer: {
            Text("只补全缺失的英文释义，不覆盖已手动编辑的内容。释义会使用简单英文，显示在「单词 → 释义」闪卡正面，帮助先按英文线索猜中文释义。")
        }
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
