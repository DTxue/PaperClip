import SwiftUI
import SwiftData

struct VocabularyHomeView: View {
    let board: VocabularyHomeBoard
    @Environment(\.modelContext) var modelContext

    @State var folders: [VocabularyFolderRowData] = []
    @State var decks: [VocabularyDeckRowData] = []
    @State var snapshot = VocabularyHomeSnapshot.empty
    @State private var kindToCreate: VocabularyDeckKind?
    @State private var isCreatingFolder = false
    @State private var deckToMove: VocabularyDeckRowData?
    @State private var folderToRename: VocabularyFolderRowData?
    @State var alert: AppAlert?

    init(board: VocabularyHomeBoard = .english) {
        self.board = board
    }

    var boardDecks: [VocabularyDeckRowData] {
        decks.filter { $0.kind.homeBoard == board }
    }

    var boardFolders: [VocabularyFolderRowData] {
        let linkedFolderIDs = Set(decks.compactMap(\.folderID))
        let boardFolderIDs = Set(boardDecks.compactMap(\.folderID))
        return folders.filter { folder in
            boardFolderIDs.contains(folder.id) || !linkedFolderIDs.contains(folder.id)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if boardFolders.isEmpty && boardDecks.isEmpty {
                    ContentUnavailableView {
                        Label("还没有\(board.title)内容", systemImage: "character.book.closed")
                    } description: {
                        Text(board == .english
                            ? "创建词集学习单词，或创建句集学习短语与句子；两者都支持 TXT 文本导入。"
                            : "创建\(board.title)默写集，支持 TXT 文本导入。")
                    } actions: {
                        ForEach(board.kinds) { kind in
                            Button {
                                kindToCreate = kind
                            } label: {
                                Label("创建\(kind.collectionName)", systemImage: kind.systemImage)
                            }
                            .buttonStyle(.bordered)
                        }
                        Button("创建文件夹", systemImage: "folder.badge.plus") {
                            isCreatingFolder = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, minHeight: 360)
                } else {
                    VocabularyHomeOverview(
                        folderCount: boardFolders.count,
                        deckCounts: board.kinds.map { kind in
                            (kind.collectionName, boardDecks.filter { $0.kind == kind }.count)
                        },
                        snapshot: snapshot
                    )
                    VocabularyHomeFolderGrid(
                        folders: boardFolders,
                        decks: boardDecks,
                        kinds: board.kinds,
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
        .navigationTitle(board.title)
        .onAppear {
            refreshHome()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(board.kinds) { kind in
                        Button {
                            kindToCreate = kind
                        } label: {
                            Label("创建\(kind.collectionName)", systemImage: kind.systemImage)
                        }
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

struct VocabularyDictationHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var decks: [VocabularyDeckRowData] = []
    @State private var alert: AppAlert?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("默写分类")
                    .font(.title2.bold())

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 16)], spacing: 16) {
                    ForEach(VocabularyHomeBoard.allCases) { board in
                        NavigationLink {
                            VocabularyHomeView(board: board)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: board.systemImage)
                                    .font(.title)
                                    .foregroundStyle(Color.accentColor)
                                Text(board.title)
                                    .font(.headline)
                                Text(board.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(deckCount(for: board)) 个学习集")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
                            .padding(18)
                            .background(.background, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .paperClipThemedSurface(.page)
        .navigationTitle("默写")
        .task { refreshDecks() }
        .appAlert($alert)
    }

    private func deckCount(for board: VocabularyHomeBoard) -> Int {
        decks.filter { $0.kind.homeBoard == board }.count
    }

    private func refreshDecks() {
        do {
            decks = try modelContext.fetchVocabularyDecks(
                propertiesToFetch: VocabularyDeckRowData.propertiesToFetch
            ).map(VocabularyDeckRowData.init)
        } catch {
            alert = AppAlert(title: "无法读取默写分类", error: error)
        }
    }
}
