import SwiftUI
import UniformTypeIdentifiers

struct ShareImageRequest: Identifiable, Transferable, Sendable {
    let id = UUID()
    let data: Data

    var image: UIImage? { UIImage(data: data) }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .image) { request in
            request.data
        }
    }
}

struct PDFWorkspaceSnapshot {
    let latestAttempt: ExamAttemptHistoryRowData?
    let attemptCount: Int
    let gradeStamps: [PDFGradeStamp]

    var hasAttempts: Bool { attemptCount > 0 }

    init(
        latestAttempt: ExamAttemptHistoryRowData?,
        attemptCount: Int,
        activeGradeMarks: [ExamGradeMark],
        activeAttempt: ExamAttempt?
    ) {
        self.latestAttempt = latestAttempt
        self.attemptCount = attemptCount

        guard let activeAttempt else {
            gradeStamps = []
            return
        }

        var activeGradeStamps: [PDFGradeStamp] = []
        for mark in activeGradeMarks where mark.attemptId == activeAttempt.id {
            guard let point = Self.normalizedPoint(from: mark.normalizedAnchor) else { continue }
            activeGradeStamps.append(
                PDFGradeStamp(
                    id: mark.id,
                    pageIndex: mark.pageIndex,
                    isCorrect: mark.isCorrect,
                    normalizedAnchor: point,
                    confidence: mark.confidence
                )
            )
        }
        gradeStamps = activeGradeStamps
    }

    private static func normalizedPoint(from string: String) -> CGPoint? {
        let parts = string
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard parts.count == 2 else { return nil }
        return CGPoint(x: parts[0], y: parts[1])
    }
}

struct PDFWorkspaceCanvasSnapshot {
    let url: URL
    let drawings: [Int: Data]
    let gradeStamps: [PDFGradeStamp]
    let hasActiveAttempt: Bool
    let isWritingEnabled: Bool
    let isDrawingVisible: Bool
    let isSelectionMode: Bool
    let showsStartOverlay: Bool
    let latestAttempt: ExamAttemptHistoryRowData?
    let attemptCount: Int
    let isSubmittingExam: Bool

    init(
        activePDFURL: URL,
        drawings: [Int: Data],
        workspaceSnapshot: PDFWorkspaceSnapshot,
        hasActiveAttempt: Bool,
        isWritingEnabled: Bool,
        isDrawingVisible: Bool,
        isSelectionMode: Bool,
        isSubmittingExam: Bool
    ) {
        self.url = activePDFURL
        self.drawings = drawings
        self.gradeStamps = workspaceSnapshot.gradeStamps
        self.hasActiveAttempt = hasActiveAttempt
        self.isWritingEnabled = hasActiveAttempt && isWritingEnabled
        self.isDrawingVisible = isDrawingVisible
        self.isSelectionMode = hasActiveAttempt && isSelectionMode
        self.showsStartOverlay = !hasActiveAttempt
        self.latestAttempt = workspaceSnapshot.latestAttempt
        self.attemptCount = workspaceSnapshot.attemptCount
        self.isSubmittingExam = isSubmittingExam
    }
}

// MARK: - 框选菜单栏

struct SelectionMenuBar: View {
    let onSave: () -> Void
    let onShare: () -> Void
    let onReselect: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            menuButton("收藏错题", icon: "rectangle.stack.badge.plus", action: onSave)
            Divider().frame(height: 20)
            menuButton("分享截图", icon: "square.and.arrow.up", action: onShare)
            Divider().frame(height: 20)
            menuButton("重新选取", icon: "arrow.clockwise", action: onReselect)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderless)
    }
}
