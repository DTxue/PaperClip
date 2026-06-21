import SwiftUI
import SwiftData

// MARK: - MistakeLibraryView（学科索引，顶层）

struct MistakeLibraryView: View {
    @Query(sort: \MistakeCard.createdAt, order: .reverse) private var allCards: [MistakeCard]
    @AppStorage("preferredSubjects") private var preferredSubjectsRaw = ""

    /// 需要展示的学科：有数据的学科 ∪ 常用学科（即使卡片数为 0 也显示）
    private var visibleSubjects: [Subject] {
        let withData = Set(allCards.map(\.subject))
        let preferred = Set(
            preferredSubjectsRaw.split(separator: ",")
                .map(String.init)
                .filter { !$0.isEmpty }
        )
        let union = withData.union(preferred)
        return Subject.allCases.filter { union.contains($0.rawValue) }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14)],
                spacing: 14
            ) {
                if !allCards.isEmpty {
                    NavigationLink {
                        SubjectMistakesView(subject: nil)
                    } label: {
                        SubjectIndexCard(label: "全部", icon: "tray.full", cards: allCards)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(visibleSubjects) { subject in
                    let subCards = allCards.filter { $0.subject == subject.rawValue }
                    NavigationLink {
                        SubjectMistakesView(subject: subject.rawValue)
                    } label: {
                        SubjectIndexCard(label: subject.rawValue, icon: subject.sfSymbol, cards: subCards)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationTitle("错题库")
        .overlay {
            if allCards.isEmpty {
                ContentUnavailableView(
                    "还没有错题",
                    systemImage: "rectangle.stack",
                    description: Text("在 PDF 做题页使用「框选错题」创建第一张错题卡。")
                )
            }
        }
    }
}

// MARK: - SubjectIndexCard

private struct SubjectIndexCard: View {
    let label: String
    let icon: String
    let cards: [MistakeCard]

    private var masteredCount: Int {
        cards.filter { $0.status == MasteryStatus.mastered.rawValue }.count
    }
    private var total: Int { cards.count }
    private var pct: Double { total > 0 ? Double(masteredCount) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text(total == 0 ? "0" : "\(total)")
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Text(label)
                .font(.headline)
                .foregroundStyle(.primary)

            if total > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.15))
                            Capsule().fill(Color.green)
                                .frame(width: geo.size.width * pct)
                        }
                    }
                    .frame(height: 5)

                    Text("掌握 \(Int(pct * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("暂无错题")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)，\(total)张，掌握率\(Int(pct * 100))%")
    }
}

// MARK: - SubjectMistakesView（学科内卡片网格）

struct SubjectMistakesView: View {
    let subject: String? // nil = 全部

    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [MistakeCard]
    @Query(sort: \MistakePracticeLayer.createdAt) private var practiceLayers: [MistakePracticeLayer]

    @State private var searchText = ""
    @State private var selectedStatus = ""
    @State private var selectedQuestionType = ""
    @State private var selectedTag = ""
    @State private var selectedSource = ""
    @State private var editingCard: MistakeCard?
    @State private var isExportPresented = false
    @State private var isBulkUpgradeConfirmPresented = false
    @State private var isPracticePresented = false
    @State private var isPaperSelectionPresented = false
    @State private var alert: AppAlert?

    init(subject: String?) {
        self.subject = subject
        if let s = subject {
            _cards = Query(
                filter: #Predicate<MistakeCard> { $0.subject == s },
                sort: \MistakeCard.createdAt,
                order: .reverse
            )
        } else {
            _cards = Query(sort: \MistakeCard.createdAt, order: .reverse)
        }
    }

