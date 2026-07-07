import SwiftUI

extension PDFWorkspaceView {
    func leaveSelectionMode() {
        session.leaveSelectionMode()
    }

    func selectionRectDidChange(_ rect: CGRect?) {
        guard session.selectionRect != rect else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            session.selectionRect = rect
        }
    }

    func performSelectionAction(_ action: PDFSelectionAction) {
        cancelSelectionActionTask()
        session.pendingSelectionAction = action
        session.selectionActionToken += 1
    }

    func resetSelection() {
        cancelSelectionActionTask()
        session.pendingSelectionAction = nil
        session.cancelSelectionToken += 1
    }

    func handleSelectionAction(
        image: UIImage,
        width: Double,
        height: Double,
        action: PDFSelectionAction
    ) {
        // 延迟状态更新，避免在 updateUIView 内部同步修改触发 SwiftUI 重建。
        let captured = image
        cancelSelectionActionTask()
        switch action {
        case .share:
            _ = session.selectionActionTaskSlot.start { taskID in
                defer { session.selectionActionTaskSlot.finish(taskID) }
                await shareSelectionImage(captured, taskID: taskID)
            }
        case .saveMistake:
            _ = session.selectionActionTaskSlot.start { taskID in
                defer { session.selectionActionTaskSlot.finish(taskID) }
                await saveSelectionAsMistake(
                    image: captured,
                    width: width,
                    height: height,
                    taskID: taskID
                )
            }
        }
    }

    func isCurrentSelectionActionTask(_ taskID: UUID) -> Bool {
        session.selectionActionTaskSlot.isCurrent(taskID)
    }

    func cancelSelectionActionTask() {
        session.selectionActionTaskSlot.cancel()
    }
}
