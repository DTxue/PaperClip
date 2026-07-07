import SwiftUI
import SwiftData

struct VocabularyHomeView: View {
    @Environment(\.modelContext) var modelContext

    @State var folders: [VocabularyFolderRowData] = []
    @State var decks: [VocabularyDeckRowData] = []
    @State var snapshot = VocabularyHomeSnapshot.empty
    @State private var isCreatingDeck = false
    @State private var isCreatingFolder = false
    @State private var deckToMove: VocabularyDeckRowData?
    @State private var folderToRename: VocabularyFolderRowData?
    @State var alert: AppAlert?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if folders.isEmpty && decks.isEmpty {
                    ContentUnavailableView {
                        Label("还没有 ENG 内容", systemImage: "character.book.closed")
                    } description: {
                        Text("创建词集后，可通过多种 TXT 文本格式导入单词；也可以创建文件夹归档多个词集。")
                    } actions: {
                        Button("创建词集", systemImage: "plus") {
                            isCreatingDeck = true
                        }
                        .buttonStyle(.borderedProminent)
                        Button("创建文件夹", systemImage: "folder.badge.plus") {
                            isCreatingFolder = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, minHeight: 360)
                } else {
                    VocabularyHomeOverview(
                        folderCount: folders.count,
                        deckCount: decks.count,
                        snapshot: snapshot
                    )
                    VocabularyHomeFolderGrid(
                        folders: folders,
                        decks: decks,
                        snapshot: snapshot,
                        onRenameFolder: { folderToRename = $0 },
                        onMoveDeck: { deckToMove = $0 },
                        onRemoveDeckFromFolder: removeDeckFromFolder
                    )
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("英语")
        .onAppear {
            refreshHome()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("创建词集", systemImage: "character.book.closed") {
                        isCreatingDeck = true
                    }
                    Button("创建文件夹", systemImage: "folder.badge.plus") {
                        isCreatingFolder = true
                    }
                } label: {
                    Label("新增", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreatingDeck, onDismiss: {
            refreshHome()
        }) {
            NavigationStack {
                VocabularyDeckCreateView()
            }
        }
        .sheet(isPresented: $isCreatingFolder, onDismiss: {
            refreshHome()
        }) {
            NavigationStack {
                VocabularyFolderCreateView()
            }
        }
        .sheet(item: $folderToRename, onDismiss: {
            refreshHome()
        }) { folder in
            NavigationStack {
                VocabularyFolderRenameView(folder: folder)
            }
        }
        .sheet(item: $deckToMove, onDismiss: {
            refreshHome()
        }) { deck in
            NavigationStack {
                VocabularyDeckFolderPickerView(
                    deck: deck,
                    folders: folders,
                    onSelect: { folderID in
                        moveDeck(deck, to: folderID)
                    }
                )
            }
        }
        .appAlert($alert)
    }

}
