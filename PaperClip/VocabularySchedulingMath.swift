import Foundation

extension VocabularySchedulingCore {
    static func forgettingCurve(
        elapsedDays: Double,
        stability: Double,
        parameters w: [Double]
    ) -> Double {
        pow(1 + retentionFactor(parameters: w) * elapsedDays / stability, schedulingDecay(parameters: w))
    }

    static func retentionIntervalModifier(
        retention: Double,
        parameters w: [Double]
    ) -> Double {
        let decay = schedulingDecay(parameters: w)
        return (pow(retention, 1 / decay) - 1) / retentionFactor(parameters: w)
    }

    static func validatedParameters(_ parameters: [Double]) -> [Double] {
        parameters.count == 21 ? parameters : defaultParameters
    }

    static func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }

    private static func schedulingDecay(parameters w: [Double]) -> Double {
        -w[20]
    }

    private static func retentionFactor(parameters w: [Double]) -> Double {
        exp(log(0.9) / schedulingDecay(parameters: w)) - 1
    }
}
