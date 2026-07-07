import Foundation

struct VocabularyImportResult {
    let format: VocabularyTextFormat
    let rows: [VocabularyImportRow]

    var validRows: [VocabularyImportRow] {
        rows.filter(\.isValid)
    }

    var summary: VocabularyImportSummary {
        VocabularyImportSummary(result: self)
    }

    var projection: VocabularyImportProjection {
        VocabularyImportProjection(result: self)
    }
}
