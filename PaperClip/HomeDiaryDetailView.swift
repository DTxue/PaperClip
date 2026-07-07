import SwiftData
import SwiftUI

struct HomeDiaryDetailView: View {
    @Environment(\.modelContext) var modelContext

    @Binding var todayEntry: DiaryEntry?
    @Binding var selection: DiaryListItem?
    @Binding var diaryDraft: DiaryEntryEditableContent
    @Binding var loadedDate: Date?
    @Binding var newEntryDate: Date?
    @Binding var alert: AppAlert?

    var body: some View {
        detailContent
            .task {
                refreshTodayEntry()
                loadTodayDraftIfNeeded()
            }
    }

    @ViewBuilder
    private var detailContent: some View {
        if let date = newEntryDate {
            newEntryEditView(for: date)
        } else {
            switch selection {
            case .today, nil:
                if let entry = todayEntry {
                    DiaryEntryDetailPane(entry: entry, onDelete: {
                        refreshTodayEntry()
                        loadedDate = nil
                        loadTodayDraftIfNeeded()
                        selection = .today
                    })
                    .id(entry.id)
                } else {
                    todayEditView
                }
            case .entry(let entry):
                DiaryEntryDetailPane(entry: entry, onDelete: {
                    if Calendar.current.isDateInToday(entry.date) {
                        refreshTodayEntry()
                        loadedDate = nil
                        loadTodayDraftIfNeeded()
                    }
                    selection = .today
                })
                .id(entry.id)
            }
        }
    }

    private var todayEditView: some View {
        Form {
            DiaryEntryEditorSections(content: $diaryDraft)
        }
        .navigationTitle("今日日记")
        .navigationBarTitleDisplayMode(.inline)
        .prominentActionToolbar("保存", action: saveToday)
    }

    private func newEntryEditView(for date: Date) -> some View {
        Form {
            DiaryEntryEditorSections(content: $diaryDraft)
        }
        .navigationTitle(date.formatted(.dateTime.year().month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .prominentSaveToolbar(
            onCancel: {
                newEntryDate = nil
                selection = .today
            },
            onSave: { saveNewEntry(for: date) }
        )
    }
}
