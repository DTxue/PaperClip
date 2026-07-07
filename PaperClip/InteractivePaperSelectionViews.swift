import SwiftUI
import SwiftData

private struct InteractivePaperSession: Identifiable {
    let id = UUID()
    let cards: [MistakeCard]
}

struct PaperCardSelectionView: View {
    let availableCards: [MistakeCardRowData]
    let subject: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedIDs: Set<UUID>
    @State private var filterStatus: PaperSelectionStatusFilter = .unmastered
    @State private var activeSession: InteractivePaperSession?
    @State private var alert: AppAlert?

    init(availableCards: [MistakeCardRowData], subject: String?) {
        self.availableCards = availableCards
        self.subject = subject
        _selectedIDs = State(initialValue: PaperSelectionSnapshot.initiallySelectedIDs(from: availableCards))
    }

    private var selectionSnapshot: PaperSelectionSnapshot {
        PaperSelectionSnapshot(
            availableCards: availableCards,
            filterStatus: filterStatus,
            selectedIDs: selectedIDs
        )
    }

    var body: some View {
        let snapshot = selectionSnapshot

        NavigationStack {
            PaperCardSelectionList(
                availableCards: availableCards,
                snapshot: snapshot,
                filterStatus: $filterStatus,
                selectedIDs: $selectedIDs
            )
            .navigationTitle("出卷选题\(subject.map { " · \($0)" } ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .cancelToolbar { dismiss() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("开始（\(selectedIDs.count) 题）") {
                        startSelectedPaper()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedIDs.isEmpty)
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button(snapshot.allSelected ? "全不选" : "全选") {
                        if snapshot.allSelected { selectedIDs.subtract(snapshot.displayCardIDs) }
                        else { selectedIDs.formUnion(snapshot.displayCardIDs) }
                    }
                }
            }
        }
        .fullScreenCover(item: $activeSession) { session in
            InteractivePaperView(cards: session.cards, subject: subject)
        }
        .appAlert($alert)
    }

    private func startSelectedPaper() {
        let orderedIDs = selectionSnapshot.selectedOrderedIDs
        guard !orderedIDs.isEmpty else { return }

        do {
            let cards = try modelContext.fetchMistakeCards(ids: orderedIDs)
            guard !cards.isEmpty else {
                alert = AppAlert(title: "无法开始出卷", message: "所选错题不存在或已被删除。")
                return
            }
            activeSession = InteractivePaperSession(cards: cards)
        } catch {
            alert = AppAlert(title: "无法开始出卷", error: error)
        }
    }
}
