import SwiftUI

struct VocabularyDeckDistractorConfigSection: View {
    @Binding var totalCount: Int
    @Binding var weightInflection: Int
    @Binding var weightLookalike: Int
    @Binding var weightSynonym: Int
    @Binding var weightConfused: Int
    @Binding var weightDerivation: Int

    var body: some View {
        Section {
            Stepper("干扰词数量：\(totalCount)", value: $totalCount, in: 4...12)
            DistractorWeightRow(label: "词形变体", description: "ran / runs / running", value: $weightInflection)
            DistractorWeightRow(label: "形近词", description: "拼写相似但不同的单词", value: $weightLookalike)
            DistractorWeightRow(label: "近义词", description: "同类但语义不同的单词", value: $weightSynonym)
            DistractorWeightRow(label: "常见混淆词", description: "affect/effect 这类高频错误", value: $weightConfused)
            DistractorWeightRow(label: "词性变体", description: "同词根不同词性", value: $weightDerivation)
        } header: {
            Text("干扰词配置")
        } footer: {
            Text("权重 0 表示关闭该类型；1-3 按比例分配名额。实际生成数量以总数为上限，各类型按权重占比取整分配。")
        }
    }
}

struct VocabularyDeckDistractorLibrarySection: View {
    let snapshot: VocabularyDeckSettingsSnapshot
    let isGenerating: Bool
    let generatedCount: Int
    let saveError: String?
    let generateError: String?
    let onRegenerate: () -> Void

    var body: some View {
        Section {
            LabeledContent("缓存状态") {
                Text("\(snapshot.freshCacheCount) / \(snapshot.cards.count) 已生成")
                    .foregroundStyle(snapshot.freshCacheCount == snapshot.cards.count ? .green : .secondary)
            }
            if isGenerating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("正在生成 \(generatedCount) / \(snapshot.cards.count)...")
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("用 AI 重新生成干扰词库", systemImage: "sparkles", action: onRegenerate)
                    .disabled(snapshot.cards.isEmpty)
            }
            if let saveError {
                Text(saveError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            if let generateError {
                Text(generateError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("干扰词库")
        } footer: {
            Text("干扰词库为每张卡片生成易混淆的词块，用于「学习」和「测验」的拼句题型。生成后永久缓存；单词内容变更时需重新生成。")
        }
    }
}

private struct DistractorWeightRow: View {
    let label: String
    let description: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(label, selection: $value) {
                Text("关").tag(0)
                Text("1").tag(1)
                Text("2").tag(2)
                Text("3").tag(3)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 220)
        }
        .padding(.vertical, 2)
    }
}
