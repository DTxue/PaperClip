extension VocabularyTestView {
    func finishSessionIfReady() {
        guard !didRecordSession else { return }
        guard let sessionMode else { return }

        if sessionMode != .exam {
            if batches.first?.status == .graded {
                if sessionMode.recordsHistory {
                    commitToScheduler(kind: "测验")
                } else {
                    didRecordSession = true
                }
            }
            return
        }

        guard didFinishAnswering, !batches.isEmpty else { return }
        guard batches.allSatisfy({ $0.status == .graded }) else { return }
        commitToScheduler(kind: "测验")
    }

    func commitToScheduler(kind: String) {
        guard !didRecordSession else { return }
        guard let sessionMode, sessionMode.recordsHistory else {
            didRecordSession = true
            return
        }
        do {
            let didCommit = try VocabularyTestSessionCommitTransaction.commitAndSave(
                deck: deck,
                batches: batches,
                kind: kind,
                startedAt: startedAt,
                modelContext: modelContext
            ) { batch, drawingIndex in
                encodedDrawingData(for: batch, drawingIndex: drawingIndex)
            }
            guard didCommit else { return }
            if sessionMode == .exam {
                deleteExamDraft()
            }
            didRecordSession = true
        } catch {
            alert = AppAlert(title: "无法记录测验结果", error: error)
        }
    }
}
