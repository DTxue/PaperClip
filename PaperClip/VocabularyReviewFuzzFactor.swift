import Foundation

enum VocabularyReviewFuzzFactor {
    static func factor(
        cardID: UUID,
        direction: VocabularyDirection,
        reviewCount: Int
    ) -> Double {
        var hash: UInt64 = 14_695_981_039_346_656_037
        withUnsafeBytes(of: cardID.uuid) { bytes in
            for byte in bytes {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
        }
        for byte in direction.rawValue.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        hash ^= UInt64(max(0, reviewCount))
        hash &*= 1_099_511_628_211
        return Double(hash % 1_000_000) / 1_000_000
    }
}
