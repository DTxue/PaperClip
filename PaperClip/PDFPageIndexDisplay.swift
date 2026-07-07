import Foundation

enum PDFPageIndexDisplay {
    static func userPageNumber(forZeroBasedIndex index: Int) -> Int {
        index + 1
    }

    static func pageTitle(forZeroBasedIndex index: Int) -> String {
        "第 \(userPageNumber(forZeroBasedIndex: index)) 页"
    }

    static func selectionAccessibilityLabel(
        zeroBasedIndex index: Int,
        isSelected: Bool,
        supplementTitle: String? = nil
    ) -> String {
        var parts = [
            pageTitle(forZeroBasedIndex: index),
            isSelected ? "已选择" : "未选择"
        ]
        if let supplementTitle, !supplementTitle.isEmpty {
            parts.append(supplementTitle)
        }
        return parts.joined(separator: "，")
    }

    static func parseStoredIndices(_ text: String) -> [Int] {
        text
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    static func serializeStoredIndices(_ indices: [Int]) -> String {
        indices.map(String.init).joined(separator: ",")
    }

    static func userPageNumbers(forZeroBasedIndices indices: [Int]) -> [Int] {
        indices.map(userPageNumber(forZeroBasedIndex:))
    }

    static func summary(_ userPageNumbers: [Int], limit: Int = 6) -> String {
        guard !userPageNumbers.isEmpty else { return "无页面" }
        let visiblePages = userPageNumbers.prefix(limit).map(String.init).joined(separator: "、")
        return userPageNumbers.count <= limit ? visiblePages : visiblePages + "..."
    }
}
