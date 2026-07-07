import SwiftUI
import SwiftData

struct WritingHomeView: View {
    @State private var selectedLanguage = WritingLanguage.chinese
    @State private var searchText = ""
    @State private var isPresentingNewPrompt = false
    @State private var promptRefreshToken = 0
    @State private var alert: AppAlert?

    var body: some View {
        List {
            Section {
                Picker("写作类型", selection: $selectedLanguage) {
                    ForEach(WritingLanguage.allCases) { language in
                        Label(language.title, systemImage: language.systemImage)
                            .tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            WritingPromptListSection(
                language: selectedLanguage,
                searchText: searchText,
                refreshToken: promptRefreshToken,
                alert: $alert
            )
            .id(selectedLanguage)
        }
        .navigationTitle("写作")
        .searchable(text: $searchText, prompt: "搜索写作题")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingNewPrompt = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("生成写作题")
            }
        }
        .sheet(isPresented: $isPresentingNewPrompt, onDismiss: {
            promptRefreshToken &+= 1
        }) {
            NewWritingPromptView(initialLanguage: selectedLanguage)
        }
        .appAlert($alert)
    }
}
