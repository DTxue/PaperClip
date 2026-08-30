import SwiftUI
import SwiftData
import ImageIO
import UIKit

private struct MistakeSubjectRoute: Hashable {
    let filter: MistakeLibraryFilter
    let subject: String
}

struct MistakeLibraryView: View {
    @Query(sort: \MistakeLibraryItem.updatedAt, order: .reverse)
    private var items: [MistakeLibraryItem]
    @Query(sort: \MistakeAttachment.sortIndex)
    private var attachments: [MistakeAttachment]
    @Query(sort: \MistakeReviewAttempt.createdAt, order: .reverse)
    private var attempts: [MistakeReviewAttempt]

    @State private var selectedFilter: MistakeLibraryFilter? = .all
    @State private var navigationPath = NavigationPath()
    @State private var isCreating = false
    @State private var selectedItem: MistakeLibraryItem?

    var body: some View {
        PaperClipNavigationSplitView {
            List(selection: $selectedFilter) {
                Section("整理") {
                    ForEach(MistakeLibraryFilter.allCases) { filter in
                        Label(filter.title, systemImage: filter.systemImage)
                            .tag(filter)
                    }
                }
            }
            .paperClipSidebarColumn("错题库")
        } detail: {
            NavigationStack(path: $navigationPath) {
                let filter = selectedFilter ?? .all
                Group {
                    if filter.usesSubjectFolders {
                        subjectFolderList(for: filter)
                    } else {
                        MistakeSubjectItemsView(
                            title: filter.title,
                            emptyTitle: "最近删除为空",
                            items: MistakeLibraryOrganizer.items(items, matching: filter),
                            attachments: attachments,
                            onSelect: { selectedItem = $0 }
                        )
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isCreating = true
                        } label: {
                            Label("录入错题", systemImage: "plus")
                        }
                    }
                }
                .navigationDestination(for: MistakeSubjectRoute.self) { route in
                    MistakeSubjectItemsView(
                        title: route.subject,
                        emptyTitle: "\(route.subject)暂无\(route.filter.title)",
                        items: MistakeLibraryOrganizer.items(items, matching: route.filter)
                            .filter { $0.subject == route.subject },
                        attachments: attachments,
                        onSelect: { selectedItem = $0 }
                    )
                }
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            navigationPath = NavigationPath()
        }
        .sheet(isPresented: $isCreating) {
            MistakeEditorView()
        }
        .sheet(item: $selectedItem) { item in
            MistakeDetailView(
                item: item,
                attachments: attachments.filter { $0.itemID == item.id },
                attempts: attempts.filter { $0.itemID == item.id },
                onRemoved: { selectedItem = nil }
            )
        }
    }

    private func subjectFolderList(for filter: MistakeLibraryFilter) -> some View {
        List {
            ForEach(MistakeLibraryOrganizer.folders(for: items, matching: filter)) { folder in
                NavigationLink(value: MistakeSubjectRoute(filter: filter, subject: folder.subject)) {
                    HStack(spacing: 14) {
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: subjectSymbol(folder.subject))
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        Text(folder.subject)
                            .font(.headline)
                        Spacer()
                        Text("\(folder.count) 道")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(filter.title)
    }
}

private struct MistakeSubjectItemsView: View {
    let title: String
    let emptyTitle: String
    let items: [MistakeLibraryItem]
    let attachments: [MistakeAttachment]
    let onSelect: (MistakeLibraryItem) -> Void

    @State private var searchText = ""

    var body: some View {
        Group {
            if visibleItems.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? emptyTitle : "没有匹配的错题",
                    systemImage: searchText.isEmpty ? "folder" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "符合当前条件的错题会显示在这里。" : "请尝试其他关键词。")
                )
            } else {
                List(visibleItems) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        MistakeLibraryRow(
                            item: item,
                            attachment: attachments.first { $0.itemID == item.id }
                        )
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(title)
        .searchable(text: $searchText, prompt: "搜索题目、来源、标签")
    }

    private var visibleItems: [MistakeLibraryItem] {
        guard !searchText.isEmpty else { return items }
        let query = searchText.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        return items.filter { item in
            [
                item.questionText,
                item.errorReason,
                item.subject,
                item.grade,
                item.semester,
                item.source,
                item.tagsText
            ]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .localizedStandardContains(query)
        }
    }
}

private func subjectSymbol(_ rawValue: String) -> String {
    Subject(rawValue: rawValue)?.sfSymbol ?? "book.closed"
}

private struct MistakeLibraryRow: View {
    let item: MistakeLibraryItem
    let attachment: MistakeAttachment?

    var body: some View {
        HStack(spacing: 14) {
            MistakeAttachmentThumbnail(fileName: attachment?.fileName)
                .frame(width: 84, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                if item.questionText.isEmpty {
                    Text("图片错题")
                        .font(.headline)
                        .foregroundStyle(.primary)
                } else {
                    MistakeQuestionTextView(
                        text: item.questionText,
                        maximumHeight: 52
                    )
                    .allowsHitTesting(false)
                }
                HStack(spacing: 8) {
                    Text(item.subject)
                    Text(item.grade)
                    Text(item.semester)
                    Text(item.status.title)
                    if let nextReviewAt = item.nextReviewAt, item.status == .learning {
                        Text(nextReviewAt, style: .date)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

struct MistakeAttachmentThumbnail: View {
    let fileName: String?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    Color.secondary.opacity(0.12)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task(id: fileName) {
            guard let fileName else {
                image = nil
                return
            }
            let url = StoredFile.mistakeAttachment(fileName: fileName).url
            image = await Task.detached(priority: .utility) {
                downsampledImage(at: url, maxPixel: 720)
            }.value
        }
    }
}

private nonisolated func downsampledImage(at url: URL, maxPixel: Int) -> UIImage? {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }
    let options = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixel
    ] as CFDictionary
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
    return UIImage(cgImage: image)
}
