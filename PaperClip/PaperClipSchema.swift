import Foundation
import SwiftData

extension PaperClipSchemaV6: VersionedSchema {
    static let versionIdentifier = Schema.Version(6, 0, 0)

    static let models: [any PersistentModel.Type] = [
        VocabularyFolder.self,
        VocabularyDeck.self,
        VocabularyCard.self,
        VocabularyMemoryState.self,
        VocabularyReviewLog.self,
        VocabularyStudySession.self,
        VocabularyTestDraft.self,
        VocabularyHandwritingAttempt.self,
        VocabularyImportBatch.self,
        VocabularyDistractorCache.self,
        DiaryEntry.self,
        KnowledgeItem.self
    ]
}

enum PaperClipStore {
    static func makeContainer(
        at url: URL? = nil,
        isStoredInMemoryOnly: Bool = false
    ) throws -> ModelContainer {
        precondition(url == nil || !isStoredInMemoryOnly)

        do {
            return try makeCurrentContainer(at: url, isStoredInMemoryOnly: isStoredInMemoryOnly)
        } catch let currentSchemaError {
            guard !isStoredInMemoryOnly else { throw currentSchemaError }

            // Stores created before PaperClip adopted VersionedSchema have no
            // version checksum. Opening once with V1 lets SwiftData perform its
            // inferred migration and stamp the store before the staged V2 move.
            do {
                let legacyContainer = try makeLegacyV1Container(at: url)
                withExtendedLifetime(legacyContainer) {}
            } catch {
                throw currentSchemaError
            }
            return try makeCurrentContainer(at: url, isStoredInMemoryOnly: false)
        }
    }

    private static func makeCurrentContainer(
        at url: URL?,
        isStoredInMemoryOnly: Bool
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: PaperClipSchemaV6.self)
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(
                "PaperClip",
                schema: schema,
                url: url
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: isStoredInMemoryOnly
            )
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: PaperClipMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func makeLegacyV1Container(at url: URL?) throws -> ModelContainer {
        let schema = Schema(versionedSchema: PaperClipSchemaV1.self)
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(
                "PaperClip",
                schema: schema,
                url: url
            )
        } else {
            configuration = ModelConfiguration(schema: schema)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
