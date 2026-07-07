import Foundation

/// 从应用 Bundle 中读取版本化教材 JSON。内容与展示逻辑分离，后续校订
/// 只需修改 Resources/Curriculum/suke-math-2026.json。
enum MathematicsReference {
    static let result: Result<MathematicsReferenceCatalog, Error> = {
        do {
            return .success(try load())
        } catch {
            return .failure(error)
        }
    }()

    static var catalog: MathematicsReferenceCatalog? {
        try? result.get()
    }

    static var loadingError: Error? {
        guard case .failure(let error) = result else { return nil }
        return error
    }

    static func load(
        from bundle: Bundle = .main,
        resourceName: String = "suke-math-2026"
    ) throws -> MathematicsReferenceCatalog {
        try MathematicsReferenceCatalogLoader.load(
            from: bundle,
            resourceName: resourceName
        )
    }

    static func decode(_ data: Data) throws -> MathematicsReferenceCatalog {
        try MathematicsReferenceCatalogLoader.decode(data)
    }

    static func chapters(
        grade: String,
        semester: String,
        kind: MathematicsReferenceKind
    ) -> [MathematicsReferenceChapter] {
        catalog?.chapters(grade: grade, semester: semester, kind: kind) ?? []
    }
}
