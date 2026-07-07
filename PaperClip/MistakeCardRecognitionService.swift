import Foundation
import UIKit
import SwiftData

/// 后台静默识别服务：框选保存错题卡后自动调用豆包识别题目内容，
/// 填写 recognizedText、subject、tagsText，不阻塞主线程。
///
/// 设计约束：
/// - 最多同时运行 2 个识别任务，防止 API 限速
/// - 使用 ModelContainer 的主上下文写回，让 SwiftUI 立即观察状态变化
/// - 失败的卡片保留 .failed 状态，下次启动 App 自动补跑
@MainActor
final class MistakeCardRecognitionService {
    static let shared = MistakeCardRecognitionService()
    private init() {}

    var modelContainer: ModelContainer? {
        didSet {
            if oldValue !== modelContainer {
                cancelAllWork()
            }
            drain()
        }
    }

    // MARK: - Queue State

    private var queue = MistakeRecognitionQueue()
    private var activeTaskIDs: [UUID: UUID] = [:]
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    private let maxConcurrent = 2
    private let maxConcurrentRecovery = 1

    // MARK: - Public API

    /// 将新创建的错题卡加入识别队列（由 PDFWorkspaceView 在保存卡片后调用）。
    func enqueue(cardID: UUID, imagePath: String) {
        enqueue(
            cardID: cardID,
            imagePath: imagePath,
            priority: .userInitiated
        )
    }

    func enqueue(
        cardID: UUID,
        imagePath: String,
        priority: MistakeRecognitionQueue.Item.Priority
    ) {
        queue.enqueue(cardID: cardID, imagePath: imagePath, priority: priority)
        drain()
    }

    // MARK: - Queue Drain

    private func drain() {
        guard modelContainer != nil else { return }

        while let item = queue.startNext(
            maxConcurrent: maxConcurrent,
            maxConcurrentRecovery: maxConcurrentRecovery
        ) {
            let taskID = UUID()
            activeTaskIDs[item.cardID] = taskID
            activeTasks[item.cardID] = Task {
                await process(item: item)
                finish(item: item, taskID: taskID)
                drain()
            }
        }
    }

    private func finish(item: MistakeRecognitionQueue.Item, taskID: UUID) {
        guard activeTaskIDs[item.cardID] == taskID else { return }
        activeTaskIDs[item.cardID] = nil
        activeTasks[item.cardID] = nil
        queue.finish(item)
    }

    private func cancelAllWork() {
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        activeTaskIDs.removeAll()
        queue.reset()
    }
}
