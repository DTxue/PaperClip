import SwiftUI
import SwiftData

struct WritingHomeView: View {
    @State private var searchText = ""
    @State private var isPresentingNewPrompt = false
    @State private var promptRefreshToken = 0
    @State private var alert: AppAlert?

    var body: some View {
        List {
            WritingPromptListSection(
                language: .chinese,
                searchText: searchText,
                refreshToken: promptRefreshToken,
                alert: $alert,
                onCreate: {
                    isPresentingNewPrompt = true
                }
            )
        }
        .navigationTitle("写作")
        .searchable(text: $searchText, prompt: "搜索写作题")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingNewPrompt = true
                } label: {
                    Label("生成写作题", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewPrompt, onDismiss: {
            promptRefreshToken &+= 1
        }) {
            NewWritingPromptView()
        }
        .appAlert($alert)
    }
}
