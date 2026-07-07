import Foundation

struct VocabularyImportSummary: Equatable {
    let totalCount: Int
    let validCount: Int
    let failedCount: Int

    init(result: VocabularyImportResult) {
        let validCount = result.rows.reduce(0) { count, row in
            row.isValid ? count + 1 : count
        }
        self.init(totalCount: result.rows.count, validCount: validCount)
    }

    init(totalCount: Int, validCount: Int) {
        self.totalCount = totalCount
        self.validCount = validCount
        self.failedCount = max(totalCount - validCount, 0)
    }

    var hasValidRows: Bool {
        validCount > 0
    }

    func createConfirmTitle() -> String {
        "创建并导入 \(validCount) 项"
    }

    func importConfirmTitle() -> String {
        "导入 \(validCount) 项"
    }

    func canCreateDeck(title: String) -> Bool {
        hasValidRows && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct VocabularyImportProjection {
    let validRows: [VocabularyImportRow]
    let summary: VocabularyImportSummary

    init(result: VocabularyImportResult) {
        var validRows: [VocabularyImportRow] = []
        validRows.reserveCapacity(result.rows.count)
        for row in result.rows where row.isValid {
            validRows.append(row)
        }
        self.validRows = validRows
        self.summary = VocabularyImportSummary(
            totalCount: result.rows.count,
            validCount: validRows.count
        )
    }
}
