import Foundation

@main
struct MathematicsReferenceTests {
    static func main() throws {
        let url = URL(fileURLWithPath: "PaperClip/Resources/Curriculum/suke-math-2026.json")
        let catalog = try MathematicsReferenceCatalogLoader.decode(Data(contentsOf: url))

        expect(catalog.schemaVersion == 1)
        expect(catalog.contentVersion == "2026.1")
        expect(catalog.sections.count == 12)

        for grade in ["七年级", "八年级", "九年级"] {
            for semester in ["上学期", "下学期"] {
                for kind in [MathematicsReferenceKind.knowledgePoints, .formulas] {
                    let chapters = catalog.chapters(
                        grade: grade,
                        semester: semester,
                        kind: kind
                    )
                    expect(!chapters.isEmpty)
                    expect(chapters.allSatisfy { !$0.entries.isEmpty })
                }
            }
        }

        let entryCount = catalog.sections
            .flatMap(\.chapters)
            .flatMap(\.entries)
            .count
        expect(entryCount == 243)
        try testInvalidCatalogs()

        print("MathematicsReferenceTests: 32 passed")
    }

    private static func testInvalidCatalogs() throws {
        expectThrows(MathematicsReferenceError.unsupportedSchema(2)) {
            _ = try MathematicsReferenceCatalogLoader.decode(catalogData(schemaVersion: 2))
        }
        expectThrows(MathematicsReferenceError.invalidMetadata) {
            _ = try MathematicsReferenceCatalogLoader.decode(catalogData(subject: "物理"))
        }
        expectThrows(MathematicsReferenceError.invalidMetadata) {
            _ = try MathematicsReferenceCatalogLoader.decode(catalogData(grade: "高一"))
        }
        expectThrows(MathematicsReferenceError.invalidEntry("第一章")) {
            _ = try MathematicsReferenceCatalogLoader.decode(catalogData(entry: ["概念"]))
        }
    }

    private static func catalogData(
        schemaVersion: Int = 1,
        subject: String = "数学",
        grade: String = "七年级",
        entry: [String] = ["有理数", "整数和分数统称为有理数。"]
    ) -> Data {
        let entryJSON = entry.map { "\"\($0)\"" }.joined(separator: ", ")
        return """
        {
          "schemaVersion": \(schemaVersion),
          "contentVersion": "2026.1",
          "id": "test-math",
          "subject": "\(subject)",
          "publisher": "苏科版",
          "edition": "2026",
          "verifiedAt": "2026-01-01",
          "sections": [
            {
              "grade": "\(grade)",
              "semester": "上学期",
              "kind": "knowledgePoints",
              "chapters": [
                {
                  "title": "第一章",
                  "entries": [[\(entryJSON)]]
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!
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

    private static func expectThrows(
        _ expected: MathematicsReferenceError,
        _ operation: () throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            try operation()
            fatalError("Expected error", file: file, line: line)
        } catch let error as MathematicsReferenceError {
            expect(error == expected, file: file, line: line)
        } catch {
            fatalError("Unexpected error", file: file, line: line)
        }
    }
}
