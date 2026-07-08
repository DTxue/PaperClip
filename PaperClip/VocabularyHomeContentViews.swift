import SwiftUI

struct VocabularyHomeOverview: View {
    let folderCount: Int
    let deckCount: Int
    let snapshot: VocabularyHomeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("学习概况")
                .font(.title2.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                VocabularyMetricTile(
                    value: "\(folderCount)",
                    label: "文件夹",
                    icon: "folder.fill",
                    color: Color.yellow
                )
                VocabularyMetricTile(
                    value: "\(deckCount)",
                    label: "词集",
                    icon: "books.vertical.fill",
                    color: Color.accentColor
                )
                VocabularyMetricTile(
                    value: "\(snapshot.totalCardCount)",
                    label: "单词",
                    icon: "character.book.closed.fill",
                    color: Color.blue
                )
                VocabularyMetricTile(
                    value: "\(snapshot.dueCount)",
                    label: "今日待复习次数",
                    icon: "clock.fill",
                    color: Color.orange
                )
            }
        }
    }
}

struct VocabularyHomeFolderGrid: View {
    let folders: [VocabularyFolderRowData]
    let decks: [VocabularyDeckRowData]
    let snapshot: VocabularyHomeSnapshot
    let onRenameFolder: (VocabularyFolderRowData) -> Void
    let onMoveDeck: (VocabularyDeckRowData) -> Void
    let onRemoveDeckFromFolder: (VocabularyDeckRowData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !folders.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("文件夹")
                        .font(.title2.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 16)], spacing: 16) {
                        ForEach(folders) { folder in
                            NavigationLink {
                                VocabularyFolderDeckListView(
                                    folder: folder,
                                    decks: decks(in: folder),
                                    snapshot: snapshot,
                                    onMoveDeck: onMoveDeck,
                                    onRemoveDeckFromFolder: onRemoveDeckFromFolder
                                )
                            } label: {
                                VocabularyHomeFolderCard(
                                    title: folder.title,
                                    deckCount: decks(in: folder).count,
                                    cardCount: cardCount(in: folder)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("文件夹设置", systemImage: "gearshape") {
                                    onRenameFolder(folder)
                                }
                            }
                            .accessibilityLabel("\(folder.title)，\(decks(in: folder).count)个词集")
                        }
                    }
                }
            }

            VocabularyHomeDeckGrid(
                title: folders.isEmpty ? "我的词集" : "未归档词集",
                decks: unfiledDecks,
                snapshot: snapshot,
                onMoveDeck: onMoveDeck,
                onRemoveDeckFromFolder: onRemoveDeckFromFolder
            )
        }
    }

    private var folderIDs: Set<UUID> {
        Set(folders.map(\.id))
    }

    private var unfiledDecks: [VocabularyDeckRowData] {
        decks.filter { deck in
            guard let folderID = deck.folderID else { return true }
            return !folderIDs.contains(folderID)
        }
    }

    private func decks(in folder: VocabularyFolderRowData) -> [VocabularyDeckRowData] {
        decks.filter { $0.folderID == folder.id }
    }

    private func cardCount(in folder: VocabularyFolderRowData) -> Int {
        decks(in: folder).reduce(0) { total, deck in
            total + cardCount(for: deck)
        }
    }

    private func cardCount(for deck: VocabularyDeckRowData) -> Int {
        snapshot.cardCountByDeckID[deck.id, default: 0]
    }
}

struct VocabularyHomeDeckGrid: View {
    let title: String
    let decks: [VocabularyDeckRowData]
    let snapshot: VocabularyHomeSnapshot
    let onMoveDeck: (VocabularyDeckRowData) -> Void
    let onRemoveDeckFromFolder: (VocabularyDeckRowData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title2.bold())
            if decks.isEmpty {
                ContentUnavailableView(
                    title == "未归档词集" ? "没有未归档词集" : "还没有词集",
                    systemImage: "tray",
                    description: Text(title == "未归档词集" ? "移动到文件夹的词集会从这里移出。" : "创建词集后会显示在这里。")
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 16)], spacing: 16) {
                    ForEach(decks) { deck in
                        VocabularyHomeDeckLink(
                            deck: deck,
                            cardCount: cardCount(for: deck),
                            onMoveDeck: onMoveDeck,
                            onRemoveDeckFromFolder: onRemoveDeckFromFolder
                        )
                    }
                }
            }
        }
    }

    private func cardCount(for deck: VocabularyDeckRowData) -> Int {
        snapshot.cardCountByDeckID[deck.id, default: 0]
    }
}

struct VocabularyFolderDeckListView: View {
    let folder: VocabularyFolderRowData
    let decks: [VocabularyDeckRowData]
    let snapshot: VocabularyHomeSnapshot
    let onMoveDeck: (VocabularyDeckRowData) -> Void
    let onRemoveDeckFromFolder: (VocabularyDeckRowData) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if decks.isEmpty {
                    ContentUnavailableView(
                        "文件夹为空",
                        systemImage: "folder",
                        description: Text("从词集菜单中选择“移至文件夹”即可归档到这里。")
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    VocabularyHomeDeckGrid(
                        title: "词集",
                        decks: decks,
                        snapshot: snapshot,
                        onMoveDeck: onMoveDeck,
                        onRemoveDeckFromFolder: onRemoveDeckFromFolder
                    )
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(folder.title)
    }
}

private struct VocabularyHomeDeckLink: View {
    let deck: VocabularyDeckRowData
    let cardCount: Int
    let onMoveDeck: (VocabularyDeckRowData) -> Void
    let onRemoveDeckFromFolder: (VocabularyDeckRowData) -> Void

    var body: some View {
        NavigationLink {
            VocabularyDeckLoader(deckID: deck.id)
        } label: {
            VocabularyHomeDeckCard(
                title: deck.title,
                cardCount: cardCount
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("移至文件夹", systemImage: "folder") {
                onMoveDeck(deck)
            }
            if deck.folderID != nil {
                Button("移出文件夹", systemImage: "tray.and.arrow.up") {
                    onRemoveDeckFromFolder(deck)
                }
            }
        }
        .accessibilityLabel("\(deck.title)，\(cardCount)个单词")
    }
}

private struct VocabularyHomeFolderCard: View {
    @Environment(\.paperClipAppPalette) private var palette

    let title: String
    let deckCount: Int
    let cardCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title)
                .foregroundStyle(.yellow)
            Text(title)
                .font(.headline)
                .lineLimit(2)
            Text("\(deckCount) 个词集 · \(cardCount) 个词组")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .padding(18)
        .background(palette.panelBackgroundColor, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(palette.borderColor.opacity(0.7)) }
    }
}

private struct VocabularyHomeDeckCard: View {
    @Environment(\.paperClipAppPalette) private var palette

    let title: String
    let cardCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "character.book.closed.fill")
                .font(.title)
                .foregroundStyle(.accent)
            Text(title)
                .font(.headline)
                .lineLimit(2)
            Text("\(cardCount) 个词组")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .padding(18)
        .background(palette.panelBackgroundColor, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(palette.borderColor.opacity(0.7)) }
    }
}
