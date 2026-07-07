import Foundation

@main
struct KnowledgeAIPromptsTests {
    static func main() {
        testAnalyzePromptIncludesInputStrategiesAndSchema()
        testKnowledgeAnalysisDecodableNormalizesFlexibleFields()
        print("KnowledgeAIPromptsTests: 2 passed")
    }

    private static func testAnalyzePromptIncludesInputStrategiesAndSchema() {
        let prompt = KnowledgeAIPrompts.analyze("牛顿第二定律")
        expect(prompt.contains("知识点：牛顿第二定律"))
        expect(prompt.contains("【数学/物理】"))
        expect(prompt.contains("【英语】"))
        expect(prompt.contains("\"subject\""))
        expect(prompt.contains("\"memoryAnchor\""))
    }

    private static func testKnowledgeAnalysisDecodableNormalizesFlexibleFields() {
        let data = """
        {
          "subject": "物理",
          "essence": "力和加速度\\n成正比",
          "formula": "F=ma",
          "solutionPath": ["受力分析", "列方程"],
          "trap": "单位错误\\n方向错误",
          "related": ["运动学", "牛顿第三定律"],
          "memoryAnchor": "力决定加速度"
        }
        """.data(using: .utf8)!

        let value = try! JSONDecoder().decode(KnowledgeAnalysisDecodable.self, from: data)
        let analysis = value.toAnalysis()

        expect(analysis.subject == "物理")
        expect(analysis.essence == "力和加速度\n成正比")
        expect(analysis.solutionPath == "受力分析\n列方程")
        expect(analysis.trap == "单位错误\n方向错误")
        expect(analysis.related == "运动学\n牛顿第三定律")
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
