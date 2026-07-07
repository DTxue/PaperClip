import Foundation

enum MathematicsReferenceKind: String, Codable, Equatable {
    case knowledgePoints
    case formulas
}

struct MathematicsReferenceChapter: Identifiable {
    let title: String
    let entries: [MathematicsReferenceEntry]

    var id: String { title }
}

struct MathematicsReferenceEntry: Identifiable {
    let title: String
    let detail: String

    var id: String { "\(title)|\(detail)" }
}

struct MathematicsReferenceCatalog: Decodable {
    let schemaVersion: Int
    let contentVersion: String
    let id: String
    let subject: String
    let publisher: String
    let edition: String
    let verifiedAt: String
    let sections: [Section]

    struct Section: Decodable {
        let grade: String
        let semester: String
        let kind: MathematicsReferenceKind
        let chapters: [Chapter]
    }

    struct Chapter: Decodable {
        let title: String
        let entries: [[String]]
    }

    func chapters(
        grade: String,
        semester: String,
        kind: MathematicsReferenceKind
    ) -> [MathematicsReferenceChapter] {
        guard let section = sections.first(where: {
            $0.grade == grade
                && $0.semester == semester
                && $0.kind == kind
        }) else {
            return []
        }

        return section.chapters.map { chapter in
            MathematicsReferenceChapter(
                title: chapter.title,
                entries: chapter.entries.compactMap { fields in
                    guard fields.count == 2 else { return nil }
                    return MathematicsReferenceEntry(
                        title: fields[0],
                        detail: fields[1]
                    )
                }
            )
        }
    }
}
