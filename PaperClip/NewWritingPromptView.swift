import SwiftUI
import SwiftData

struct NewWritingPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var studentGrade = "初一"
    @State private var requirementInput = ""
    @State private var isGenerating = false
    @State private var generationTaskSlot = ViewTaskSlot()
    @State private var alert: AppAlert?

    var body: some View {
        NavigationStack {
            Form {
                NewWritingPromptFormSections(
                    studentGrade: $studentGrade,
                    requirementInput: $requirementInput,
                    isGenerating: isGenerating,
                    onGenerate: startGeneratingPrompt
                )
            }
            .navigationTitle("生成写作题")
            .navigationBarTitleDisplayMode(.inline)
            .cancelToolbar { dismiss() }
            .appAlert($alert)
        }
        .onDisappear {
            generationTaskSlot.cancel()
        }
    }

    @MainActor
    private func startGeneratingPrompt() {
        _ = generationTaskSlot.start { taskID in
            await generatePrompt(taskID: taskID)
            generationTaskSlot.finish(taskID)
        }
    }

    @MainActor
    private func generatePrompt(taskID: UUID) async {
        isGenerating = true

        do {
            let draft = WritingPromptGenerationDraft(
                language: .chinese,
                studentGrade: studentGrade,
                requirementInput: requirementInput
            )
            let result = try await AIService.generateWritingPrompt(
                language: draft.language,
                studentGrade: draft.studentGrade,
                requirementInput: draft.requirementInput
            )
            try Task.checkCancellation()
            guard generationTaskSlot.isCurrent(taskID) else { return }
            let prompt = WritingPrompt(
                language: draft.language,
                studentGrade: draft.studentGrade,
                requirementInput: draft.requirementInput,
                generatedTitle: result.title,
                generatedRequirement: result.requirement,
                constraints: result.constraints,
                rubric: result.rubric
            )
            modelContext.insert(prompt)
            try modelContext.saveOrRollbackIfNeeded()
            guard generationTaskSlot.isCurrent(taskID) else { return }
            dismiss()
        } catch is CancellationError {
            guard generationTaskSlot.isCurrent(taskID) else { return }
            modelContext.rollback()
            isGenerating = false
            return
        } catch {
            guard generationTaskSlot.isCurrent(taskID) else { return }
            modelContext.rollback()
            alert = AppAlert(title: "无法生成写作题", error: error)
        }
        guard generationTaskSlot.isCurrent(taskID) else { return }
        isGenerating = false
    }

}
