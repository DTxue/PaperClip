import SwiftUI

extension SubjectMistakesView {
    @ViewBuilder
    func referencePage(kind: MathematicsReferenceKind) -> some View {
        if subject == Subject.math.rawValue {
            MathematicsReferenceView(kind: kind)
        } else {
            let title = kind == .knowledgePoints ? "知识点" : "公式"
            let image = kind == .knowledgePoints
                ? "point.3.connected.trianglepath.dotted"
                : "function"
            ContentUnavailableView(
                "\(title)页面",
                systemImage: image,
                description: Text("该学科的\(title)内容暂未开放。")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func saveChanges() {
        do { try modelContext.saveOrRollbackIfNeeded() }
        catch { alert = AppAlert(title: "无法保存更改", error: error) }
    }

    func refreshCards() {
        do {
            cards = try modelContext.fetchMistakeCards(
                subject: subject,
                propertiesToFetch: MistakeCardRowData.propertiesToFetch
            ).map(MistakeCardRowData.init)
            fetchPracticeRoundCounts(for: cards.map(\.id))
        } catch {
            cards = []
            practiceRoundCountByCardID = [:]
            alert = AppAlert(title: "无法读取错题", error: error)
        }
    }

    func fetchPracticeRoundCounts(for cardIDs: [UUID]) {
        let visibleCardIDs = Set(cardIDs)
        guard !visibleCardIDs.isEmpty else {
            practiceRoundCountByCardID = [:]
            return
        }

        do {
            practiceRoundCountByCardID = try modelContext.fetchMistakePracticeRoundCounts(
                cardIDs: Array(visibleCardIDs)
            )
        } catch {
            alert = AppAlert(title: "无法读取练习次数", error: error)
            practiceRoundCountByCardID = [:]
        }
    }

    func promoteStatus(for row: MistakeCardRowData) {
        do {
            guard let card = try modelContext.fetchMistakeCard(id: row.id) else {
                alert = AppAlert(title: "无法保存更改", message: "该错题不存在或已被删除。")
                refreshCards()
                return
            }
            card.status = MasteryStatus.nextLevel(after: card.status).rawValue
            card.updatedAt = .now
            try modelContext.saveOrRollbackIfNeeded()
            refreshCards()
        } catch {
            alert = AppAlert(title: "无法保存更改", error: error)
        }
    }

    func deleteCard(_ row: MistakeCardRowData) {
        let imageURL: URL
        do {
            imageURL = try modelContext.deleteMistakeCardCascade(cardID: row.id) ?? row.imageURL
            try modelContext.saveOrRollbackIfNeeded()
            refreshCards()
        } catch {
            alert = AppAlert(title: "无法删除错题", error: error)
            return
        }

        do {
            try StorageService.deleteFile(at: imageURL)
        } catch {
            alert = AppAlert(title: "错题记录已删除，图片清理失败", error: error)
        }
    }
}