    private var filteredCards: [MistakeCard] {
        cards.filter { card in
            let matchesSearch = searchText.isEmpty
                || card.subject.localizedCaseInsensitiveContains(searchText)
                || card.grade.localizedCaseInsensitiveContains(searchText)
                || card.tagsText.localizedCaseInsensitiveContains(searchText)
                || card.note.localizedCaseInsensitiveContains(searchText)
                || card.recognizedText.localizedCaseInsensitiveContains(searchText)
                || card.correctAnswer.localizedCaseInsensitiveContains(searchText)
                || card.resolvedQuestionType.rawValue.localizedCaseInsensitiveContains(searchText)
                || card.sourceDocumentTitle.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus.isEmpty || card.status == selectedStatus
            let matchesQuestionType = selectedQuestionType.isEmpty
                || card.resolvedQuestionType.rawValue == selectedQuestionType
            let matchesTag = selectedTag.isEmpty || card.tags.contains(selectedTag)
            let matchesSource = selectedSource.isEmpty || card.sourceDocumentTitle == selectedSource
            return matchesSearch
                && matchesStatus
                && matchesQuestionType
                && matchesTag
                && matchesSource
        }
    }

    private var allSources: [String] {
        Array(Set(cards.map(\.sourceDocumentTitle).filter { !$0.isEmpty })).sorted()
    }

