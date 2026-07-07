import Foundation

extension MistakeCard {
    func applyRecognition(_ recognition: AIQuestionRecognition) {
        recognizedText = recognition.recognizedQuestion
        questionType = QuestionType.resolve(
            recognition.questionType,
            questionText: recognition.recognizedQuestion
        ).rawValue
        correctAnswer = recognition.correctAnswer.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if let mappedSubject = Subject.from(aiString: recognition.subject) {
            subject = mappedSubject.rawValue
        }

        if tagsText.isEmpty {
            let newTags = MistakeTagParser.normalize(recognition.knowledgePoints)
            if !newTags.isEmpty {
                tagsText = MistakeTagParser.serialize(newTags)
            }
        }
    }
}
