import Foundation

struct MistakeCardRowData: Identifiable, Hashable {
    let id: UUID
    let imageFileName: String
    let grade: String
    let semester: String
    let subject: String
    let tagsText: String
    let status: String
    let note: String
    let createdAt: Date
    let tags: [String]
    let recognitionStatus: String
    let recognizedText: String
    let questionType: String
    let correctAnswer: String
    let sourceDocumentTitle: String
    let resolvedQuestionTypeRaw: String

    init(
        id: UUID,
        imageFileName: String,
        grade: String,
        semester: String,
        subject: String,
        tagsText: String,
        status: String,
        note: String,
        createdAt: Date,
        recognitionStatus: String,
        recognizedText: String,
        questionType: String,
        correctAnswer: String,
        sourceDocumentTitle: String
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.grade = grade
        self.semester = semester
        self.subject = subject
        self.tagsText = tagsText
        self.status = status
        self.note = note
        self.createdAt = createdAt
        self.tags = MistakeTagParser.parse(tagsText)
        self.recognitionStatus = recognitionStatus
        self.recognizedText = recognizedText
        self.questionType = questionType
        self.correctAnswer = correctAnswer
        self.sourceDocumentTitle = sourceDocumentTitle
        self.resolvedQuestionTypeRaw = QuestionType.resolve(
            questionType,
            questionText: recognizedText
        ).rawValue
    }

}
