import SwiftUI
import SwiftData

struct KnowledgeItemDetailView: View {
    let item: KnowledgeItem

    var body: some View {
        KnowledgeItemDetailContent(item: item)
            .navigationTitle("知识点详情")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct KnowledgeItemSheetView: View {
    let item: KnowledgeItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            KnowledgeItemDetailContent(item: item)
                .navigationTitle("知识点详情")
                .navigationBarTitleDisplayMode(.inline)
                .doneToolbar { dismiss() }
        }
        .presentationSizing(.page)
        .presentationDragIndicator(.hidden)
    }
}

struct KnowledgeItemSheetLoader: View {
    @Environment(\.modelContext) private var modelContext
    let itemID: UUID
    @State private var item: KnowledgeItem?
    @State private var alert: AppAlert?

    var body: some View {
        Group {
            if let item {
                KnowledgeItemSheetView(item: item)
            } else {
                NavigationStack {
                    ProgressView()
                        .navigationTitle("知识点详情")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationSizing(.page)
                .presentationDragIndicator(.hidden)
            }
        }
        .task(id: itemID) {
            loadItem()
        }
        .appAlert($alert)
    }

    private func loadItem() {
        do {
            item = try modelContext.fetchKnowledgeItem(id: itemID)
        } catch {
            item = nil
            alert = AppAlert(title: "无法读取知识点详情", error: error)
        }
    }
}
