import SwiftUI
import SwiftData

struct WritingPromptListSection: View {
    let language: WritingLanguage
    let searchText: String
    let refreshToken: Int
    let onCreate: () -> Void
    @Binding var alert: AppAlert?

    @Environment(\.modelContext) private var modelContext
    @State private var prompts: [WritingPromptRowData] = []
    @State private var recentDrafts: [WritingDraftRowData] = []
    @State private var recentReviews: [WritingReviewRowData] = []

    init(
        language: WritingLanguage,
        searchText: String,
        refreshToken: Int,
        alert: Binding<AppAlert?>,
        onCreate: @escaping () -> Void
    ) {
        self.language = language
        self.searchText = searchText
        self.refreshToken = refreshToken
        self.onCreate = onCreate
        _alert = alert
    }

    var body: some View {
        let snapshot = WritingHomeSnapshot(
            prompts: prompts,
            drafts: recentDrafts,
            reviews: recentReviews,
            searchText: searchText
        )

        WritingPromptListContentView(
            language: language,
            snapshot: snapshot,
            onDelete: deletePrompts,
            onCreate: onCreate
        )
        .task(id: refreshToken) {
            refreshPrompts()
        }
    }

    func refreshPrompts() {
        do {
            let data = try WritingPromptListDataLoader.load(
                language: language,
                modelContext: modelContext
            )
            prompts = data.prompts
            recentDrafts = data.drafts
            recentReviews = data.reviews
        } catch {
            alert = AppAlert(title: "无法读取写作题", error: error)
            prompts = []
            recentDrafts = []
            recentReviews = []
        }
    }

    func deletePrompts(at offsets: IndexSet, visiblePrompts: [WritingPromptRowData]) {
        let targetIDs = WritingPromptDeletionSelection.targetIDs(
            offsets: offsets,
            visiblePrompts: visiblePrompts
        )

        do {
            for promptID in targetIDs {
                try modelContext.deleteWritingPromptCascade(promptID: promptID)
            }
            try modelContext.saveOrRollbackIfNeeded()
            refreshPrompts()
        } catch {
            alert = AppAlert(title: "无法删除写作题", error: error)
        }
    }

}
