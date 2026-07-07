import Foundation

@main
struct VocabularyArticleRecitationTests {
    static func main() {
        let sentences = VocabularyArticleSentence.split("I am ready to learn. Focus helps memory.")
        expect(sentences.count == 2)
        expect(sentences[0].words == ["i", "am", "ready", "to", "learn"])

        var repeated = VocabularyArticleRecitationState(sentences: sentences)
        repeated.process(words: VocabularyArticleTextNormalizer.words(from: "I am I am ready to learn"))
        expect(repeated.revealedSentenceCount == 1)
        expect(repeated.currentSentenceIndex == 1)
        expect(repeated.lastMismatchWord == nil)

        var mismatch = VocabularyArticleRecitationState(sentences: sentences)
        mismatch.process(words: VocabularyArticleTextNormalizer.words(from: "I am wrong"))
        expect(mismatch.revealedSentenceCount == 0)
        expect(mismatch.currentWordIndex == 0)
        expect(mismatch.lastMismatchWord == "wrong")
        mismatch.process(words: VocabularyArticleTextNormalizer.words(from: "I am ready to learn"))
        expect(mismatch.revealedSentenceCount == 1)

        var complete = VocabularyArticleRecitationState(sentences: sentences)
        complete.process(words: VocabularyArticleTextNormalizer.words(from: "I am ready to learn Focus helps memory"))
        expect(complete.isComplete)

        let baseline = VocabularyArticleRecitationState(sentences: sentences)
        var revisedTranscript = VocabularyArticleTranscriptMatcher.apply(
            transcript: "I am ready to",
            baseline: baseline,
            current: baseline
        )
        expect(revisedTranscript.currentWordIndex == 4)
        revisedTranscript = VocabularyArticleTranscriptMatcher.apply(
            transcript: "I am ready two learn",
            baseline: baseline,
            current: revisedTranscript
        )
        expect(revisedTranscript.currentWordIndex == 4)
        revisedTranscript = VocabularyArticleTranscriptMatcher.apply(
            transcript: "I am ready to learn",
            baseline: baseline,
            current: revisedTranscript
        )
        expect(revisedTranscript.revealedSentenceCount == 1)

        let resumedTranscript = VocabularyArticleTranscriptMatcher.apply(
            transcript: "Focus helps memory",
            baseline: revisedTranscript,
            current: revisedTranscript
        )
        expect(resumedTranscript.isComplete)

        let normalized = VocabularyArticleTextNormalizer.words(from: "I'm ready, and I don't stop.")
        expect(normalized == ["i", "am", "ready", "and", "i", "do", "not", "stop"])

        print("VocabularyArticleRecitationTests: 17 passed")
    }

    private static func expect(
        _ condition: @autoclosure () -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard condition() else {
            fatalError("Expectation failed", file: file, line: line)
        }
    }
}
