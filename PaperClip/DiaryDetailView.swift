import SwiftUI

// MARK: - Detail View

struct DiaryDetailView: View {
    let entry: DiaryEntry
    @State private var isEditorPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DiaryEntryReadSections(entry: entry, includeAI: true)
            }
            .frame(maxWidth: 800, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(entry.date.formatted(.dateTime.year().month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") { isEditorPresented = true }
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            DiaryEditorSheet(existingEntry: entry)
        }
    }
}
