import Foundation

extension AIWritingReviewResult {
    struct ParagraphReconstruction: Codable, Identifiable, Sendable {
        var id: String { section + highScoreRewrite }
        let section: String
        let relatedOriginalParagraphs: String
        let extractedContent: String
        let writingFunction: String
        let currentProblem: String
        let keepMaterial: String
        let compressOrMergeMaterial: String
        let expandMaterial: String
        let rewriteStrategy: String
        let highScoreRewrite: String
        let whyThisRewriteIsBetter: String
        let studentCanLearn: String

        private enum CodingKeys: String, CodingKey {
            case section, relatedOriginalParagraphs, extractedContent, writingFunction, currentProblem
            case keepMaterial, compressOrMergeMaterial, expandMaterial, rewriteStrategy, highScoreRewrite
            case whyThisRewriteIsBetter, studentCanLearn
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            section = container.decodeString(.section)
            relatedOriginalParagraphs = container.decodeString(.relatedOriginalParagraphs)
            extractedContent = container.decodeString(.extractedContent)
            writingFunction = container.decodeString(.writingFunction)
            currentProblem = container.decodeString(.currentProblem)
            keepMaterial = container.decodeString(.keepMaterial)
            compressOrMergeMaterial = container.decodeString(.compressOrMergeMaterial)
            expandMaterial = container.decodeString(.expandMaterial)
            rewriteStrategy = container.decodeString(.rewriteStrategy)
            highScoreRewrite = container.decodeString(.highScoreRewrite)
            whyThisRewriteIsBetter = container.decodeString(.whyThisRewriteIsBetter)
            studentCanLearn = container.decodeString(.studentCanLearn)
        }
    }

    struct RevisedStructurePlan: Codable, Identifiable, Sendable {
        var id: String { part + content }
        let part: String
        let content: String
        let lengthAdvice: String
        let purpose: String

        private enum CodingKeys: String, CodingKey {
            case part, content, lengthAdvice, purpose
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            part = container.decodeString(.part)
            content = container.decodeString(.content)
            lengthAdvice = container.decodeString(.lengthAdvice)
            purpose = container.decodeString(.purpose)
        }
    }

    struct StudentRevisionTask: Codable, Identifiable, Sendable {
        var id: String { task + targetParagraph }
        let task: String
        let targetParagraph: String
        let instruction: String
        let example: String
        let purpose: String

        private enum CodingKeys: String, CodingKey {
            case task, targetParagraph, instruction, example, purpose
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            task = container.decodeString(.task)
            targetParagraph = container.decodeString(.targetParagraph)
            instruction = container.decodeString(.instruction)
            example = container.decodeString(.example)
            purpose = container.decodeString(.purpose)
        }
    }
}
