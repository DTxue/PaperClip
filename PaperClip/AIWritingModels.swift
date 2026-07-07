import Foundation

struct AIWritingReviewResult: Codable, Sendable {
    let overallJudgement: String
    let advancedTargetStandard: String
    let actualLevel: ActualLevel
    let score: Score
    let coreGap: String
    let possibleOCRIssues: [String]
    let strengths: [String]
    let mainProblems: [Problem]
    let ideaUpgrade: IdeaUpgrade
    let contentAdvice: [ContentAdvice]
    let structureAdvice: [StructureAdvice]
    let languageUpgrade: [LanguageUpgrade]
    let goodWordsAndSentences: GoodWordsAndSentences
    let paragraphAdvice: [ParagraphAdvice]?
    let sampleUpgrade: SampleUpgrade?

    // New Fields
    let topicTaskAnalysis: TopicTaskAnalysis?
    let writingAbilityDiagnosis: [WritingAbilityDiagnosis]?
    let writingBlueprint: WritingBlueprint?
    let paragraphReconstruction: [ParagraphReconstruction]?
    let coreSceneUpgrade: CoreSceneUpgrade?
    let revisedStructurePlan: [RevisedStructurePlan]?
    let studentRevisionTasks: [StudentRevisionTask]?
    let priorityRevisionPlan: [String]
    let teacherComment: String

    private enum CodingKeys: String, CodingKey {
        case overallJudgement, advancedTargetStandard, actualLevel, score, coreGap
        case possibleOCRIssues, strengths, mainProblems, ideaUpgrade, contentAdvice
        case structureAdvice, languageUpgrade, goodWordsAndSentences, paragraphAdvice
        case sampleUpgrade, topicTaskAnalysis, writingAbilityDiagnosis, writingBlueprint
        case paragraphReconstruction, coreSceneUpgrade, revisedStructurePlan, studentRevisionTasks
        case priorityRevisionPlan, teacherComment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overallJudgement = container.decodeString(.overallJudgement)
        advancedTargetStandard = container.decodeString(.advancedTargetStandard)
        actualLevel = (try? container.decode(ActualLevel.self, forKey: .actualLevel)) ?? ActualLevel()
        score = (try? container.decode(Score.self, forKey: .score)) ?? Score()
        coreGap = container.decodeString(.coreGap)
        possibleOCRIssues = container.decodeStringArray(.possibleOCRIssues)
        strengths = container.decodeStringArray(.strengths)
        mainProblems = container.decodeArray([Problem].self, .mainProblems)
        ideaUpgrade = (try? container.decode(IdeaUpgrade.self, forKey: .ideaUpgrade)) ?? IdeaUpgrade()
        contentAdvice = container.decodeArray([ContentAdvice].self, .contentAdvice)
        structureAdvice = container.decodeArray([StructureAdvice].self, .structureAdvice)
        languageUpgrade = container.decodeArray([LanguageUpgrade].self, .languageUpgrade)
        goodWordsAndSentences = (try? container.decode(GoodWordsAndSentences.self, forKey: .goodWordsAndSentences)) ?? GoodWordsAndSentences()
        paragraphAdvice = container.decodeArray([ParagraphAdvice].self, .paragraphAdvice)
        sampleUpgrade = try? container.decode(SampleUpgrade.self, forKey: .sampleUpgrade)

        topicTaskAnalysis = try? container.decode(TopicTaskAnalysis.self, forKey: .topicTaskAnalysis)
        writingAbilityDiagnosis = container.decodeArray([WritingAbilityDiagnosis].self, .writingAbilityDiagnosis)
        writingBlueprint = try? container.decode(WritingBlueprint.self, forKey: .writingBlueprint)
        paragraphReconstruction = container.decodeArray([ParagraphReconstruction].self, .paragraphReconstruction)
        coreSceneUpgrade = try? container.decode(CoreSceneUpgrade.self, forKey: .coreSceneUpgrade)
        revisedStructurePlan = container.decodeArray([RevisedStructurePlan].self, .revisedStructurePlan)
        studentRevisionTasks = container.decodeArray([StudentRevisionTask].self, .studentRevisionTasks)

        priorityRevisionPlan = container.decodeStringArray(.priorityRevisionPlan)
        teacherComment = container.decodeString(.teacherComment)
    }

    var scoreText: String {
        guard score.fullScore > 0 else { return "" }
        let value = score.score == floor(score.score)
            ? String(Int(score.score))
            : String(format: "%.1f", score.score)
        let full = score.fullScore == floor(score.fullScore)
            ? String(Int(score.fullScore))
            : String(format: "%.1f", score.fullScore)
        return "\(value)/\(full)"
    }

    func encodedData() -> Data {
        WritingReviewJSONStorage.encode(self)
    }
}
