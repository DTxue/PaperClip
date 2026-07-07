import UIKit

enum AIConnectionTestSample {
    static let question = "计算：1 + 1 = ?"

    static let recognition = AIQuestionRecognition(
        recognizedQuestion: question,
        subject: "数学",
        questionType: "计算题",
        knowledgePoints: ["整数加法"]
    )

    static func image() -> UIImage {
        let size = CGSize(width: 900, height: 360)

        return ImageRenderSupport.opaqueImage(size: size) { context in
            ImageRenderSupport.fillWhiteBackground(
                in: CGRect(origin: .zero, size: size),
                context: context
            )
            question.draw(
                at: CGPoint(x: 80, y: 115),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 72, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
            )
        }
    }
}
