import SwiftData
import SwiftUI

extension MistakeCardEditorView {
    func saveAndDismiss() {
        let nextPrintHeight = MistakeCardEditorDraftLogic.printHeight(
            printWidthMM: draftPrintWidthMM,
            aspectRatio: card.aspectRatio
        )
        guard hasChanges || card.printHeightMM != nextPrintHeight else {
            dismiss()
            return
        }

        applyDraft(nextPrintHeight: nextPrintHeight)
        guard modelContext.hasChanges else {
            dismiss()
            return
        }

        let oldFingerprint = initialFingerprint
        do {
            try MistakeCardEditorSaveTransaction.save(
                card: card,
                nextPrintHeight: nextPrintHeight,
                in: modelContext
            )
            initialFingerprint = currentFingerprint
            dismiss()
        } catch {
            initialFingerprint = oldFingerprint
            loadDraft(force: true)
            alert = AppAlert(title: "无法保存错题卡", error: error)
        }
    }

    func loadDraftIfNeeded() {
        guard initialFingerprint.isEmpty else { return }
        loadDraft(force: true)
        initialFingerprint = currentFingerprint
    }

    func loadDraft(force: Bool = false) {
        guard force || initialFingerprint.isEmpty else { return }
        draftGrade = card.grade
        draftSemester = card.semester
        draftSubject = card.subject
        draftQuestionType = card.resolvedQuestionType.rawValue
        draftCorrectAnswer = card.correctAnswer
        draftTagsText = card.tagsText
        draftErrorReason = card.errorReason
        draftStatus = card.status
        draftNote = card.note
        draftPrintWidthMM = card.printWidthMM
        draftQuestionCrop = card.questionCrop
    }

    func applyDraft(nextPrintHeight: Double) {
        card.grade = draftGrade
        card.semester = draftSemester
        card.subject = draftSubject
        card.questionType = draftQuestionType
        card.correctAnswer = draftCorrectAnswer
        card.tagsText = draftTagsText
        card.errorReason = draftErrorReason
        card.status = draftStatus
        card.note = draftNote
        card.printWidthMM = draftPrintWidthMM
        card.printHeightMM = nextPrintHeight
        card.questionCrop = draftQuestionCrop
    }
}
