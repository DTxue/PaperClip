import Foundation
import SwiftData

struct SubjectLibrarySnapshot {
    static var paperCountPropertiesToFetch: [PartialKeyPath<PDFDocumentItem>] {
        [\.subject]
    }

    static var mistakeAggregatePropertiesToFetch: [PartialKeyPath<MistakeCard>] {
        [\.subject, \.status, \.createdAt]
    }

    let visibleSubjects: [Subject]
    let masterySummary: MasteryStatusSummary
    let paperCountBySubject: [String: Int]
    let mistakeCountBySubject: [String: Int]
    let todayCount: Int

    var subjectCards: [SubjectLibraryCardData] {
        visibleSubjects.map { subject in
            let subjectName = subject.rawValue
            return SubjectLibraryCardData(
                subject: subject,
                paperCount: paperCountBySubject[subjectName, default: 0],
                mistakeCount: mistakeCountBySubject[subjectName, default: 0]
            )
        }
    }

    static let empty = SubjectLibrarySnapshot(
        visibleSubjects: [],
        masterySummary: .empty,
        paperCountBySubject: [:],
        mistakeCountBySubject: [:],
        todayCount: 0
    )

    static func load(
        preferredSubjectsRaw: String,
        modelContext: ModelContext,
        calendar: Calendar = .current,
        now: Date = .now
    ) throws -> SubjectLibrarySnapshot {
        let papers = try modelContext.fetchPDFDocuments(
            subject: nil,
            propertiesToFetch: paperCountPropertiesToFetch
        )
        let cards = try modelContext.fetchMistakeCards(
            subject: nil,
            propertiesToFetch: mistakeAggregatePropertiesToFetch
        )
        let paperCountBySubject = SubjectLibraryPaperStatistics.countBySubject(papers)
        let mistakeStats = SubjectLibraryMistakeStatistics(cards: cards, calendar: calendar, now: now)

        return SubjectLibrarySnapshot(
            visibleSubjects: visibleSubjects(
                preferredSubjectsRaw: preferredSubjectsRaw,
                paperCountBySubject: paperCountBySubject,
                mistakeCountBySubject: mistakeStats.countBySubject
            ),
            masterySummary: mistakeStats.masterySummary,
            paperCountBySubject: paperCountBySubject,
            mistakeCountBySubject: mistakeStats.countBySubject,
            todayCount: mistakeStats.todayCount
        )
    }

    private static func visibleSubjects(
        preferredSubjectsRaw: String,
        paperCountBySubject: [String: Int],
        mistakeCountBySubject: [String: Int]
    ) -> [Subject] {
        var activeSubjects = PreferredSubjects.parseSet(preferredSubjectsRaw)
        for subject in Subject.allCases {
            let subjectName = subject.rawValue
            if paperCountBySubject[subjectName, default: 0] > 0
                || mistakeCountBySubject[subjectName, default: 0] > 0 {
                activeSubjects.insert(subjectName)
            }
        }
        return Subject.allCases.filter { activeSubjects.contains($0.rawValue) }
    }
}
