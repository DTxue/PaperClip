import Foundation

@main
enum MistakeLibrarySupportTests {
    static func main() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let dueMath = MistakeLibraryItem(
            subject: Subject.math.rawValue,
            status: .learning,
            isFavorite: true,
            nextReviewAt: now
        )
        let futureChinese = MistakeLibraryItem(
            subject: Subject.chinese.rawValue,
            status: .learning,
            nextReviewAt: now.addingTimeInterval(86_400)
        )
        let archivedMath = MistakeLibraryItem(
            subject: Subject.math.rawValue,
            status: .archived
        )
        let inboxEnglish = MistakeLibraryItem(
            subject: Subject.english.rawValue,
            status: .inbox
        )
        let masteredPhysics = MistakeLibraryItem(
            subject: Subject.physics.rawValue,
            status: .mastered
        )
        let items = [dueMath, futureChinese, archivedMath, inboxEnglish, masteredPhysics]

        let dueFolders = MistakeLibraryOrganizer.folders(for: items, matching: .due, now: now)
        expect(folder(Subject.math.rawValue, in: dueFolders).count == 1, "due folder counts due math items")
        expect(folder(Subject.chinese.rawValue, in: dueFolders).count == 0, "due folder excludes future reviews")
        expect(dueFolders.count == Subject.allCases.count, "every filter shows every subject folder")

        let allFolders = MistakeLibraryOrganizer.folders(for: items, matching: .all, now: now)
        expect(folder(Subject.math.rawValue, in: allFolders).count == 1, "all excludes archived mistakes")
        expect(folder(Subject.chinese.rawValue, in: allFolders).count == 1, "all groups active mistakes by subject")

        let archivedFolders = MistakeLibraryOrganizer.folders(for: items, matching: .archived, now: now)
        expect(folder(Subject.math.rawValue, in: archivedFolders).count == 1, "archived has its own subject counts")
        let favoriteFolders = MistakeLibraryOrganizer.folders(for: items, matching: .favorites, now: now)
        expect(folder(Subject.math.rawValue, in: favoriteFolders).count == 1, "favorites has subject counts")
        let inboxFolders = MistakeLibraryOrganizer.folders(for: items, matching: .inbox, now: now)
        expect(folder(Subject.english.rawValue, in: inboxFolders).count == 1, "inbox has subject counts")
        let learningFolders = MistakeLibraryOrganizer.folders(for: items, matching: .learning, now: now)
        expect(folder(Subject.chinese.rawValue, in: learningFolders).count == 1, "learning has subject counts")
        let masteredFolders = MistakeLibraryOrganizer.folders(for: items, matching: .mastered, now: now)
        expect(folder(Subject.physics.rawValue, in: masteredFolders).count == 1, "mastered has subject counts")
        expect(
            MistakeLibraryFilter.allCases.filter(\.usesSubjectFolders).count == 7,
            "the seven active library pages use subject folders"
        )

        let parsed = MistakeErrorReasonDraft.parse("粗心，计算错误,自定义原因")
        expect(parsed.selected == ["粗心", "计算错误"], "known reasons become selected tags")
        expect(parsed.custom == "自定义原因", "unknown reasons remain editable")
        expect(
            MistakeErrorReasonDraft.storedValue(
                selected: ["计算错误", "粗心"],
                custom: "自定义原因"
            ) == "粗心,计算错误,自定义原因",
            "reason tags serialize in a stable order"
        )

        print("MistakeLibrarySupportTests: 14 passed")
    }

    private static func folder(
        _ subject: String,
        in folders: [MistakeSubjectFolderSummary]
    ) -> MistakeSubjectFolderSummary {
        guard let folder = folders.first(where: { $0.subject == subject }) else {
            fatalError("missing subject folder: \(subject)")
        }
        return folder
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
