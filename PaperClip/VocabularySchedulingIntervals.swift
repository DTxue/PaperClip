import Foundation

extension VocabularySchedulingCore {
    static func nextIntervalDays(
        stability: Double,
        elapsedDays: Double,
        desiredRetention: Double,
        maximumIntervalDays: Double,
        fuzzFactor: Double,
        parameters w: [Double]
    ) -> Double {
        let retention = clamp(desiredRetention, 0.75, 0.99)
        let modifier = retentionIntervalModifier(retention: retention, parameters: w)
        let rawInterval = min(
            max(1, (stability * modifier).rounded()),
            max(1, maximumIntervalDays)
        )
        return fuzzedInterval(
            rawInterval,
            elapsedDays: elapsedDays,
            maximumIntervalDays: maximumIntervalDays,
            fuzzFactor: fuzzFactor
        )
    }

    static func orderedReviewInterval(
        selectedRating: Int,
        stability: Double,
        difficulty: Double,
        elapsedDays: Double,
        desiredRetention: Double,
        maximumIntervalDays: Double,
        fuzzFactor: Double,
        parameters w: [Double]
    ) -> Double {
        func interval(_ rating: Int) -> Double {
            let state = nextMemoryState(
                stability: stability,
                difficulty: difficulty,
                elapsedDays: elapsedDays,
                rating: rating,
                parameters: w
            )
            return nextIntervalDays(
                stability: state.stability,
                elapsedDays: elapsedDays,
                desiredRetention: desiredRetention,
                maximumIntervalDays: maximumIntervalDays,
                fuzzFactor: fuzzFactor,
                parameters: w
            )
        }

        var hard = interval(2)
        var good = interval(3)
        hard = min(hard, good)
        good = max(good, hard + 1)
        let easy = max(interval(4), good + 1)

        switch selectedRating {
        case 2: return hard
        case 4: return easy
        default: return good
        }
    }

    static func fuzzedInterval(
        _ interval: Double,
        elapsedDays: Double,
        maximumIntervalDays: Double,
        fuzzFactor: Double
    ) -> Double {
        guard interval >= 2.5 else { return interval.rounded() }

        let bounded = min(interval, maximumIntervalDays)
        let delta = intervalFuzzDelta(for: interval)
        var minimum = max(2, (bounded - delta).rounded())
        let maximum = min((bounded + delta).rounded(), maximumIntervalDays)
        if bounded > elapsedDays {
            minimum = max(minimum, elapsedDays + 1)
        }
        minimum = min(minimum, maximum)

        let normalizedFuzz = clamp(fuzzFactor, 0, 0.999_999_999)
        return floor(normalizedFuzz * (maximum - minimum + 1) + minimum)
    }

    private static func intervalFuzzDelta(for interval: Double) -> Double {
        let ranges: [(start: Double, end: Double, factor: Double)] = [
            (2.5, 7, 0.15),
            (7, 20, 0.10),
            (20, .infinity, 0.05)
        ]
        return ranges.reduce(1.0) { delta, range in
            delta + range.factor * max(min(interval, range.end) - range.start, 0)
        }
    }
}
