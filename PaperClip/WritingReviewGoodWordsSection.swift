import SwiftUI

extension WritingReviewDetailView {
    @ViewBuilder
    func goodWordsSection(_ item: AIWritingReviewResult.GoodWordsAndSentences) -> some View {
        if !item.words.isEmpty
            || !item.phrases.isEmpty
            || !item.sentences.isEmpty
            || !item.sentencePatterns.isEmpty
            || !item.openingSentences.isEmpty
            || !item.transitionSentences.isEmpty
            || !item.endingSentences.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("好词好句")
                    .font(.headline)
                ForEach(item.words) { word in
                    Text("好词：\(word.word)｜\(word.meaning)｜\(word.whereToUse)\n\(word.example)")
                }
                ForEach(item.phrases) { phrase in
                    Text("好短语：\(phrase.phrase)｜\(phrase.whereToUse)\n\(phrase.example)")
                }
                ForEach(item.sentences) { sentence in
                    Text("好句：\(sentence.sentence)\n\(sentence.whereToUse)：\(sentence.whyUseful)")
                }
                ForEach(item.sentencePatterns) { pattern in
                    Text("句式：\(pattern.pattern)\n\(pattern.usage)\n\(pattern.example)")
                }
                listSection("开头句", item.openingSentences)
                listSection("过渡句", item.transitionSentences)
                listSection("结尾句", item.endingSentences)
                textSection("使用建议", item.stackingAdvice)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
