import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum AppSection: Int {
    case home
    case mistakes
    case statistics
    case settings
}

struct RootView: View {
    @State private var section: AppSection = .home

    var body: some View {
        TabView(selection: $section) {
            Tab("首页", systemImage: "house", value: .home) {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("错题库", systemImage: "rectangle.stack", value: .mistakes) {
                NavigationStack {
                    MistakeLibraryView()
                }
            }

            Tab("统计", systemImage: "chart.bar", value: .statistics) {
                NavigationStack {
                    StatisticsView()
                }
            }

            Tab("设置", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

// MARK: - Home View

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PDFDocumentItem.lastOpenDate, order: .reverse) private var documents: [PDFDocumentItem]
    @Query(sort: \MistakeCard.createdAt, order: .reverse) private var cards: [MistakeCard]

    @State private var isImporterPresented = false
    @State private var selectedDocument: PDFDocumentItem?
    @State private var alert: AppAlert?
    @State private var searchText = ""

    private var filteredDocuments: [PDFDocumentItem] {
        guard !searchText.isEmpty else { return documents }
        return documents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: Stats

    private var unmasteredCount: Int {
        cards.filter { $0.status == MasteryStatus.unmastered.rawValue }.count
    }
    private var masteredPct: Int {
        cards.isEmpty ? 0 : Int(Double(cards.filter { $0.status == MasteryStatus.mastered.rawValue }.count) / Double(cards.count) * 100)
    }
    private var todayCount: Int {
        let start = Calendar.current.startOfDay(for: .now)
        return cards.filter { $0.createdAt >= start }.count
    }
    private var recentCards: [MistakeCard] { Array(cards.prefix(5)) }
    private var subjectProgress: [(subject: String, mastered: Int, total: Int)] {
        let subjects = Subject.allCases.filter { s in
            cards.contains { $0.subject == s.rawValue }
        }
        return subjects.map { s in
            let subCards = cards.filter { $0.subject == s.rawValue }
            let m = subCards.filter { $0.status == MasteryStatus.mastered.rawValue }.count
            return (s.rawValue, m, subCards.count)
        }.sorted { $0.total > $1.total }
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // 仪表盘：只有错题时显示
                if !cards.isEmpty {
                    dashboardSection
                }

                // 最近试卷
                recentDocumentsSection

                // 最近错题
                if !recentCards.isEmpty {
                    recentMistakesSection
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("首页")
        .searchable(text: $searchText, prompt: "搜索试卷")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isImporterPresented = true
                } label: {
                    Label("新增 PDF", systemImage: "plus")
                }
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else {
                    throw CocoaError(.fileNoSuchFile)
                }
                let imported = try StorageService.importPDF(from: url)
                let item = PDFDocumentItem(title: imported.title, localFileName: imported.fileName)
                modelContext.insert(item)
                try modelContext.save()
                selectedDocument = item
            } catch {
                alert = AppAlert(title: "无法导入 PDF", error: error)
            }
        }
        .fullScreenCover(item: $selectedDocument) { document in
            PDFWorkspaceView(document: document)
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("好"))
            )
        }
    }

    // MARK: Dashboard Section

    private var dashboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习概况")
                .font(.title2.bold())

            // 三格快速统计
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 14)],
                spacing: 14
            ) {
                DashTile(value: "\(cards.count)", label: "总错题", icon: "rectangle.stack.fill", color: .accentColor)
                DashTile(value: "\(unmasteredCount)", label: "待攻克", icon: "xmark.circle.fill", color: .red)
                DashTile(value: "\(masteredPct)%", label: "掌握率", icon: "checkmark.seal.fill", color: .green)
                DashTile(value: "+\(todayCount)", label: "今日新增", icon: "plus.circle.fill", color: .orange)
            }

            // 学科进度条（最多 5 科）
            if !subjectProgress.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("各科掌握进度")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(subjectProgress.prefix(5), id: \.subject) { item in
                        HStack(spacing: 10) {
                            Text(item.subject)
                                .font(.caption)
                                .frame(width: 72, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.secondary.opacity(0.12))
                                    Capsule()
                                        .fill(Color.green)
                                        .frame(
                                            width: item.total > 0
                                                ? geo.size.width * CGFloat(item.mastered) / CGFloat(item.total)
                                                : 0
                                        )
                                }
                            }
                            .frame(height: 8)
                            Text("\(item.mastered)/\(item.total)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .padding(16)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: Recent Documents Section

    private var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近试卷")
                .font(.title2.bold())

            if documents.isEmpty {
                ContentUnavailableView(
                    "还没有试卷",
                    systemImage: "doc",
                    description: Text("点击右上角 + 导入一份 PDF 开始做题。")
                )
                .frame(maxWidth: .infinity, minHeight: 240)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            } else if filteredDocuments.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity, minHeight: 240)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredDocuments) { document in
                        Button {
                            document.lastOpenDate = .now
                            selectedDocument = document
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "doc.fill")
                                    .font(.title)
                                    .foregroundStyle(.red)
                                    .frame(width: 50, height: 58)
                                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(document.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(document.lastOpenDate, format: .relative(presentation: .named))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 90)
                            .background(.background, in: RoundedRectangle(cornerRadius: 18))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18).stroke(.quaternary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("打开试卷")
                        .contextMenu {
                            Button("删除", systemImage: "trash", role: .destructive) {
                                deleteDocument(document)
                            }
                        }
                    }
                }
                .frame(maxWidth: 840)
            }
        }
    }

    private func deleteDocument(_ document: PDFDocumentItem) {
        do {
            let documentID = document.id
            let descriptor = FetchDescriptor<HandwritingLayer>(
                predicate: #Predicate { $0.documentId == documentID }
            )
            for layer in try modelContext.fetch(descriptor) {
                modelContext.delete(layer)
            }
            modelContext.delete(document)
            try modelContext.save()
            StorageService.deleteFile(at: document.localFileURL)
        } catch {
            alert = AppAlert(title: "无法删除试卷", error: error)
        }
    }

    // MARK: Recent Mistakes Section

    private var recentMistakesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近收录")
                .font(.title2.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(recentCards) { card in
                        VStack(alignment: .leading, spacing: 8) {
                            if let img = UIImage(contentsOfFile: card.imageURL.path) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 100)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.quaternary)
                                    .frame(width: 140, height: 100)
                            }
                            Text(card.subject)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text(card.createdAt, format: .dateTime.month().day())
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(width: 140)
                    }
                }
            }
        }
    }
}

// MARK: - Dashboard Tile

private struct DashTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }
}
