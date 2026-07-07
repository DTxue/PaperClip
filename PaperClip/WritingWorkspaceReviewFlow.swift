import SwiftUI

extension WritingWorkspaceView {
    @MainActor
    func startReview() async {
        guard DrawingDataSupport.hasInk(drawingStore.drawing) else {
            alert = AppAlert(title: "还没有书写内容", message: "请先完成作文，再提交批阅。")
            return
        }
        guard saveDraft() else { return }
        phase = .recognizing
        updateActiveDraftReviewState(status: .recognizing)
        guard saveReviewState(failureTitle: "无法保存作文状态") else { return }

        do {
            let image = try await WritingOCRImageRenderer.render(
                drawing: drawingStore.drawing,
                paperSize: paperSize,
                blackPaperMode: blackPaperMode
            )
            let result = try await AIService.recognizeWriting(image: image, language: prompt.language)
            recognitionText = result.recognizedText
            updateActiveDraftReviewState(status: .recognized, recognizedText: result.recognizedText)
            try WritingReviewTransaction.saveState(in: modelContext)
            phase = .idle
            isShowingRecognitionSheet = true
        } catch is CancellationError {
            phase = .idle
            updateActiveDraftReviewState(status: .draft)
            _ = saveReviewState(failureTitle: "无法恢复作文状态")
        } catch {
            phase = .idle
            saveFailureReviewState(
                status: .failed,
                originalError: error,
                alertTitle: "作文识别失败",
                saveFailureTitle: "作文识别失败，且状态保存失败"
            )
        }
    }

    @MainActor
    func submitForReview(confirmedText: String) async {
        let text = confirmedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            alert = AppAlert(title: "识别文本为空", message: "请修正识别结果后再提交批阅。")
            return
        }
        guard let activeDraft else { return }

        phase = .grading
        updateActiveDraftReviewState(status: .grading, recognizedText: text)
        guard saveReviewState(failureTitle: "无法保存作文状态") else { return }

        do {
            let result = try await AIService.reviewWriting(
                language: prompt.language,
                studentGrade: prompt.studentGrade,
                writingRequirement: prompt.generatedRequirement,
                recognizedText: text,
                fullScore: prompt.language.defaultFullScore
            )
            let review = WritingReview(
                promptID: prompt.id,
                draftID: activeDraft.id,
                language: prompt.language,
                recognizedText: text,
                reviewJSONData: result.encodedData(),
                overallJudgement: result.overallJudgement,
                teacherComment: result.teacherComment,
                scoreText: result.scoreText
            )
            try WritingReviewTransaction.insertCompletedReview(
                review,
                draft: activeDraft,
                in: modelContext
            )
            refreshReviewSummaries()
            phase = .idle
            presentedReview = WritingReviewRowData(review: review)
        } catch is CancellationError {
            phase = .idle
            updateActiveDraftReviewState(status: .recognized)
            _ = saveReviewState(failureTitle: "无法恢复作文状态")
        } catch {
            phase = .idle
            saveFailureReviewState(
                status: .failed,
                originalError: error,
                alertTitle: "作文批阅失败",
                saveFailureTitle: "作文批阅失败，且状态保存失败"
            )
        }
    }
}
