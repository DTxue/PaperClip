import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum AppSection: Int {
    case home
    case papers
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

            Tab("试卷库", systemImage: "doc.on.doc", value: .papers) {
                NavigationStack {
                    PaperLibraryView()
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
                SettingsView()
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}

// MARK: - 常用学科解析（设置中的 preferredSubjects）

enum PreferredSubjects {
    static func parse(_ raw: String) -> [String] {
        raw.split(separator: ",").map(String.init).filter { !$0.isEmpty }
    }

    /// 默认导入学科：第一个常用学科，否则数学。
    static func defaultSubject(_ raw: String) -> String {
        parse(raw).sorted().first ?? Subject.math.rawValue
    }
}

// MARK: - Home View（仪表盘：按常用学科的试卷入口）

struct HomeView: View {
    @Query(sort: \MistakeCard.createdAt, order: .reverse) private var cards: [MistakeCard]

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if !cards.isEmpty {
                    dashboardSection
                } else {
                    ContentUnavailableView(
                        "还没有错题",
                        systemImage: "rectangle.stack",
                        description: Text("在「试卷库」打开 PDF 做题，框选错题后自动建卡。")
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("首页")
    }

    private var dashboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习概况")
                .font(.title2.bold())

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 14)],
                spacing: 14
            ) {
                DashTile(value: "\(cards.count)", label: "总错题", icon: "rectangle.stack.fill", color: .accentColor)
                DashTile(value: "\(unmasteredCount)", label: "待攻克", icon: "xmark.circle.fill", color: .red)
                DashTile(value: "\(masteredPct)%", label: "掌握率", icon: "checkmark.seal.fill", color: .green)
                DashTile(value: "+\(todayCount)", label: "今日新增", icon: "plus.circle.fill", color: .orange)
            }
        }
    }
}

// MARK: - 试卷库（按学科入口）

struct PaperLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PDFDocumentItem.lastOpenDate, order: .reverse) private var documents: [PDFDocumentItem]
    @AppStorage("preferredSubjects") private var preferredSubjectsRaw = ""
    @AppStorage("defaultGrade") private var defaultGrade = Grade.grade7.rawValue
    @AppStorage("defaultSemester") private var defaultSemester = Semester.first.rawValue

    @State private var isImporterPresented = false
    @State private var selectedDocument: PDFDocumentItem?
    @State private var alert: AppAlert?

    private var visibleSubjects: [Subject] {
        let withData = Set(documents.map(\.subject))
        let preferred = Set(PreferredSubjects.parse(preferredSubjectsRaw))
        let union = withData.union(preferred)
        return Subject.allCases.filter { union.contains($0.rawValue) }
    }

    private func paperCount(for subject: Subject) -> Int {
        documents.filter { $0.subject == subject.rawValue }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if visibleSubjects.isEmpty {
                    ContentUnavailableView {
                        Label("还没有试卷", systemImage: "doc")
                    } description: {
                        Text("点击右上角 + 导入一份 PDF，或在「设置 → 学习设置」中开启常用学科。")
                    } actions: {
                        Button("导入 PDF", systemImage: "plus") { isImporterPresented = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 180), spacing: 16)],
                        spacing: 16
                    ) {
                        NavigationLink {
                            PaperSubjectView(subject: nil)
                        } label: {
                            PaperSubjectCard(title: "全部试卷", icon: "tray.full", count: documents.count)
                        }
                        .buttonStyle(.plain)

                        ForEach(visibleSubjects) { subject in
                            NavigationLink {
                                PaperSubjectView(subject: subject.rawValue)
                            } label: {
                                PaperSubjectCard(
                                    title: subject.rawValue,
                                    icon: subject.sfSymbol,
                                    count: paperCount(for: subject)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: 980)
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("试卷库")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isImporterPresented = true } label: {
                    Label("新增 PDF", systemImage: "plus")
                }
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            importPDF(from: result)
        }
        .fullScreenCover(item: $selectedDocument) { document in
            PDFWorkspaceView(document: document)
        }
        .appAlert($alert)
    }

    private func importPDF(from result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { throw CocoaError(.fileNoSuchFile) }
            let imported = try StorageService.importPDF(from: url)
            let item = PDFDocumentItem(
                title: imported.title,
                localFileName: imported.fileName,
                grade: defaultGrade,
                semester: defaultSemester,
                subject: PreferredSubjects.defaultSubject(preferredSubjectsRaw)
            )
            modelContext.insert(item)
            try modelContext.save()
            selectedDocument = item
        } catch {
            alert = AppAlert(title: "无法导入 PDF", error: error)
        }
    }
}

