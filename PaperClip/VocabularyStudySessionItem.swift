import Foundation

struct VocabularyStudySessionItem: Codable, Identifiable {
    var id: UUID
    var cardID: UUID
    var prompt: String
    var expectedAnswer: String
    var isCorrect: Bool
    var recognizedText: String
    var comment: String

    init(
        id: UUID = UUID(),
        cardID: UUID,
        prompt: String,
        expectedAnswer: String,
        isCorrect: Bool,
        recognizedText: String = "",
        comment: String = ""
    ) {
        self.id = id
        self.cardID = cardID
        self.prompt = prompt
        self.expectedAnswer = expectedAnswer
        self.isCorrect = isCorrect
        self.recognizedText = recognizedText
        self.comment = comment
    }
}
