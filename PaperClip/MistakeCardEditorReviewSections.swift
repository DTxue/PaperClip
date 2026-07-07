import SwiftUI

extension MistakeCardEditorView {
    var reviewSection: some View {
        Section("复习信息") {
            HStack(spacing: 8) {
                Picker("错误原因", selection: $draftErrorReason) {
                    ForEach(ErrorReason.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)

                Divider().frame(height: 22)

                Picker("掌握状态", selection: $draftStatus) {
                    ForEach(MasteryStatus.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)

                if draftStatus != MasteryStatus.mastered.rawValue {
                    Button("升一级") {
                        draftStatus = MasteryStatus.nextLevel(after: draftStatus).rawValue
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.green)
                }
            }

            TextField("备注", text: $draftNote, axis: .vertical)
                .lineLimit(2...6)
        }
    }

    var printSizeSection: some View {
        Section("打印尺寸") {
            LabeledContent("原始比例", value: String(format: "%.2f : 1", card.aspectRatio))
            HStack {
                Text("打印宽度")
                Slider(value: $draftPrintWidthMM, in: 40...190, step: 1)
                Text("\(Int(draftPrintWidthMM)) mm")
                    .monospacedDigit()
                    .frame(width: 66, alignment: .trailing)
            }
            LabeledContent(
                "打印高度",
                value: "\(Int(draftPrintWidthMM / max(card.aspectRatio, 0.01))) mm"
            )
        }
    }

    @ViewBuilder
    func relatedMistakesSection(_ currentDraftTags: [String]) -> some View {
        let relatedItems = RelatedMistakeMatcher.topMatches(
            candidates: relatedCandidateCards,
            currentCardID: card.id,
            tags: currentDraftTags
        )

        if !relatedItems.isEmpty {
            Section {
                ForEach(relatedItems) { item in
                    RelatedMistakeRow(item: item)
                }
            } header: {
                Label("相关错题", systemImage: "link")
            } footer: {
                Text("与本题存在共同知识点。")
            }
        }
    }
}
