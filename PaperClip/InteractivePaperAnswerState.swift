import Foundation
import PencilKit
import SwiftUI

struct InteractivePaperAnswerState {
    var drawings: [UUID: PKDrawing] = [:]
    var selectedAnswers: [UUID: String] = [:]
    var textAnswers: [UUID: String] = [:]

    func drawing(for cardID: UUID) -> PKDrawing {
        drawings[cardID] ?? PKDrawing()
    }

    func selectedAnswer(for cardID: UUID) -> String {
        selectedAnswers[cardID] ?? ""
    }

    func textAnswer(for cardID: UUID) -> String {
        textAnswers[cardID] ?? ""
    }

    mutating func setDrawing(_ drawing: PKDrawing, for cardID: UUID) {
        drawings[cardID] = drawing
    }

    mutating func setSelectedAnswer(_ answer: String, for cardID: UUID) {
        selectedAnswers[cardID] = answer
    }

    mutating func setTextAnswer(_ answer: String, for cardID: UUID) {
        textAnswers[cardID] = answer
    }
}

extension Binding where Value == InteractivePaperAnswerState {
    func drawing(for cardID: UUID) -> Binding<PKDrawing> {
        Binding<PKDrawing>(
            get: { wrappedValue.drawing(for: cardID) },
            set: { wrappedValue.setDrawing($0, for: cardID) }
        )
    }

    func selectedAnswer(for cardID: UUID) -> Binding<String> {
        Binding<String>(
            get: { wrappedValue.selectedAnswer(for: cardID) },
            set: { wrappedValue.setSelectedAnswer($0, for: cardID) }
        )
    }

    func textAnswer(for cardID: UUID) -> Binding<String> {
        Binding<String>(
            get: { wrappedValue.textAnswer(for: cardID) },
            set: { wrappedValue.setTextAnswer($0, for: cardID) }
        )
    }
}
