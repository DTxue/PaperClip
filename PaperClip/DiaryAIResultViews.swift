import SwiftUI
import SwiftData

// MARK: - AI Result View

enum SectionAIState: Equatable {
    case loading
    case done
    case failed(String)
    case ignored
}

struct DiaryAIResultView: View {
    let entry: DiaryEntry
    let onComplete: () -> Void

    @Environment(\.modelContext) var modelContext

    @State var learnedState: SectionAIState = .ignored
    @State var confusedState: SectionAIState = .ignored
    @State var inspiredState: SectionAIState = .ignored
    @State var learnedDraft = ""
    @State var confusedDraft = ""
    @State var inspiredDraft = ""
    @State var didInitializeDrafts = false
    @State var learnedTaskSlot = DiaryTaskSlot()
    @State var confusedTaskSlot = DiaryTaskSlot()
    @State var inspiredTaskSlot = DiaryTaskSlot()
    @State var alert: AppAlert?

    var body: some View {
        let contentPresence = entry.contentPresence

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if contentPresence.hasLearned {
                    aiSection(
                        icon: "book.fill", color: .blue,
                        title: "今天学了什么",
                        original: entry.learned,
                        aiResult: $learnedDraft,
                        state: $learnedState,
                        retryAction: startLearnedTask
                    )
                }
                if contentPresence.hasConfused {
                    aiSection(
                        icon: "questionmark.circle.fill", color: .orange,
                        title: "今天哪些地方没搞懂",
                        original: entry.confused,
                        aiResult: $confusedDraft,
                        state: $confusedState,
                        retryAction: startConfusedTask
                    )
                }
                if contentPresence.hasNoted {
                    noteSection
                }
                if contentPresence.hasInspired {
                    aiSection(
                        icon: "lightbulb.fill", color: .yellow,
                        title: "今天有什么灵光一闪的想法",
                        original: entry.inspired,
                        aiResult: $inspiredDraft,
                        state: $inspiredState,
                        retryAction: startInspiredTask
                    )
                }
            }
            .frame(maxWidth: 800, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("AI 整理结果")
        .navigationBarTitleDisplayMode(.inline)
        .doneToolbar(action: finish)
        .appAlert($alert)
        .task {
            initDraftsIfNeeded()
            guard entry.aiState == "pending" else { return }
            let contentPresence = entry.contentPresence
            if contentPresence.hasLearned { startLearnedTask() }
            if contentPresence.hasConfused { startConfusedTask() }
            if contentPresence.hasInspired { startInspiredTask() }
        }
        .onDisappear {
            learnedTaskSlot.cancel()
            confusedTaskSlot.cancel()
            inspiredTaskSlot.cancel()
        }
    }
}
