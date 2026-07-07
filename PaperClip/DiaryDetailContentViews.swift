import SwiftUI

struct DiaryEntryReadOnlyContent: View {
    let entry: DiaryEntry
    let snapshot: DiaryKnowledgeSnapshot
    let onDelete: () -> Void
    let onClearKnowledge: () -> Void
    let onStartDrafting: () -> Void
    let onEdit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                actionBar

                if !snapshot.confirmedItems.isEmpty {
                    knowledgeChipsBar
                    Divider()
                }

                DiaryEntryReadSections(entry: entry, includeAI: false)
            }
            .frame(maxWidth: 800, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(entry.date.formatted(.dateTime.year().month().day()))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .tint(.red)

            Spacer()

            if !snapshot.confirmedItems.isEmpty {
                Button(role: .destructive, action: onClearKnowledge) {
                    Label("清除知识点", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .tint(.orange)
            }

            if entry.hasAIProcessableContent {
                Button(action: onStartDrafting) {
                    Label("AI 整理", systemImage: "brain")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }

            Button(action: onEdit) {
                Label("编辑", systemImage: "pencil")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
    }

    private var knowledgeChipsBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("知识点", systemImage: "brain")
                    .font(.subheadline.bold())
                    .foregroundStyle(.indigo)
                Spacer()
                Text("\(snapshot.confirmedItems.count) 条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(snapshot.confirmedItems) { item in
                        KnowledgeChipCard(item: item)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
