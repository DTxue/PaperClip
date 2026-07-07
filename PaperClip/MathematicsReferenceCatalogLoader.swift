import Foundation

enum MathematicsReferenceError: LocalizedError, Equatable {
    case resourceMissing
    case unsupportedSchema(Int)
    case invalidMetadata
    case invalidEntry(String)

    var errorDescription: String? {
        switch self {
        case .resourceMissing:
            "找不到内置数学教材数据。"
        case .unsupportedSchema(let version):
            "不支持数学教材数据格式版本 \(version)。"
        case .invalidMetadata:
            "数学教材数据的学科或版本信息无效。"
        case .invalidEntry(let location):
            "数学教材数据在 \(location) 存在无效条目。"
        }
    }
}

enum MathematicsReferenceCatalogLoader {
    static func load(
        from bundle: Bundle = .main,
        resourceName: String = "suke-math-2026"
    ) throws -> MathematicsReferenceCatalog {
        guard let url = bundle.url(
            forResource: resourceName,
            withExtension: "json",
            subdirectory: "Curriculum"
        ) ?? bundle.url(forResource: resourceName, withExtension: "json") else {
            throw MathematicsReferenceError.resourceMissing
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> MathematicsReferenceCatalog {
        let catalog = try JSONDecoder().decode(
            MathematicsReferenceCatalog.self,
            from: data
        )
        try validate(catalog)
        return catalog
    }

    private static func validate(_ catalog: MathematicsReferenceCatalog) throws {
        guard catalog.schemaVersion == 1 else {
            throw MathematicsReferenceError.unsupportedSchema(catalog.schemaVersion)
        }
        guard
            catalog.subject == "数学",
            !catalog.id.isEmpty,
            !catalog.contentVersion.isEmpty,
            !catalog.publisher.isEmpty
        else {
            throw MathematicsReferenceError.invalidMetadata
        }

        for section in catalog.sections {
            try validate(section)
        }
    }

    private static func validate(_ section: MathematicsReferenceCatalog.Section) throws {
        guard
            ["七年级", "八年级", "九年级"].contains(section.grade),
            ["上学期", "下学期"].contains(section.semester)
        else {
            throw MathematicsReferenceError.invalidMetadata
        }
        for chapter in section.chapters {
            try validate(chapter, location: "\(section.grade) \(section.semester)")
        }
    }

    private static func validate(
        _ chapter: MathematicsReferenceCatalog.Chapter,
        location: String
    ) throws {
        guard !chapter.title.isEmpty else {
            throw MathematicsReferenceError.invalidEntry(location)
        }
        for entry in chapter.entries where
            entry.count != 2 || entry[0].isEmpty || entry[1].isEmpty
        {
            throw MathematicsReferenceError.invalidEntry(chapter.title)
        }
    }
}
