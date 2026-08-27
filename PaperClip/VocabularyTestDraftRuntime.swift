import Foundation
import PencilKit

struct VocabularyDraftDrawingKey: Hashable {
    let batchID: Int
    let drawingIndex: Int
}

struct VocabularyTestGradingTaskContext {
    let sessionID: UUID
    let taskID: UUID
}

final class VocabularyTestGradingTaskStore {
    private var sessionID = UUID()
    private var tasksByBatchID: [Int: Task<Void, Never>] = [:]
    private var taskIDsByBatchID: [Int: UUID] = [:]

    func prepareTask(batchID: Int) -> VocabularyTestGradingTaskContext {
        tasksByBatchID[batchID]?.cancel()
        let taskID = UUID()
        taskIDsByBatchID[batchID] = taskID
        return VocabularyTestGradingTaskContext(sessionID: sessionID, taskID: taskID)
    }

    func setTask(_ task: Task<Void, Never>, batchID: Int, taskID: UUID) {
        guard taskIDsByBatchID[batchID] == taskID else {
            task.cancel()
            return
        }
        tasksByBatchID[batchID] = task
    }

    func restart() {
        cancelAll()
        sessionID = UUID()
    }

    func cancelAll() {
        for task in tasksByBatchID.values {
            task.cancel()
        }
        tasksByBatchID.removeAll()
        taskIDsByBatchID.removeAll()
    }

    func isCurrent(sessionID: UUID, taskID: UUID, batchID: Int) -> Bool {
        self.sessionID == sessionID && taskIDsByBatchID[batchID] == taskID
    }

    func clear(batchID: Int, taskID: UUID) {
        guard taskIDsByBatchID[batchID] == taskID else { return }
        tasksByBatchID[batchID] = nil
        taskIDsByBatchID[batchID] = nil
    }
}

final class VocabularyDraftDrawingDataCache {
    private var dataByDrawingKey: [VocabularyDraftDrawingKey: Data] = [:]

    func set(_ data: Data, for key: VocabularyDraftDrawingKey) {
        dataByDrawingKey[key] = data
    }

    func data(for key: VocabularyDraftDrawingKey, drawing: PKDrawing) -> Data {
        if let cached = dataByDrawingKey[key] {
            return cached
        }
        let data = DrawingDataSupport.data(from: drawing)
        dataByDrawingKey[key] = data
        return data
    }

    func removeValue(for key: VocabularyDraftDrawingKey) {
        dataByDrawingKey[key] = nil
    }

    func removeAll() {
        dataByDrawingKey.removeAll(keepingCapacity: true)
    }
}
