import Foundation

enum AnalysisHTML {
    static func documentID(for analysis: AIQuestionAnalysis) -> String {
        [
            analysis.recognizedQuestion,
            analysis.solutionOverview,
            analysis.finalAnswer,
            analysis.solutionSteps.map(\.title).joined(),
            analysis.solutionSteps.map(\.explanation).joined(),
            analysis.commonMistakes.joined()
        ].joined(separator: "\u{1F}").hashValue.description
    }

    static func build(for analysis: AIQuestionAnalysis) -> String {
        let steps = analysis.solutionSteps.map { step in
            """
            <li>
              <h3>\(escaped(step.title))</h3>
              <div class="content">\(formatted(step.explanation))</div>
            </li>
            """
        }.joined()

        let mistakes = analysis.commonMistakes.map {
            "<li>\(formatted($0))</li>"
        }.joined()

        let mistakesSection = mistakes.isEmpty ? "" : """
        <section>
          <h2 class="section-title">
            <span class="section-icon" aria-hidden="true">!</span>
            <span>易错分析</span>
          </h2>
          <ul class="mistakes">\(mistakes)</ul>
        </section>
        """

        return """
        <!DOCTYPE html>
        <html lang="zh-Hans">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
          \(katexResources)
          \(sharedStyle)
        </head>
        <body>
          <main>
            <section>
              <h2 class="section-title">
                <span class="section-icon" aria-hidden="true">✦</span>
                <span>解题思路</span>
              </h2>
              <div class="content">\(formatted(analysis.solutionOverview))</div>
            </section>
            <section>
              <h2 class="section-title">
                <span class="section-icon" aria-hidden="true">①</span>
                <span>完整解答</span>
              </h2>
              <ol>\(steps)</ol>
            </section>
            <section>
              <h2 class="section-title">
                <span class="section-icon" aria-hidden="true">✓</span>
                <span>最终答案</span>
              </h2>
              <div class="content answer">\(formatted(analysis.finalAnswer))</div>
            </section>
            \(mistakesSection)
          </main>
          \(renderingScript)
        </body>
        </html>
        """
    }

}
