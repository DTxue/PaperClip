import Foundation

enum VocabularyMemoryRetrievability {
    static func current(
        state: VocabularyMemoryState,
        now: Date = .now,
        parameters: [Double] = VocabularySchedulingCore.defaultParameters
    ) -> Double {
        VocabularySchedulingCore.retrievability(
            stability: state.stability,
            elapsedDays: elapsedDays(from: state.lastReviewDate, to: now),
            parameters: parameters
        )
    }

    static func current(
        state: VocabularyMemoryState,
        deck: VocabularyDeck,
        now: Date = .now
    ) -> Double {
        current(
            state: state,
            now: now,
            parameters: parameters(for: deck)
        )
    }

    static func parameters(for deck: VocabularyDeck) -> [Double] {
        guard
            !deck.fsrsParametersJSON.isEmpty,
            let values = VocabularyJSONStorage.decodeOptional(
                [Double].self,
                from: deck.fsrsParametersJSON
            ),
            values.count == 21
        else {
            return VocabularySchedulingCore.defaultParameters
        }
        return values
    }

    static func elapsedDays(from lastReview: Date?, to now: Date) -> Double {
        guard let lastReview else { return 0 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent
        let start = calendar.startOfDay(for: lastReview)
        let end = calendar.startOfDay(for: now)
        return max(0, floor(end.timeIntervalSince(start) / 86_400))
    }
}
