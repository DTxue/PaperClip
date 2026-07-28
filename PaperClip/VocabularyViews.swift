import SwiftUI
import SwiftData

struct VocabularyHomeView: View {
    @Environment(\.modelContext) var modelContext

    @State var folders: [VocabularyFolderRowData] = []
    @State var decks: [VocabularyDeckRowData] = []
    @State var snapshot = VocabularyHomeSnapshot.empty
    @State private var kindToCreate: VocabularyDeckKind?
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
                        Text("创建词集学习单词，或创建句集学习短语与句子；两者都支持 TXT 文本导入。")
                    } actions: {
                        Button("创建词集", systemImage: "plus") {
                            kindToCreate = .word
                        }
                        .buttonStyle(.borderedProminent)
                        Button("创建句集", systemImage: "text.quote") {
                            kindToCreate = .sentence
                        }
                        .buttonStyle(.bordered)
                        Button("创建文件夹", systemImage: "folder.badge.plus") {
                            isCreatingFolder = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, minHeight: 360)
                } else {
                    VocabularyHomeOverview(
                        folderCount: folders.count,
                        wordDeckCount: decks.filter { $0.kind == .word }.count,
                        sentenceDeckCount: decks.filter { $0.kind == .sentence }.count,
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
        .paperClipThemedSurface(.page)
        .navigationTitle("英语")
        .onAppear {
            refreshHome()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("创建词集", systemImage: "character.book.closed") {
                        kindToCreate = .word
                    }
                    Button("创建句集", systemImage: "text.quote") {
                        kindToCreate = .sentence
                    }
                    Button("创建文件夹", systemImage: "folder.badge.plus") {
                        isCreatingFolder = true
                    }
                } label: {
                    Label("新增", systemImage: "plus")
                }
            }
        }
        .sheet(item: $kindToCreate, onDismiss: {
            refreshHome()
        }) { kind in
            NavigationStack {
                VocabularyDeckCreateView(kind: kind)
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
