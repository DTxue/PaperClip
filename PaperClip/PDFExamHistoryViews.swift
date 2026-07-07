import SwiftUI

struct ExamAttemptHistoryRowData: Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let selectedPageIndicesText: String
    let status: String

    init(
        id: UUID,
        createdAt: Date,
        updatedAt: Date,
        selectedPageIndicesText: String,
        status: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.selectedPageIndicesText = selectedPageIndicesText
        self.status = status
    }

    init(attempt: ExamAttempt) {
        id = attempt.id
        createdAt = attempt.createdAt
        updatedAt = attempt.updatedAt
        selectedPageIndicesText = attempt.selectedPageIndicesText
        status = attempt.status
    }

    var selectedPageIndices: [Int] {
        PDFPageIndexDisplay.parseStoredIndices(selectedPageIndicesText)
    }

    static var propertiesToFetch: [PartialKeyPath<ExamAttempt>] {
        [
            \.id,
            \.sourceDocumentId,
            \.selectedPageIndicesText,
            \.status,
            \.createdAt,
            \.updatedAt
        ]
    }
}

struct ExamAttemptHistorySnapshot {
    let rows: [ExamAttemptHistoryDisplayRow]

    init(attempts: [ExamAttemptHistoryRowData]) {
        let orderedAttempts = Self.isSortedByUpdatedAtDescending(attempts)
            ? attempts
            : attempts.sorted { $0.updatedAt > $1.updatedAt }
        rows = orderedAttempts.map(ExamAttemptHistoryDisplayRow.init)
    }

    private static func isSortedByUpdatedAtDescending(_ attempts: [ExamAttemptHistoryRowData]) -> Bool {
        guard attempts.count > 1 else { return true }
        for index in attempts.indices.dropFirst() where attempts[index - 1].updatedAt < attempts[index].updatedAt {
            return false
        }
        return true
    }
}

struct ExamAttemptHistoryState: Equatable {
    var latestAttempt: ExamAttemptHistoryRowData?
    var attemptCount: Int
    var attempts: [ExamAttemptHistoryRowData]

    init(
        latestAttempt: ExamAttemptHistoryRowData? = nil,
        attemptCount: Int = 0,
        attempts: [ExamAttemptHistoryRowData] = []
    ) {
        self.latestAttempt = latestAttempt
        self.attemptCount = max(attemptCount, attempts.count)
        self.attempts = Self.normalizedAttempts(attempts)

        if let first = self.attempts.first {
            self.latestAttempt = Self.latest(first, self.latestAttempt)
        }
    }

    init(fetchedAttempts: [ExamAttemptHistoryRowData]) {
        let attempts = Self.normalizedAttempts(fetchedAttempts)
        self.latestAttempt = attempts.first
        self.attemptCount = attempts.count
        self.attempts = attempts
    }

    init(
        summaryLatestAttempt: ExamAttemptHistoryRowData?,
        attemptCount: Int,
        cachedAttempts: [ExamAttemptHistoryRowData]
    ) {
        let count = max(0, attemptCount)
        let attempts = count == 0 ? [] : Self.normalizedAttempts(cachedAttempts)
        self.latestAttempt = Self.latest(summaryLatestAttempt, attempts.first)
        self.attemptCount = count
        self.attempts = attempts.count <= count ? attempts : []
    }

    mutating func recordInserted(_ attempt: ExamAttemptHistoryRowData) {
        let existed = latestAttempt?.id == attempt.id || attempts.contains { $0.id == attempt.id }
        upsertAttempt(attempt)
        if !existed {
            attemptCount += 1
        }
        attemptCount = max(attemptCount, attempts.count)
    }

    mutating func recordUpdated(_ attempt: ExamAttemptHistoryRowData) {
        upsertAttempt(attempt)
        attemptCount = max(attemptCount, attempts.count)
    }

    private mutating func upsertAttempt(_ attempt: ExamAttemptHistoryRowData) {
        if let index = attempts.firstIndex(where: { $0.id == attempt.id }) {
            attempts[index] = attempt
        } else {
            attempts.append(attempt)
        }
        attempts = Self.normalizedAttempts(attempts)
        latestAttempt = Self.latest(attempts.first, latestAttempt)
        latestAttempt = Self.latest(attempt, latestAttempt)
    }

    private static func latest(
        _ lhs: ExamAttemptHistoryRowData?,
        _ rhs: ExamAttemptHistoryRowData?
    ) -> ExamAttemptHistoryRowData? {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs.updatedAt >= rhs.updatedAt ? lhs : rhs
        case let (lhs?, nil):
            return lhs
        case let (nil, rhs?):
            return rhs
        case (nil, nil):
            return nil
        }
    }

    private static func normalizedAttempts(
        _ attempts: [ExamAttemptHistoryRowData]
    ) -> [ExamAttemptHistoryRowData] {
        var latestByID: [UUID: ExamAttemptHistoryRowData] = [:]
        for attempt in attempts {
            if let existing = latestByID[attempt.id], existing.updatedAt >= attempt.updatedAt {
                continue
            }
            latestByID[attempt.id] = attempt
        }
        return latestByID.values.sorted { $0.updatedAt > $1.updatedAt }
    }
}

struct ExamAttemptHistoryDisplayRow: Identifiable, Hashable {
    let attempt: ExamAttemptHistoryRowData
    let pageCount: Int
    let pageSummary: String
    let statusStyle: ExamAttemptHistoryStatusStyle

    var id: UUID { attempt.id }
    var createdAt: Date { attempt.createdAt }
    var statusTitle: String { statusStyle.title }
    var iconName: String { statusStyle.iconName }

    init(attempt: ExamAttemptHistoryRowData) {
        self.attempt = attempt

        let pages = PDFPageIndexDisplay.userPageNumbers(
            forZeroBasedIndices: attempt.selectedPageIndices
        )
        pageCount = pages.count
        pageSummary = PDFPageIndexDisplay.summary(pages)
        statusStyle = ExamAttemptHistoryStatusStyle(status: attempt.status)
    }
}
