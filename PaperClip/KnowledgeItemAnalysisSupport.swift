import Foundation

extension KnowledgeItem {
    @discardableResult
    func applyAnalysis(_ result: KnowledgeAnalysis) -> Bool {
        let didChange = subject != result.subject
            || aiEssence != result.essence
            || aiFormula != result.formula
            || aiSolutionPath != result.solutionPath
            || aiTrap != result.trap
            || aiRelated != result.related
            || aiMemoryAnchor != result.memoryAnchor
            || aiAnalysisState != "done"
        guard didChange else { return false }

        subject = result.subject
        aiEssence = result.essence
        aiFormula = result.formula
        aiSolutionPath = result.solutionPath
        aiTrap = result.trap
        aiRelated = result.related
        aiMemoryAnchor = result.memoryAnchor
        aiAnalysisState = "done"
        updatedAt = Date()
        return true
    }

    @discardableResult
    func markAnalysisFailed() -> Bool {
        guard aiAnalysisState != "failed" else { return false }
        aiAnalysisState = "failed"
        updatedAt = Date()
        return true
    }

    @discardableResult
    func resetAnalysisState() -> Bool {
        guard aiAnalysisState != "none" else { return false }
        aiAnalysisState = "none"
        updatedAt = Date()
        return true
    }
}
