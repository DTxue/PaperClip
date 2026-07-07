import Foundation
import SwiftData

extension MistakeCardRecognitionService {
    /// 启动时重新提交上次未完成的卡片。
    func resumeUnfinished() {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        let unfinished: [MistakeCard]
        do {
            unfinished = try context.fetchUnfinishedRecognitionMistakeCards()
        } catch {
            assertionFailure("恢复错题卡识别队列失败：\(error.localizedDescription)")
            return
        }
        persistRecognitionChange {
            try MistakeCardRecognitionTransaction.resetForRecovery(unfinished, in: context)
        }
        for card in unfinished {
            enqueue(
                cardID: card.id,
                imagePath: card.imageURL.path,
                priority: .recovery
            )
        }
    }
}
