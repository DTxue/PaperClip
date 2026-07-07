import Foundation

enum RecognitionHTML {
    static func build(question: String, isEmbedded: Bool) -> String {
        let content = isEmbedded
            ? """
              <div class="content embedded-content">\(formatted(question))</div>
              """
            : """
              <section class="recognition">
                <h2 class="section-title">
                  <span class="section-icon" aria-hidden="true">⌗</span>
                  <span>识别结果</span>
                </h2>
                <div class="content">\(formatted(question))</div>
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
            \(content)
          </main>
          \(renderingScript)
        </body>
        </html>
        """
    }
}
