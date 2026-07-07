import Foundation

struct SubjectLibraryCardData: Identifiable, Equatable {
    let subject: Subject
    let paperCount: Int
    let mistakeCount: Int

    var id: String { subject.rawValue }
    var title: String { subject.rawValue }
    var icon: String { subject.sfSymbol }
}

enum SubjectLibraryPaperStatistics {
    static func countBySubject(_ papers: [PDFDocumentItem]) -> [String: Int] {
        var counts: [String: Int] = [:]
        counts.reserveCapacity(Subject.allCases.count)
        for paper in papers {
            counts[paper.subject, default: 0] += 1
        }
        return counts
    }
}

struct SubjectLibraryMistakeStatistics {
    let countBySubject: [String: Int]
    let masterySummary: MasteryStatusSummary
    let todayCount: Int

    init(cards: [MistakeCard], calendar: Calendar, now: Date) {
        var counts: [String: Int] = [:]
        counts.reserveCapacity(Subject.allCases.count)

        var masteryCounter = MasteryStatusCounter()
        var todayCount = 0
        let startOfToday = calendar.startOfDay(for: now)

        for card in cards {
            counts[card.subject, default: 0] += 1
            masteryCounter.add(card.status)
            if card.createdAt >= startOfToday {
                todayCount += 1
            }
        }

        self.countBySubject = counts
        self.masterySummary = masteryCounter.summary
        self.todayCount = todayCount
    }
}
