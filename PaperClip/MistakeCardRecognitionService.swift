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
            drain()
        }
    }

    // MARK: - Queue State

    private struct QueueItem {
        enum Priority {
            case userInitiated
            case recovery
        }

        let cardID: UUID
        let imagePath: String
        let priority: Priority
    }

    private var userPending: [QueueItem] = []
    private var recoveryPending: [QueueItem] = []
    private var processingIDs: Set<UUID> = []
    private var activeCount = 0
    private var activeRecoveryCount = 0
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

    private func enqueue(
        cardID: UUID,
        imagePath: String,
        priority: QueueItem.Priority
    ) {
        guard !processingIDs.contains(cardID),
              !userPending.contains(where: { $0.cardID == cardID }),
              !recoveryPending.contains(where: { $0.cardID == cardID }) else {
            return
        }
        let item = QueueItem(
            cardID: cardID,
            imagePath: imagePath,
            priority: priority
        )
        switch priority {
        case .userInitiated:
            userPending.append(item)
        case .recovery:
            recoveryPending.append(item)
        }
        drain()
    }

    /// 启动时重新提交上次未完成的卡片。
    func resumeUnfinished() {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        let all = (try? context.fetch(FetchDescriptor<MistakeCard>())) ?? []
        let unfinished = all.filter {
            $0.recognitionStatus == RecognitionStatus.pending.rawValue
                || $0.recognitionStatus == RecognitionStatus.processing.rawValue
                || $0.recognitionStatus == RecognitionStatus.failed.rawValue
        }
        for card in unfinished {
            card.recognitionStatus = RecognitionStatus.pending.rawValue
            enqueue(
                cardID: card.id,
                imagePath: card.imageURL.path,
                priority: .recovery
            )
        }
        try? context.save()
    }

    // MARK: - Queue Drain

    private func drain() {
        guard modelContainer != nil else { return }

        while activeCount < maxConcurrent, let item = nextItem() {
            guard !processingIDs.contains(item.cardID) else { continue }
            processingIDs.insert(item.cardID)
            activeCount += 1
            if item.priority == .recovery {
                activeRecoveryCount += 1
            }

            Task {
                await process(item: item)
                activeCount -= 1
                if item.priority == .recovery {
                    activeRecoveryCount -= 1
                }
                processingIDs.remove(item.cardID)
                drain()
            }
        }
    }

    private func nextItem() -> QueueItem? {
        if !userPending.isEmpty {
            return userPending.removeFirst()
        }
        guard activeRecoveryCount < maxConcurrentRecovery,
              !recoveryPending.isEmpty else {
            return nil
        }
        return recoveryPending.removeFirst()
    }

    // MARK: - Recognition

    private func process(item: QueueItem) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        // 卡片入队前已经保存；从主上下文加载，确保状态变化实时反映到界面。
        let id = item.cardID
        guard let card = (try? context.fetch(
            FetchDescriptor<MistakeCard>(
                predicate: #Predicate<MistakeCard> { $0.id == id }
            )
        ))?.first else {
            return
        }

        // 入队任务一开始就离开“等待识别”，避免网络准备期间长期显示 pending。
        card.recognitionStatus = RecognitionStatus.processing.rawValue
        save(context)

        // 加载图片
        guard let image = UIImage(contentsOfFile: item.imagePath) else {
            card.recognitionStatus = RecognitionStatus.failed.rawValue
            save(context)
            return
        }

        // 调用 AI 识别
        do {
            let recognition = try await AIService.recognize(image: image)

            card.recognizedText = recognition.recognizedQuestion

            // 仅在识别结果可信时覆盖学科（避免覆盖用户已手动设置的值）
            if let mappedSubject = Subject.from(aiString: recognition.subject) {
                card.subject = mappedSubject.rawValue
            }

            // 用知识点填充 tag（已有 tag 则跳过，尊重用户已有内容）
            let newTags = recognition.knowledgePoints.filter { !$0.isEmpty }
            if !newTags.isEmpty && card.tagsText.isEmpty {
                card.tagsText = newTags.joined(separator: ",")
            }

            card.recognitionStatus = RecognitionStatus.completed.rawValue
            card.updatedAt = .now
        } catch {
            card.recognitionStatus = RecognitionStatus.failed.rawValue
        }

        save(context)
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            assertionFailure("保存错题卡识别状态失败：\(error.localizedDescription)")
        }
    }
}
