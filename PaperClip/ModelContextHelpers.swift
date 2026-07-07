import SwiftData

extension ModelContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }

    func saveOrRollbackIfNeeded() throws {
        do {
            try saveIfNeeded()
        } catch {
            rollback()
            throw error
        }
    }

    @discardableResult
    func deleteFetched<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) throws -> Int {
        var deletedCount = 0
        for model in try fetch(descriptor) {
            delete(model)
            deletedCount += 1
        }
        return deletedCount
    }

    @discardableResult
    func deleteFetched<Model: PersistentModel>(
        _ descriptor: FetchDescriptor<Model>,
        fetching propertiesToFetch: [PartialKeyPath<Model>]
    ) throws -> Int {
        var descriptor = descriptor
        descriptor.propertiesToFetch = propertiesToFetch
        return try deleteFetched(descriptor)
    }

    func deleteMatching<Model: PersistentModel>(
        _ models: [Model],
        where shouldDelete: (Model) -> Bool
    ) {
        for model in models where shouldDelete(model) {
            delete(model)
        }
    }

    func fetchFirst<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) throws -> Model? {
        var descriptor = descriptor
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    func fetchConfigured<Model: PersistentModel>(
        _ descriptor: FetchDescriptor<Model>,
        limit: Int? = nil,
        propertiesToFetch: [PartialKeyPath<Model>] = []
    ) throws -> [Model] {
        var descriptor = descriptor
        if let limit {
            descriptor.fetchLimit = limit
        }
        descriptor.propertiesToFetch = propertiesToFetch
        return try fetch(descriptor)
    }
}
