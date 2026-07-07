import SwiftUI
import SwiftData

// MARK: - Editor Sheet

struct DiaryEditorSheet: View {
    let existingEntry: DiaryEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var content: DiaryEntryEditableContent
    @State private var savedEntry: DiaryEntry?
    @State private var showAIResult = false
    @State private var alert: AppAlert?

    init(existingEntry: DiaryEntry?) {
        self.existingEntry = existingEntry
        _content = State(initialValue: DiaryEntryEditableContent(entry: existingEntry))
    }

    var body: some View {
        NavigationStack {
            Form {
                DiaryEntryEditorSections(content: $content)
            }
            .navigationTitle(existingEntry != nil ? "修改日记" : "今日日记")
            .navigationBarTitleDisplayMode(.inline)
            .editSheetToolbar(
                onCancel: { dismiss() },
                onConfirm: save
            )
            .navigationDestination(isPresented: $showAIResult) {
                if let entry = savedEntry {
                    DiaryAIResultView(entry: entry, onComplete: { dismiss() })
                }
            }
            .appAlert($alert)
        }
    }

    private func save() {
        guard existingEntry != nil || content.hasInput else { dismiss(); return }

        let entry: DiaryEntry
        if let existing = existingEntry {
            guard content.differs(from: existing) else {
                if existing.hasAIProcessableContent {
                    savedEntry = existing
                    showAIResult = true
                } else {
                    dismiss()
                }
                return
            }
            entry = existing
        } else {
            entry = DiaryEntry(date: .now)
            modelContext.insert(entry)
        }

        let aiContentChanged = existingEntry.map(content.aiContentDiffers(from:)) ?? true

        content.apply(to: entry)
        entry.updatedAt = .now

        if aiContentChanged {
            entry.aiState = "pending"
            entry.aiLearned = ""
            entry.aiConfused = ""
            entry.aiInspired = ""
        }

        do {
            try modelContext.saveOrRollbackIfNeeded()
        } catch {
            alert = AppAlert(title: "无法保存日记", error: error)
            return
        }

        if entry.hasAIProcessableContent {
            savedEntry = entry
            showAIResult = true
        } else {
            dismiss()
        }
    }

}
