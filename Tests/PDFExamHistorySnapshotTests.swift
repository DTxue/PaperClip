import Foundation

@main
struct PDFExamHistorySnapshotTests {
    static func main() {
        testSnapshotSortsAttemptsByUpdatedAtDescending()
        testDisplayRowsSummarizePagesAndStatus()
        testHistoryStateNormalizesFetchedAttempts()
        testHistoryStateUsesSummaryCountAsAuthoritative()
        testHistoryStatePreservesKnownCountWhenHistoryIsPartial()
        testHistoryStateDoesNotDoubleCountLatestInsert()
        testHistoryStateUpdatesExistingAttemptWithoutChangingCount()
        print("PDFExamHistorySnapshotTests: 14 passed")
    }

    private static func testSnapshotSortsAttemptsByUpdatedAtDescending() {
        let olderID = UUID()
        let newerID = UUID()
        let attempts = [
            makeAttempt(id: olderID, updatedAt: Date(timeIntervalSince1970: 10)),
            makeAttempt(id: newerID, updatedAt: Date(timeIntervalSince1970: 20))
        ]

        let snapshot = ExamAttemptHistorySnapshot(attempts: attempts)

        expect(snapshot.rows.map(\.id) == [newerID, olderID], "history rows should be newest first")
    }

    private static func testDisplayRowsSummarizePagesAndStatus() {
        let graded = ExamAttemptHistoryDisplayRow(attempt: makeAttempt(
            selectedPageIndicesText: "0,1,2,3,4,5,6",
            status: ExamAttemptStatus.graded.rawValue
        ))
        expect(graded.pageCount == 7, "page count should match selected pages")
        expect(graded.pageSummary == "1、2、3、4、5、6...", "long page summaries should show the first six pages")
        expect(
            PDFPageIndexDisplay.summary([1, 2, 3], limit: 2) == "1、2...",
            "page summary formatter should support explicit display limits"
        )
        expect(graded.statusTitle == "已批阅", "graded attempts should use graded title")
        expect(graded.iconName == "checkmark.seal.fill", "graded attempts should use system graded icon")

        let submitted = ExamAttemptHistoryDisplayRow(attempt: makeAttempt(
            selectedPageIndicesText: "2",
            status: ExamAttemptStatus.submitted.rawValue
        ))
        expect(submitted.pageSummary == "3", "page summaries should convert zero-based indices to user-facing pages")
        expect(submitted.statusTitle == "已交卷", "submitted attempts should use submitted title")
        expect(submitted.iconName == "tray.full.fill", "submitted attempts should use system submitted icon")

        let inProgress = ExamAttemptHistoryDisplayRow(attempt: makeAttempt(
            selectedPageIndicesText: "",
            status: "unexpected"
        ))
        expect(inProgress.pageSummary == "无页面", "empty page selections should be explicit")
        expect(inProgress.statusTitle == "进行中", "unknown statuses should fall back to in-progress")
        expect(inProgress.iconName == "pencil.and.scribble", "in-progress attempts should use system writing icon")
    }

    private static func testHistoryStateNormalizesFetchedAttempts() {
        let sharedID = UUID()
        let olderDuplicate = makeAttempt(id: sharedID, updatedAt: Date(timeIntervalSince1970: 10))
        let newerDuplicate = makeAttempt(id: sharedID, updatedAt: Date(timeIntervalSince1970: 30))
        let middle = makeAttempt(updatedAt: Date(timeIntervalSince1970: 20))

        let state = ExamAttemptHistoryState(fetchedAttempts: [olderDuplicate, middle, newerDuplicate])

        expect(state.attempts.map(\.id) == [sharedID, middle.id], "fetched history should keep newest row per id and sort")
        expect(state.latestAttempt?.id == sharedID, "latest attempt should follow normalized sorted history")
        expect(state.attemptCount == 2, "full fetched history should define the count")
    }

    private static func testHistoryStateUsesSummaryCountAsAuthoritative() {
        let stale = makeAttempt(updatedAt: Date(timeIntervalSince1970: 20))
        let emptyState = ExamAttemptHistoryState(
            summaryLatestAttempt: nil,
            attemptCount: 0,
            cachedAttempts: [stale]
        )

        expect(emptyState.latestAttempt == nil, "empty summary should clear latest attempt")
        expect(emptyState.attemptCount == 0, "summary count should remain authoritative")
        expect(emptyState.attempts.isEmpty, "empty summary should clear stale cached attempts")

        let latest = makeAttempt(updatedAt: Date(timeIntervalSince1970: 30))
        let state = ExamAttemptHistoryState(
            summaryLatestAttempt: latest,
            attemptCount: 1,
            cachedAttempts: [stale, latest]
        )
        expect(state.latestAttempt == latest, "summary latest should win when newer")
        expect(state.attemptCount == 1, "summary count should not be inflated by cache")
        expect(state.attempts.isEmpty, "cache larger than summary count should be dropped")
    }

    private static func testHistoryStatePreservesKnownCountWhenHistoryIsPartial() {
        let knownLatest = makeAttempt(updatedAt: Date(timeIntervalSince1970: 20))
        let inserted = makeAttempt(updatedAt: Date(timeIntervalSince1970: 30))
        var state = ExamAttemptHistoryState(
            latestAttempt: knownLatest,
            attemptCount: 5,
            attempts: []
        )

        state.recordInserted(inserted)

        expect(state.attemptCount == 6, "insert should increment the known total count")
        expect(state.attempts.map(\.id) == [inserted.id], "partial local history should upsert the inserted row")
        expect(state.latestAttempt?.id == inserted.id, "newer inserted attempt should become latest")
    }

    private static func testHistoryStateDoesNotDoubleCountLatestInsert() {
        let latest = makeAttempt(updatedAt: Date(timeIntervalSince1970: 10))
        var state = ExamAttemptHistoryState(
            latestAttempt: latest,
            attemptCount: 4,
            attempts: []
        )

        state.recordInserted(latest)

        expect(state.attemptCount == 4, "inserting the known latest attempt should not double count")
        expect(state.attempts == [latest], "known latest should be inserted into the local list")
    }

    private static func testHistoryStateUpdatesExistingAttemptWithoutChangingCount() {
        let id = UUID()
        let original = makeAttempt(id: id, updatedAt: Date(timeIntervalSince1970: 10))
        let updated = makeAttempt(id: id, updatedAt: Date(timeIntervalSince1970: 40), status: ExamAttemptStatus.graded.rawValue)
        var state = ExamAttemptHistoryState(
            latestAttempt: original,
            attemptCount: 3,
            attempts: [original]
        )

        state.recordUpdated(updated)

        expect(state.attemptCount == 3, "updating an existing attempt should preserve known count")
        expect(state.attempts == [updated], "existing row should be replaced")
        expect(state.latestAttempt == updated, "updated row should become latest")
    }

    private static func makeAttempt(
        id: UUID = UUID(),
        createdAt: Date = Date(timeIntervalSince1970: 1),
        updatedAt: Date = Date(timeIntervalSince1970: 1),
        selectedPageIndicesText: String = "0",
        status: String = ExamAttemptStatus.inProgress.rawValue
    ) -> ExamAttemptHistoryRowData {
        ExamAttemptHistoryRowData(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            selectedPageIndicesText: selectedPageIndicesText,
            status: status
        )
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError(message, file: file, line: line)
        }
    }
}