// MARK: - 学科试卷入口卡片

private struct PaperSubjectCard: View {
    let title: String
    let icon: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.accentColor)
                .frame(width: 52, height: 52)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))

            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text(count == 0 ? "暂无试卷" : "\(count) 份试卷")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.quaternary) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(count == 0 ? "暂无试卷" : "\(count)份试卷")")
        .accessibilityHint("查看该学科试卷")
    }
}

// MARK: - 学科试卷列表（年级/学期筛选 + 导入）

struct PaperSubjectView: View {
    let subject: String? // nil = 全部

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PDFDocumentItem.lastOpenDate, order: .reverse) private var allDocuments: [PDFDocumentItem]
    @AppStorage("defaultGrade") private var defaultGrade = Grade.grade7.rawValue
    @AppStorage("defaultSemester") private var defaultSemester = Semester.first.rawValue

    @State private var searchText = ""
    @State private var selectedGrade = ""
    @State private var selectedSemester = ""
    @State private var isImporterPresented = false
    @State private var selectedDocument: PDFDocumentItem?
    @State private var editingDocument: PDFDocumentItem?
    @State private var documentToDelete: PDFDocumentItem?
    @State private var alert: AppAlert?

    private var documents: [PDFDocumentItem] {
        allDocuments.filter { subject == nil || $0.subject == subject }
    }

    private var filteredDocuments: [PDFDocumentItem] {
        documents.filter { doc in
            let matchesSearch = searchText.isEmpty
                || doc.title.localizedCaseInsensitiveContains(searchText)
            let matchesGrade = selectedGrade.isEmpty || doc.grade == selectedGrade
            let matchesSemester = selectedSemester.isEmpty || doc.semester == selectedSemester
            return matchesSearch && matchesGrade && matchesSemester
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            filterSidebar
                .navigationTitle(subject ?? "全部试卷")
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
                .toolbar(removing: .sidebarToggle)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { isImporterPresented = true } label: {
                            Label("新增 PDF", systemImage: "plus")
                        }
                    }
                }
        } detail: {
            documentList
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $searchText, prompt: "搜索试卷")
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            importPDF(from: result)
        }
        .fullScreenCover(item: $selectedDocument) { document in
            PDFWorkspaceView(document: document)
        }
        .sheet(item: $editingDocument) { document in
            NavigationStack { PaperEditorView(document: document) }
        }
        .confirmationDialog(
            "删除试卷「\(documentToDelete?.title ?? "")」？",
            isPresented: Binding(
                get: { documentToDelete != nil },
                set: { if !$0 { documentToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let doc = documentToDelete { deleteDocument(doc) }
                documentToDelete = nil
            }
            Button("取消", role: .cancel) { documentToDelete = nil }
        } message: {
            Text("同时删除该试卷的所有答题记录，无法撤销。")
        }
        .appAlert($alert)
    }

    private var filterSidebar: some View {
        List {
            Section("年级") {
                sidebarRow(label: "全部年级", isActive: selectedGrade.isEmpty) {
                    selectedGrade = ""
                }
                ForEach(Grade.allCases) { grade in
                    sidebarRow(label: grade.rawValue, isActive: selectedGrade == grade.rawValue) {
                        selectedGrade = selectedGrade == grade.rawValue ? "" : grade.rawValue
                    }
                }
            }
            Section("学期") {
                sidebarRow(label: "全部学期", isActive: selectedSemester.isEmpty) {
                    selectedSemester = ""
                }
                ForEach(Semester.allCases) { semester in
                    sidebarRow(label: semester.rawValue, isActive: selectedSemester == semester.rawValue) {
                        selectedSemester = selectedSemester == semester.rawValue ? "" : semester.rawValue
                    }
                }
            }
            if !selectedGrade.isEmpty || !selectedSemester.isEmpty {
                Section {
                    Button(role: .destructive) {
                        selectedGrade = ""
                        selectedSemester = ""
                    } label: {
                        Label("清除筛选", systemImage: "xmark.circle").foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func sidebarRow(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundStyle(isActive ? Color.accentColor : .primary)
                    .fontWeight(isActive ? .semibold : .regular)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isActive
                ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                : nil
        )
    }

    private var documentList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if filteredDocuments.isEmpty {
                    ContentUnavailableView {
                        Label(documents.isEmpty ? "还没有试卷" : "没有符合条件的试卷", systemImage: "doc")
                    } description: {
                        Text(documents.isEmpty
                             ? "点击右上角 + 导入一份 PDF 开始做题。"
                             : "试试调整年级或学期筛选条件。")
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredDocuments) { document in
                            Button {
                                document.lastOpenDate = .now
                                selectedDocument = document
                            } label: {
                                PaperRow(document: document)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("打开试卷")
                            .contextMenu {
                                Button("编辑分类", systemImage: "pencil") { editingDocument = document }
                                Divider()
                                Button("删除", systemImage: "trash", role: .destructive) {
                                    documentToDelete = document
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 840)
                }
            }
            .frame(maxWidth: 1_200, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private func importPDF(from result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                throw CocoaError(.fileNoSuchFile)
            }
            let imported = try StorageService.importPDF(from: url)
            let item = PDFDocumentItem(
                title: imported.title,
                localFileName: imported.fileName,
                grade: selectedGrade.isEmpty ? defaultGrade : selectedGrade,
                semester: selectedSemester.isEmpty ? defaultSemester : selectedSemester,
                subject: subject ?? PreferredSubjects.defaultSubject("")
            )
            modelContext.insert(item)
            try modelContext.save()
            selectedDocument = item
        } catch {
            alert = AppAlert(title: "无法导入 PDF", error: error)
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
}

// MARK: - 试卷行

private struct PaperRow: View {
    @Bindable var document: PDFDocumentItem
    @State private var isRenaming = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.fill")
                .font(.title)
                .foregroundStyle(.red)
                .frame(width: 50, height: 58)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                if isRenaming {
                    TextField("试卷名称", text: $document.title)
                        .font(.headline)
                        .focused($titleFocused)
                        .onSubmit { isRenaming = false }
                        .onChange(of: titleFocused) { _, focused in
                            if !focused { isRenaming = false }
                        }
                } else {
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    Text([document.grade, document.semester, document.subject].joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(document.lastOpenDate, format: .dateTime.year().month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if !isRenaming {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.quaternary) }
        .contextMenu {
            Button("重命名", systemImage: "pencil") {
                isRenaming = true
                titleFocused = true
            }
        }
    }
}

// MARK: - 试卷分类编辑

struct PaperEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var document: PDFDocumentItem
    @State private var alert: AppAlert?

    var body: some View {
        Form {
            Section("名称") {
                TextField("试卷名称", text: $document.title)
            }
            Section("分类") {
                Picker("年级", selection: $document.grade) {
                    ForEach(Grade.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("学期", selection: $document.semester) {
                    ForEach(Semester.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("学科", selection: $document.subject) {
                    ForEach(Subject.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
            }
        }
        .navigationTitle("编辑试卷")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { save() }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
        }
        .appAlert($alert)
    }

    private func save() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alert = AppAlert(title: "无法保存试卷", error: error)
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
