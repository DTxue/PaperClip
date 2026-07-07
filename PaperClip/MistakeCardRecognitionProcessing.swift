import Foundation
import SwiftData

extension MistakeCardRecognitionService {
    func process(item: MistakeRecognitionQueue.Item) async {
        guard let container = modelContainer, !Task.isCancelled else { return }
        let context = container.mainContext

        // 卡片入队前已经保存；从主上下文加载，确保状态变化实时反映到界面。
        let id = item.cardID
        let card: MistakeCard
        do {
            guard let fetchedCard = try context.fetchMistakeCard(id: id) else {
                return
            }
            card = fetchedCard
        } catch {
            assertionFailure("加载待识别错题卡失败：\(error.localizedDescription)")
            return
        }

        guard !Task.isCancelled else { return }

        // 入队任务一开始就离开“等待识别”，避免网络准备期间长期显示 pending。
        guard persistRecognitionChange({
            try MistakeCardRecognitionTransaction.markProcessing(card, in: context)
        }) else { return }

        // 后台加载图片，避免识别队列在主上下文流程中同步解码大图。
        guard let image = await LocalImageLoader.load(path: item.imagePath) else {
            guard !Task.isCancelled else { return }
            persistRecognitionChange {
                try MistakeCardRecognitionTransaction.markFailed(card, in: context)
            }
            return
        }

        guard !Task.isCancelled else { return }

        do {
            let recognition = try await AIService.recognize(image: image)
            guard !Task.isCancelled else { return }

            persistRecognitionChange {
                try MistakeCardRecognitionTransaction.markCompleted(
                    card,
                    recognition: recognition,
                    in: context
                )
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            persistRecognitionChange {
                try MistakeCardRecognitionTransaction.markFailed(card, in: context)
            }
        }
    }

    @discardableResult
    func persistRecognitionChange(_ change: () throws -> Void) -> Bool {
        do {
            try change()
            return true
        } catch {
            assertionFailure("保存错题卡识别状态失败：\(error.localizedDescription)")
            return false
        }
    }
}