    private var topTags: [(tag: String, count: Int)] {
        var freq: [String: Int] = [:]
        for card in cards { for tag in card.tags { freq[tag, default: 0] += 1 } }
        return freq
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(15)
            .map { (tag: $0.key, count: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(filteredCards.count) 张错题")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !cards.isEmpty {
                    MasteryProgressBar(cards: cards)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        statusPicker
                        questionTypePicker
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        statusPicker
                        questionTypePicker
                    }
                }

                if allSources.count > 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("来源试卷", systemImage: "doc.text")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            if !selectedSource.isEmpty {
                                Spacer()
                                Button("清除") { selectedSource = "" }
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allSources, id: \.self) { source in
                                    let isActive = selectedSource == source
                                    Button {
                                        selectedSource = isActive ? "" : source
                                    } label: {
                                        Text(source)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(isActive ? .white : .primary)
                                            .padding(.horizontal, 14).padding(.vertical, 7)
                                            .background(
                                                isActive ? Color.accentColor : Color.secondary.opacity(0.09),
                                                in: Capsule()
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(source)
                                    .accessibilityAddTraits(isActive ? .isSelected : [])
                                }
                            }
                        }
                    }
                }

                if !topTags.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("薄弱知识点", systemImage: "chart.bar.xaxis.ascending")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            if !selectedTag.isEmpty {
                                Spacer()
                                Button("清除筛选") { selectedTag = "" }
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(topTags, id: \.tag) { item in
                                    let isActive = selectedTag == item.tag
                                    Button {
                                        selectedTag = isActive ? "" : item.tag
                                    } label: {
                                        HStack(spacing: 5) {
                                            Text(item.tag)
                                            Text("×\(item.count)")
                                                .foregroundStyle(isActive ? .orange.opacity(0.7) : .secondary)
                                        }
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(isActive ? .orange : .primary)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(
                                            isActive ? Color.orange.opacity(0.12) : Color.secondary.opacity(0.09),
                                            in: Capsule()
                                        )
                                        .overlay {
                                            Capsule().stroke(
                                                isActive ? Color.orange.opacity(0.35) : Color.clear,
                                                lineWidth: 1
                                            )
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(item.tag)，出错\(item.count)次")
                                    .accessibilityAddTraits(isActive ? .isSelected : [])
                                }
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }

                if filteredCards.isEmpty {
                    ContentUnavailableView(
                        cards.isEmpty ? "还没有错题" : "没有符合条件的错题",
                        systemImage: "rectangle.stack",
                        description: Text(
                            cards.isEmpty
                                ? "在 PDF 做题页使用「框选错题」创建第一张错题卡。"
                                : !selectedSource.isEmpty
                                    ? "试卷「\(selectedSource)」下暂无符合条件的错题。"
                                    : !selectedTag.isEmpty
                                        ? "知识点「\(selectedTag)」下暂无错题。"
                                        : "试试调整状态筛选条件。"
                        )
                    )
                    .frame(maxWidth: .infinity, minHeight: 380)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 280), spacing: 18)],
                        spacing: 18
                    ) {
                        ForEach(filteredCards) { card in
                            Button { editingCard = card } label: {
                                MistakeCardTile(card: card)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("编辑错题卡")
                            .contextMenu {
                                Button("编辑", systemImage: "pencil") { editingCard = card }
                                if card.status != MasteryStatus.mastered.rawValue {
                                    Button("升一级掌握状态", systemImage: "arrow.up.circle") {
                                        card.status = MasteryStatus.nextLevel(after: card.status).rawValue
                                        card.updatedAt = .now
                                        saveChanges()
                                    }
                                }
                                Divider()
                                Button("删除", systemImage: "trash", role: .destructive) {
                                    deleteCard(card)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 1_400, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(subject ?? "全部错题")
        .searchable(text: $searchText, prompt: "搜索标签、备注或试卷名")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                let upgradable = filteredCards.filter {
                    $0.status != MasteryStatus.mastered.rawValue
                }
                if !upgradable.isEmpty {
                    Button { isBulkUpgradeConfirmPresented = true } label: {
                        Label("批量升级", systemImage: "arrow.up.circle")
                    }
                    .tint(.green)
                }
                Button { isPracticePresented = true } label: {
                    Label("开始练习", systemImage: "play.circle.fill")
                }
                .tint(.orange)
                .disabled(filteredCards.isEmpty)

                Button { isPaperSelectionPresented = true } label: {
                    Label("出卷", systemImage: "doc.text.below.ecg")
                }
                .disabled(filteredCards.isEmpty)

                Button { isExportPresented = true } label: {
                    Label("生成错题集", systemImage: "doc.badge.plus")
                }
                .disabled(cards.isEmpty)
            }
        }
        .confirmationDialog(
            "将 \(filteredCards.filter { $0.status != MasteryStatus.mastered.rawValue }.count) 张错题的掌握状态升一级？",
            isPresented: $isBulkUpgradeConfirmPresented,
            titleVisibility: .visible
        ) {
            Button("升级") {
                for card in filteredCards where card.status != MasteryStatus.mastered.rawValue {
                    card.status = MasteryStatus.nextLevel(after: card.status).rawValue
                    card.updatedAt = .now
                }
                saveChanges()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("未掌握 → 待复习 → 已掌握。此操作仅影响当前筛选结果。")
        }
        .sheet(item: $editingCard) { card in
            NavigationStack { MistakeCardEditorView(card: card) }
                .presentationDetents([.large])
        }
        .sheet(isPresented: $isExportPresented) {
            NavigationStack { ExportView() }
        }
        .fullScreenCover(isPresented: $isPracticePresented) {
            MistakePracticeView(cards: filteredCards, practiceGroupID: UUID(), round: 1)
        }
        .sheet(isPresented: $isPaperSelectionPresented) {
            PaperCardSelectionView(availableCards: filteredCards, subject: subject)
        }
        .appAlert($alert)
    }

    private var statusPicker: some View {
        Picker("状态", selection: $selectedStatus) {
            Text("全部状态").tag("")
            ForEach(MasteryStatus.allCases) { Text($0.rawValue).tag($0.rawValue) }
        }
        .frame(maxWidth: 240)
    }

    private var questionTypePicker: some View {
        Picker("题型", selection: $selectedQuestionType) {
            Text("全部题型").tag("")
            ForEach(QuestionType.allCases) { type in
                Label(type.rawValue, systemImage: type.systemImage)
                    .tag(type.rawValue)
            }
        }
        .frame(maxWidth: 240)
    }

    private func saveChanges() {
        do { try modelContext.save() }
        catch { alert = AppAlert(title: "无法保存更改", error: error) }
    }

    private func deleteCard(_ card: MistakeCard) {
        do {
            for layer in practiceLayers where layer.cardID == card.id { modelContext.delete(layer) }
            modelContext.delete(card)
            try modelContext.save()
            StorageService.deleteFile(at: card.imageURL)
        } catch {
            alert = AppAlert(title: "无法删除错题", error: error)
        }
    }
}

// MARK: - MistakeCardTile（文字预览 + 截图降级）

private struct MistakeCardTile: View {
    let card: MistakeCard
    @Query private var practiceLayers: [MistakePracticeLayer]

    init(card: MistakeCard) {
        self.card = card
        let id = card.id
        _practiceLayers = Query(
            filter: #Predicate<MistakePracticeLayer> { $0.cardID == id },
            sort: \.createdAt
        )
    }

    private var practiceRoundCount: Int {
        Set(practiceLayers.map { "\($0.practiceGroupID)-\($0.round)" }).count
    }

    private var showTextPreview: Bool {
        card.recognitionStatus == RecognitionStatus.completed.rawValue
            && !card.recognizedText.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                previewArea
                VStack(spacing: 4) {
                    RecognitionStatusBadge(status: card.recognitionStatus)
                    if practiceRoundCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "pencil.and.list.clipboard").imageScale(.small)
                            Text("×\(practiceRoundCount)")
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(.orange, in: Capsule())
                    }
                }
                .padding(8)
            }

            HStack {
                Text(card.subject.isEmpty ? "未分类" : card.subject).font(.headline)
                Spacer()
                StatusBadge(status: card.status)
            }
            Text(
                [card.grade, card.semester, card.resolvedQuestionType.rawValue, card.tags.first ?? ""]
                    .filter { !$0.isEmpty }.joined(separator: " · ")
            )
            .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            if !card.sourceDocumentTitle.isEmpty {
                Text(card.sourceDocumentTitle).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
            }
            Text(card.createdAt, format: .dateTime.year().month().day())
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.quaternary) }
    }

    @ViewBuilder
    private var previewArea: some View {
        if showTextPreview {
            // 已识别：复用集中式 KaTeX 渲染，并裁切为卡片预览高度。
            RecognitionPreviewView(question: card.recognizedText, isEmbedded: true)
                .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 180, alignment: .topLeading)
                .clipped()
                .padding(12)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("题目预览：\(card.recognizedText)")
        } else {
            // 降级：截图预览（CardImage 内置占位符处理图片缺失）
            CardImage(url: card.imageURL, maxPixelSize: 600)
                .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 180)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - MistakeCardEditorView（极简宽屏编辑）

