import Foundation
import SwiftData

@main
struct SubjectLibrarySnapshotTests {
    @MainActor
    static func main() throws {
        let schema = Schema([
            PDFDocumentItem.self,
            MistakeCard.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        expect(SubjectLibrarySnapshot.paperCountPropertiesToFetch.count == 1)
        expect(SubjectLibrarySnapshot.mistakeAggregatePropertiesToFetch.count == 3)

        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_735_689_600)
        let yesterday = try require(calendar.date(byAdding: .day, value: -1, to: now))

        context.insert(PDFDocumentItem(
            title: "数学试卷",
            localFileName: "math.pdf",
            grade: "七年级",
            semester: "上学期",
            subject: Subject.math.rawValue
        ))
        context.insert(MistakeCard(
            imageFileName: "physics.jpg",
            originalWidth: 100,
            originalHeight: 50,
            subject: Subject.physics.rawValue,
            status: MasteryStatus.review.rawValue,
            createdAt: now
        ))
        context.insert(MistakeCard(
            imageFileName: "english.jpg",
            originalWidth: 100,
            originalHeight: 50,
            subject: Subject.english.rawValue,
            status: MasteryStatus.mastered.rawValue,
            createdAt: yesterday
        ))
        try context.save()

        let snapshot = try SubjectLibrarySnapshot.load(
            preferredSubjectsRaw: Subject.chemistry.rawValue,
            modelContext: context,
            calendar: calendar,
            now: now
        )

        expect(snapshot.visibleSubjects == [
            .math,
            .english,
            .physics,
            .chemistry
        ])
        expect(snapshot.paperCountBySubject[Subject.math.rawValue] == 1)
        expect(snapshot.mistakeCountBySubject[Subject.physics.rawValue] == 1)
        expect(snapshot.subjectCards.map(\.subject) == snapshot.visibleSubjects)
        expect(snapshot.subjectCards.map(\.paperCount) == [1, 0, 0, 0])
        expect(snapshot.subjectCards.map(\.mistakeCount) == [0, 1, 1, 0])
        expect(snapshot.masterySummary.total == 2)
        expect(snapshot.masterySummary.mastered == 1)
        expect(snapshot.masterySummary.review == 1)
        expect(snapshot.todayCount == 1)

        let documentRow = try require(try context.fetchPDFDocumentRows(subject: Subject.math.rawValue).first)
        expect(documentRow.matchesSearch("数学"))
        expect(documentRow.matchesSearch("试卷"))
        expect(!documentRow.matchesSearch("英语"))
        expect(documentRow.metadataText == "七年级 · 上学期 · 数学")
        expect(documentRow.matchesFilters(selectedGrade: "七年级", selectedSemester: "上学期"))
        expect(!documentRow.matchesFilters(selectedGrade: "八年级", selectedSemester: "上学期"))
        expect(!documentRow.matchesFilters(selectedGrade: "七年级", selectedSemester: "下学期"))

        let filteredSnapshot = SubjectDocumentSnapshot(
            documents: [documentRow],
            searchText: "数学",
            selectedGrade: "七年级",
            selectedSemester: "上学期"
        )
        expect(filteredSnapshot.filteredDocuments == [documentRow])

        print("SubjectLibrarySnapshotTests: 21 passed")
    }

    private static func require<T>(_ value: T?) throws -> T {
        guard let value else {
            throw CocoaError(.coderInvalidValue)
        }
        return value
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
