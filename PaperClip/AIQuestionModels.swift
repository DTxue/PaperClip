import Foundation

struct AIQuestionRecognition: Decodable, Sendable {
    let recognizedQuestion: String
    let subject: String
    let questionType: String
    let knowledgePoints: [String]
    let correctAnswer: String

    private enum CodingKeys: CodingKey {
        case recognizedQuestion, subject, questionType, knowledgePoints, correctAnswer
    }

    init(
        recognizedQuestion: String,
        subject: String,
        questionType: String,
        knowledgePoints: [String],
        correctAnswer: String = ""
    ) {
        self.recognizedQuestion = recognizedQuestion
        self.subject = subject
        self.questionType = questionType
        self.knowledgePoints = knowledgePoints
        self.correctAnswer = correctAnswer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recognizedQuestion = try container.decode(String.self, forKey: .recognizedQuestion)
        subject = try container.decode(String.self, forKey: .subject)
        questionType = try container.decode(String.self, forKey: .questionType)
        knowledgePoints = container.decodeStringArray(.knowledgePoints)
        correctAnswer = container.decodeString(.correctAnswer)
    }
}

struct AIQuestionSolution: Decodable, Sendable {
    struct SolutionStep: Decodable, Identifiable, Sendable {
        let number: Int
        let title: String
        let explanation: String

        var id: Int { number }

        private enum CodingKeys: CodingKey {
            case number, title, explanation
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decode(String.self, forKey: .title)
            explanation = try container.decode(String.self, forKey: .explanation)
            number = container.decodeFlexibleInt(.number)
        }
    }

    let solutionOverview: String
    let solutionSteps: [SolutionStep]
    let finalAnswer: String
    let commonMistakes: [String]

    private enum CodingKeys: CodingKey {
        case solutionOverview, solutionSteps, finalAnswer, commonMistakes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        solutionOverview = try container.decode(String.self, forKey: .solutionOverview)
        solutionSteps = try container.decode([SolutionStep].self, forKey: .solutionSteps)
        finalAnswer = try container.decode(String.self, forKey: .finalAnswer)
        commonMistakes = container.decodeStringArray(.commonMistakes)
    }
}

struct AIQuestionAnalysis: Sendable {
    let recognition: AIQuestionRecognition
    let confirmedQuestion: String
    let solution: AIQuestionSolution

    var recognizedQuestion: String { confirmedQuestion }
    var subject: String { recognition.subject }
    var questionType: String { recognition.questionType }
    var knowledgePoints: [String] { recognition.knowledgePoints }
    var solutionOverview: String { solution.solutionOverview }
    var solutionSteps: [AIQuestionSolution.SolutionStep] { solution.solutionSteps }
    var finalAnswer: String { solution.finalAnswer }
    var commonMistakes: [String] { solution.commonMistakes }
}