struct MistakeCardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: MistakeCard
    @Query(sort: \MistakeCard.createdAt, order: .reverse) private var allCards: [MistakeCard]
    @AppStorage("preferredSubjects") private var preferredSubjectsRaw = ""

    @State private var newTagText = ""
    @State private var alert: AppAlert?
    @State private var isCropPresented = false
    /// 打开时记录关键字段快照，用于判断是否有未保存改动
    @State private var initialFingerprint = ""

    private var currentFingerprint: String {
        "\(card.grade)|\(card.semester)|\(card.subject)|\(card.questionType)|\(card.correctAnswer)|\(card.tagsText)|\(card.errorReason)|\(card.status)|\(card.note)|\(card.printWidthMM)|\(card.questionCrop ?? "")"
    }
    private var hasChanges: Bool { !initialFingerprint.isEmpty && currentFingerprint != initialFingerprint }

    /// 编辑器中供选择的学科列表。
    /// 若配置了常用学科，则只显示这些；但始终包含当前卡片的学科，防止已有数据「消失」。
    private var subjectsForPicker: [Subject] {
        let preferred = Set(
            preferredSubjectsRaw.split(separator: ",")
                .map(String.init)
                .filter { !$0.isEmpty }
        )
        if preferred.isEmpty { return Subject.allCases }
        var result = Subject.allCases.filter { preferred.contains($0.rawValue) }
        // 保证当前卡片的学科始终可选
        if let current = Subject.allCases.first(where: { $0.rawValue == card.subject }),
           !result.contains(current) {
            result.append(current)
        }
        return result
    }

    private func addTags() {
        let candidates = newTagText
            .components(separatedBy: CharacterSet(charactersIn: ",，\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !candidates.isEmpty else { return }
        var tags = card.tags
        var existing = Set(tags)
        for tag in candidates where existing.insert(tag).inserted { tags.append(tag) }
        card.tagsText = tags.joined(separator: ",")
        newTagText = ""
        card.updatedAt = .now
    }

    private func removeTag(_ tag: String) {
        card.tagsText = card.tags.filter { $0 != tag }.joined(separator: ",")
        card.updatedAt = .now
    }

    private var relatedCards: [MistakeCard] {
        let myTags = Set(card.tags)
        guard !myTags.isEmpty else { return [] }
        return allCards
            .filter { $0.id != card.id && !Set($0.tags).isDisjoint(with: myTags) }
            .sorted {
                Set($0.tags).intersection(myTags).count > Set($1.tags).intersection(myTags).count
            }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        Form {
            // ── 顶部：缩略图 + 年级 / 学科 / 学期 ──
            Section {
                HStack(alignment: .top, spacing: 14) {
                    thumbnailView

                    VStack(alignment: .leading, spacing: 2) {
                        if !card.sourceDocumentTitle.isEmpty {
                            Text(card.sourceDocumentTitle)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .padding(.bottom, 4)
                        }
                        HStack(spacing: 4) {
                            Picker("年级", selection: $card.grade) {
                                ForEach(Grade.allCases) { Text($0.rawValue).tag($0.rawValue) }
                            }
                            .pickerStyle(.menu)

                            Picker("学科", selection: $card.subject) {
                                ForEach(subjectsForPicker) {
                                    Text($0.rawValue).tag($0.rawValue)
                                }
                            }
                            .pickerStyle(.menu)

                            Picker("学期", selection: $card.semester) {
                                ForEach(Semester.allCases) { Text($0.rawValue).tag($0.rawValue) }
                            }
                            .pickerStyle(.menu)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            // ── AI 识别结果 ──
            recognitionSection

            Section("题型分类") {
                Picker("题型", selection: $card.questionType) {
                    ForEach(QuestionType.allCases) { type in
                        Label(type.rawValue, systemImage: type.systemImage)
                            .tag(type.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Text("AI 会自动判断题型；你可以在此手动修改，出卷时将按该题型生成对应答题区域。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("正确答案") {
                TextField(
                    "AI 尚未生成答案，可在此手动填写",
                    text: $card.correctAnswer,
                    axis: .vertical
                )
                .lineLimit(2...8)

                if !card.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    RecognitionPreviewView(question: card.correctAnswer, isEmbedded: true)
                        .accessibilityLabel("正确答案：\(card.correctAnswer)")
                }

                Text("选择题填写选项字母，判断题填写“正确”或“错误”；公式可使用 LaTeX。交卷时将用此答案批改。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // ── 知识点标签 ──
            Section("知识点标签") {
                if card.tags.isEmpty {
                    Text("暂无标签").font(.subheadline).foregroundStyle(.tertiary)
                } else {
                    KnowledgeTagLayout(spacing: 8) {
                        ForEach(card.tags, id: \.self) { tag in
                            EditableMistakeTag(title: tag) { removeTag(tag) }
                        }
                    }
                }
                HStack {
                    TextField("新增标签（逗号分隔）", text: $newTagText)
                        .submitLabel(.done)
                        .onSubmit(addTags)
                    Button("添加", action: addTags)
                        .disabled(
                            newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                }
            }

            // ── 复习信息：错误原因 + 掌握状态 并排 + 备注 ──
            Section("复习信息") {
                HStack(spacing: 8) {
                    Picker("错误原因", selection: $card.errorReason) {
                        ForEach(ErrorReason.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 22)

                    Picker("掌握状态", selection: $card.status) {
                        ForEach(MasteryStatus.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)

                    if card.status != MasteryStatus.mastered.rawValue {
                        Button("升一级") {
                            card.status = MasteryStatus.nextLevel(after: card.status).rawValue
                            card.updatedAt = .now
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.green)
                    }
                }

                TextField("备注", text: $card.note, axis: .vertical)
                    .lineLimit(2...6)
            }

            // ── 打印尺寸 ──
            Section("打印尺寸") {
                LabeledContent("原始比例", value: String(format: "%.2f : 1", card.aspectRatio))
                HStack {
                    Text("打印宽度")
                    Slider(value: $card.printWidthMM, in: 40...190, step: 1)
                    Text("\(Int(card.printWidthMM)) mm")
                        .monospacedDigit()
                        .frame(width: 66, alignment: .trailing)
                }
                LabeledContent(
                    "打印高度",
                    value: "\(Int(card.printWidthMM / max(card.aspectRatio, 0.01))) mm"
                )
            }

            // ── 相关错题 ──
            if !relatedCards.isEmpty {
                Section {
                    ForEach(relatedCards) { related in
                        let sharedTags = Set(related.tags).intersection(Set(card.tags))
                        NavigationLink {
                            MistakeCardEditorView(card: related)
                        } label: {
                            HStack(spacing: 12) {
                                CardImage(url: related.imageURL, maxPixelSize: 200)
                                    .frame(width: 60, height: 45)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(related.subject).font(.subheadline)
                                    Text(sharedTags.sorted().prefix(3).joined(separator: " · "))
                                        .font(.caption).foregroundStyle(.orange).lineLimit(1)
                                    Text(related.createdAt, format: .dateTime.year().month().day())
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                StatusBadge(status: related.status)
                            }
                            .padding(.vertical, 2)
                        }
                        .accessibilityLabel(
                            "\(related.subject)，共同知识点：\(sharedTags.sorted().joined(separator: "、"))"
                        )
                    }
                } header: {
                    Label("相关错题", systemImage: "link")
                } footer: {
                    Text("与本题存在共同知识点。")
                }
            }
        }
        .navigationTitle("编辑错题卡")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { saveAndDismiss() }
            }
        }
        .interactiveDismissDisabled(hasChanges)
        .onAppear {
            card.questionType = card.resolvedQuestionType.rawValue
            if initialFingerprint.isEmpty { initialFingerprint = currentFingerprint }
        }
        .fullScreenCover(isPresented: $isCropPresented) {
            if let image = UIImage(contentsOfFile: card.imageURL.path) {
                QuestionCropView(
                    image: image,
                    existingCrop: card.questionCrop
                ) { cropString in
                    card.questionCrop = cropString.isEmpty ? nil : cropString
                    card.updatedAt = .now
                }
            }
        }
        .appAlert($alert)
    }

    private var thumbnailView: some View {
        ZStack(alignment: .bottomTrailing) {
            CardImage(url: card.imageURL, maxPixelSize: 300)
                .frame(width: 88, height: 72)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button { isCropPresented = true } label: {
                Image(systemName: card.questionCrop != nil ? "crop.rotate" : "crop")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(
                        card.questionCrop != nil ? Color.accentColor : Color.secondary.opacity(0.85),
                        in: RoundedRectangle(cornerRadius: 4)
                    )
            }
            .buttonStyle(.plain)
            .padding(4)
            .accessibilityLabel(card.questionCrop != nil ? "重新框选题目图片区域" : "框选题目图片区域")
        }
    }

    private func saveAndDismiss() {
        card.printHeightMM = card.printWidthMM / max(card.aspectRatio, 0.01)
        card.updatedAt = .now
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alert = AppAlert(title: "无法保存错题卡", error: error)
        }
    }

    @ViewBuilder
    private var recognitionSection: some View {
        let status = RecognitionStatus(rawValue: card.recognitionStatus) ?? .completed

        switch status {
        case .completed where !card.recognizedText.isEmpty:
            Section("AI 识别结果") {
                RecognitionPreviewView(question: card.recognizedText, isEmbedded: true)
            }
        case .processing:
            Section("AI 识别结果") {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("正在识别…").foregroundStyle(.secondary)
                }
            }
        case .failed:
            Section("AI 识别结果") {
                HStack {
                    Label("识别失败", systemImage: "exclamationmark.circle").foregroundStyle(.orange)
                    Spacer()
                    Button("重试") {
                        card.recognitionStatus = RecognitionStatus.pending.rawValue
                        do {
                            try modelContext.save()
                            MistakeCardRecognitionService.shared.enqueue(
                                cardID: card.id,
                                imagePath: card.imageURL.path
                            )
                        } catch {
                            alert = AppAlert(title: "无法重新识别", error: error)
                        }
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                }
            }
        case .pending:
            Section("AI 识别结果") {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("等待识别…").foregroundStyle(.secondary)
                }
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Supporting Views

private struct RecognitionStatusBadge: View {
    let status: String

    var body: some View {
        switch status {
        case RecognitionStatus.pending.rawValue, RecognitionStatus.processing.rawValue:
            ProgressView()
                .controlSize(.mini)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityLabel("识别中")
        case RecognitionStatus.failed.rawValue:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
                .imageScale(.medium)
                .padding(4)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityLabel("识别失败")
        default:
            EmptyView()
        }
    }
}

private struct MasteryProgressBar: View {
    let cards: [MistakeCard]

    private var masteredCount: Int   { cards.filter { $0.status == MasteryStatus.mastered.rawValue }.count }
    private var reviewCount: Int     { cards.filter { $0.status == MasteryStatus.review.rawValue }.count }
    private var unmasteredCount: Int { cards.filter { $0.status == MasteryStatus.unmastered.rawValue }.count }
    private var total: Int           { cards.count }
    private var masteredPct: Int     { total > 0 ? Int(Double(masteredCount) / Double(total) * 100) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                let w = proxy.size.width
                HStack(spacing: 0) {
                    if masteredCount > 0 {
                        Color.green.frame(width: w * CGFloat(masteredCount) / CGFloat(total))
                    }
                    if reviewCount > 0 {
                        Color.orange.frame(width: w * CGFloat(reviewCount) / CGFloat(total))
                    }
                    if unmasteredCount > 0 { Color.red.opacity(0.65) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .frame(height: 10)
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    statLabel(count: masteredCount, label: "已掌握", icon: "checkmark.circle.fill", color: .green)
                    Spacer()
                    statLabel(count: reviewCount,   label: "待复习", icon: "clock.fill",            color: .orange)
                    Spacer()
                    statLabel(count: unmasteredCount, label: "未掌握", icon: "xmark.circle.fill",   color: .red)
                    Spacer()
                    masteryPercentage
                }

                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    GridRow {
                        statLabel(count: masteredCount, label: "已掌握", icon: "checkmark.circle.fill", color: .green)
                        statLabel(count: reviewCount,   label: "待复习", icon: "clock.fill",            color: .orange)
                    }
                    GridRow {
                        statLabel(count: unmasteredCount, label: "未掌握", icon: "xmark.circle.fill", color: .red)
                        masteryPercentage
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("掌握进度：\(masteredPct)%已掌握，共 \(total) 张错题")
    }

    private func statLabel(count: Int, label: String, icon: String, color: Color) -> some View {
        Label { Text("\(count) \(label)") } icon: { Image(systemName: icon) }
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
    }

    private var masteryPercentage: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(masteredPct)%").font(.title3.bold().monospacedDigit())
            Text("掌握").font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status {
        case MasteryStatus.mastered.rawValue: .green
        case MasteryStatus.review.rawValue:   .orange
        default:                              .red
        }
    }

    var body: some View {
        Text(status)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private struct EditableMistakeTag: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Text(title).lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill").imageScale(.small)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("移除标签 \(title)")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Color.accentColor)
        .padding(.leading, 11).padding(.trailing, 7).padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
        .overlay { Capsule().stroke(Color.accentColor.opacity(0.25), lineWidth: 1) }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Subject SF Symbol

extension Subject {
    var sfSymbol: String {
        switch self {
        case .math:      return "function"
        case .chinese:   return "character.book.closed"
        case .english:   return "globe"
        case .physics:   return "atom"
        case .chemistry: return "flask"
        case .biology:   return "leaf"
        case .history:   return "building.columns"
        case .geography: return "map"
        case .politics:  return "scale.3d"
        case .music:     return "music.note"
        case .art:       return "paintpalette"
        case .pe:        return "figure.run"
        case .it:        return "laptopcomputer"
        }
    }
}
