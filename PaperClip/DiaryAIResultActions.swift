import SwiftUI

extension DiaryAIResultView {
    func initDraftsIfNeeded() {
        guard !didInitializeDrafts else { return }
        learnedDraft = entry.aiLearned
        confusedDraft = entry.aiConfused
        inspiredDraft = entry.aiInspired
        learnedState = sectionState(original: entry.learned, ai: entry.aiLearned)
        confusedState = sectionState(original: entry.confused, ai: entry.aiConfused)
        inspiredState = sectionState(original: entry.inspired, ai: entry.aiInspired)
        didInitializeDrafts = true
    }

    func sectionState(original: String, ai: String) -> SectionAIState {
        guard !original.isEmpty else { return .ignored }
        if entry.aiState == "pending" { return .loading }
        return ai.isEmpty ? .ignored : .done
    }

    func startLearnedTask() {
        startTask(
            text: entry.learned,
            state: $learnedState,
            draft: $learnedDraft,
            processor: AIService.processDiaryLearned,
            start: { learnedTaskSlot.start($0) },
            isCurrent: { learnedTaskSlot.isCurrent($0) },
            finish: { learnedTaskSlot.finish($0) }
        )
    }

    func startConfusedTask() {
        startTask(
            text: entry.confused,
            state: $confusedState,
            draft: $confusedDraft,
            processor: AIService.processDiaryConfused,
            start: { confusedTaskSlot.start($0) },
            isCurrent: { confusedTaskSlot.isCurrent($0) },
            finish: { confusedTaskSlot.finish($0) }
        )
    }

    func startInspiredTask() {
        startTask(
            text: entry.inspired,
            state: $inspiredState,
            draft: $inspiredDraft,
            processor: AIService.processDiaryInspired,
            start: { inspiredTaskSlot.start($0) },
            isCurrent: { inspiredTaskSlot.isCurrent($0) },
            finish: { inspiredTaskSlot.finish($0) }
        )
    }

    func finish() {
        applyDrafts()
        if entry.aiState != "done" {
            entry.aiState = "done"
        }
        do {
            try modelContext.saveOrRollbackIfNeeded()
        } catch {
            alert = AppAlert(title: "无法保存 AI 整理结果", error: error)
            return
        }
        onComplete()
    }

    func applyDrafts() {
        if entry.aiLearned != learnedDraft {
            entry.aiLearned = learnedDraft
        }
        if entry.aiConfused != confusedDraft {
            entry.aiConfused = confusedDraft
        }
        if entry.aiInspired != inspiredDraft {
            entry.aiInspired = inspiredDraft
        }
    }
}
