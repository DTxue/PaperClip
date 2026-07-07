import Foundation

extension VocabularySchedulingCore {
    static func nextMemoryState(
        stability: Double,
        difficulty: Double,
        elapsedDays: Double,
        rating: Int,
        parameters w: [Double]
    ) -> (stability: Double, difficulty: Double) {
        if stability == 0, difficulty == 0 {
            return (
                max(w[rating - 1], 0.1),
                initialDifficulty(rating: rating, parameters: w)
            )
        }

        let retrievability = forgettingCurve(
            elapsedDays: elapsedDays,
            stability: stability,
            parameters: w
        )
        let nextDifficulty = nextDifficulty(
            difficulty: difficulty,
            rating: rating,
            parameters: w
        )

        if elapsedDays == 0 {
            let gradeTerm = Double(rating - 3) + w[18]
            let increase = pow(stability, -w[19]) * exp(w[17] * gradeTerm)
            let boundedIncrease = rating >= 2 ? max(increase, 1) : increase
            return (
                clamp(stability * boundedIncrease, minimumStability, 36_500),
                nextDifficulty
            )
        }

        if rating == 1 {
            let failureStability = w[11]
                * pow(difficulty, -w[12])
                * (pow(stability + 1, w[13]) - 1)
                * exp(w[14] * (1 - retrievability))
            let shortTermBound = stability / exp(w[17] * w[18])
            return (
                clamp(shortTermBound, minimumStability, failureStability),
                nextDifficulty
            )
        }

        let hardPenalty = rating == 2 ? w[15] : 1
        let easyBonus = rating == 4 ? w[16] : 1
        let recallStability = stability * (
            1
            + exp(w[8])
            * (11 - difficulty)
            * pow(stability, -w[9])
            * (exp((1 - retrievability) * w[10]) - 1)
            * hardPenalty
            * easyBonus
        )
        return (
            clamp(recallStability, minimumStability, 36_500),
            nextDifficulty
        )
    }

    static func initialDifficulty(rating: Int, parameters w: [Double]) -> Double {
        clamp(w[4] - exp(Double(rating - 1) * w[5]) + 1, 1, 10)
    }

    static func nextDifficulty(
        difficulty: Double,
        rating: Int,
        parameters w: [Double]
    ) -> Double {
        let delta = -w[6] * Double(rating - 3)
        let dampedDelta = delta * (10 - difficulty) / 9
        let next = difficulty + dampedDelta
        let rawEasyDifficulty = w[4] - exp(3 * w[5]) + 1
        return clamp(w[7] * rawEasyDifficulty + (1 - w[7]) * next, 1, 10)
    }

}
