import Foundation

extension AIWritingReviewResult {
    struct CoreSceneUpgrade: Codable, Sendable {
        struct DetailAdvice: Codable, Sendable {
            let detailType: String
            let specificAdvice: String

            private enum CodingKeys: String, CodingKey {
                case detailType, specificAdvice
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                detailType = container.decodeString(.detailType)
                specificAdvice = container.decodeString(.specificAdvice)
            }
        }

        struct MethodBreakdown: Codable, Sendable {
            let method: String
            let exampleFromRewrite: String
            let effect: String

            private enum CodingKeys: String, CodingKey {
                case method, exampleFromRewrite, effect
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                method = container.decodeString(.method)
                exampleFromRewrite = container.decodeString(.exampleFromRewrite)
                effect = container.decodeString(.effect)
            }
        }

        let selectedScene: String
        let whySelected: String
        let originalProblem: String
        let detailsToAdd: [DetailAdvice]
        let highScoreRewrite: String
        let methodBreakdown: [MethodBreakdown]
        let studentCanImitateBy: [String]

        private enum CodingKeys: String, CodingKey {
            case selectedScene, whySelected, originalProblem, detailsToAdd, highScoreRewrite, methodBreakdown, studentCanImitateBy
        }

        init() {
            selectedScene = ""
            whySelected = ""
            originalProblem = ""
            detailsToAdd = []
            highScoreRewrite = ""
            methodBreakdown = []
            studentCanImitateBy = []
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            selectedScene = container.decodeString(.selectedScene)
            whySelected = container.decodeString(.whySelected)
            originalProblem = container.decodeString(.originalProblem)
            detailsToAdd = container.decodeArray([DetailAdvice].self, .detailsToAdd)
            highScoreRewrite = container.decodeString(.highScoreRewrite)
            methodBreakdown = container.decodeArray([MethodBreakdown].self, .methodBreakdown)
            studentCanImitateBy = container.decodeStringArray(.studentCanImitateBy)
        }
    }
}
