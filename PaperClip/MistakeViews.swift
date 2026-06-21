import SwiftUI
import SwiftData

struct MistakeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MistakeCard.createdAt, order: .reverse) private var cards: [MistakeCard]
    @Query(sort: \MistakePracticeLayer.createdAt) private var practiceLayers: [MistakePracticeLayer]

    @State private var searchText = ""
    @State private var selectedStatus = ""
    @State private var selectedSubject = ""
    @State private var selectedTag = ""
    @State private var selectedSource = ""
    @State private var editingCard: MistakeCard?
    @State private var isExportPresented = false
    @State private var isBulkUpgradeConfirmPresented = false
    @State private var isPracticePresented = false
    @State private var alert: AppAlert?

    private var filteredCards: [MistakeCard] {
        cards.filter { card in
            let matchesSearch = searchText.isEmpty ||
                card.subject.localizedCaseInsensitiveContains(searchText) ||
                card.grade.localizedCaseInsensitiveContains(searchText) ||
                card.tagsText.localizedCaseInsensitiveContains(searchText) ||
                card.note.localizedCaseInsensitiveContains(searchText) ||
                card.recognizedText.localizedCaseInsensitiveContains(searchText) ||
                card.sourceDocumentTitle.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus.isEmpty || card.status == selectedStatus
            let matchesSubject = selectedSubject.isEmpty || card.subject == selectedSubject
            let matchesTag = selectedTag.isEmpty || card.tags.contains(selectedTag)
            let matchesSource = selectedSource.isEmpty || card.sourceDocumentTitle == selectedSource
            return matchesSearch && matchesStatus && matchesSubject && matchesTag && matchesSource
        }
    }

    /// 所有非空来源试卷标题，去重后按首字母排序。
    private var allSources: [String] {
        Array(Set(cards.map(\.sourceDocumentTitle).filter { !$0.isEmpty })).sorted()
    }

    /// 所有错题卡 tag 按出错频率降序排列，最多取 15 个。
    private var topTags: [(tag: String, count: Int)] {
        var freq: [String: Int] = [:]
        for card in cards {
            for tag in card.tags { freq[tag, default: 0] += 1 }
        }
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

                // 掌握进度概览：有卡片时显示
                if !cards.isEmpty {
                    MasteryProgressBar(cards: cards)
                }

                ViewThatFits(in: .horizontal) {
                    HStack {
                        subjectPicker
                        statusPicker
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        subjectPicker
                        statusPicker
                    }
                }

                // 来源试卷筛选（有多份试卷时显示）
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
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
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

                // 薄弱知识点：按出错频率展示 tag，点击可筛选
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
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(
                                            isActive
                                                ? Color.orange.opacity(0.12)
                                                : Color.secondary.opacity(0.09),
                                            in: Capsule()
                                        )
                                        .overlay {
                                            Capsule()
                                                .stroke(
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
                                        : "试试调整学科或状态筛选条件。"
                        )
                    )
                    .frame(maxWidth: .infinity, minHeight: 420)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 18)], spacing: 18) {
                        ForEach(filteredCards) { card in
                            Button {
                                editingCard = card
                            } label: {
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
        .navigationTitle("错题库")
        .searchable(text: $searchText, prompt: "搜索学科、年级、标签、备注或试卷名")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // 批量升级：当前筛选结果中有未掌握/待复习的卡片时显示
                let upgradable = filteredCards.filter {
                    $0.status != MasteryStatus.mastered.rawValue
                }
                if !upgradable.isEmpty {
                    Button {
                        isBulkUpgradeConfirmPresented = true
                    } label: {
                        Label("批量升级", systemImage: "arrow.up.circle")
                    }
                    .tint(.green)
                }

                // 开始练习：以当前筛选结果启动练习模式
                Button {
                    isPracticePresented = true
                } label: {
                    Label("开始练习", systemImage: "play.circle.fill")
                }
                .tint(.orange)
                .disabled(filteredCards.isEmpty)

                Button {
                    isExportPresented = true
                } label: {
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
            NavigationStack {
                MistakeCardEditorView(card: card)
            }
        }
        .sheet(isPresented: $isExportPresented) {
            NavigationStack {
                ExportView()
            }
        }
        // 练习模式：全屏，以当前筛选结果启动
        .fullScreenCover(isPresented: $isPracticePresented) {
            MistakePracticeView(
                cards: filteredCards,
                practiceGroupID: UUID(),
                round: 1
            )
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("好"))
            )
        }
    }

    private var subjectPicker: some View {
        Picker("学科", selection: $selectedSubject) {
            Text("全部学科").tag("")
            ForEach(Subject.allCases) { Text($0.rawValue).tag($0.rawValue) }
        }
        .frame(maxWidth: 240)
    }

    private var statusPicker: some View {
        Picker("状态", selection: $selectedStatus) {
            Text("全部状态").tag("")
            ForEach(MasteryStatus.allCases) { Text($0.rawValue).tag($0.rawValue) }
        }
        .frame(maxWidth: 240)
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            alert = AppAlert(title: "无法保存更改", error: error)
        }
    }

    private func deleteCard(_ card: MistakeCard) {
        do {
            for layer in practiceLayers where layer.cardID == card.id {
                modelContext.delete(layer)
            }
            modelContext.delete(card)
            try modelContext.save()
            StorageService.deleteFile(at: card.imageURL)
        } catch {
            alert = AppAlert(title: "无法删除错题", error: error)
        }
    }
}

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

    /// 该卡片累计被练习的轮数（去重 groupID × round 组合）
    private var practiceRoundCount: Int {
        Set(practiceLayers.map { "\($0.practiceGroupID)-\($0.round)" }).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = UIImage(contentsOfFile: card.imageURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, minHeight: 130, maxHeight: 210)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        VStack(spacing: 4) {
                            RecognitionStatusBadge(status: card.recognitionStatus)
                            // 练习次数角标
                            if practiceRoundCount > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "pencil.and.list.clipboard")
                                        .imageScale(.small)
                                    Text("×\(practiceRoundCount)")
                                }
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.orange, in: Capsule())
                            }
                        }
                        .padding(8)
                    }
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 160)
                    .overlay { Image(systemName: "photo").foregroundStyle(.secondary) }
            }

            HStack {
                Text(card.subject.isEmpty ? "未设置学科" : card.subject)
                    .font(.headline)
                Spacer()
                StatusBadge(status: card.status)
            }
            Text([card.grade, card.semester, card.tags.first ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if !card.sourceDocumentTitle.isEmpty {
                Text(card.sourceDocumentTitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Text(card.createdAt, format: .dateTime.year().month().day())
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(.quaternary)
        }
    }
}

struct MistakeCardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: MistakeCard
    @Query(sort: \MistakeCard.createdAt, order: .reverse) private var allCards: [MistakeCard]
    @State private var newTagText = ""
    @State private var alert: AppAlert?

    private func addTags() {
        let candidates = newTagText
            .components(separatedBy: CharacterSet(charactersIn: ",，\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !candidates.isEmpty else { return }

        var tags = card.tags
        var existing = Set(tags)
        for tag in candidates where existing.insert(tag).inserted {
            tags.append(tag)
        }
        card.tagsText = tags.joined(separator: ",")
        newTagText = ""
        card.updatedAt = .now
    }

    private func removeTag(_ tag: String) {
        card.tagsText = card.tags
            .filter { $0 != tag }
            .joined(separator: ",")
        card.updatedAt = .now
    }

    /// 按共同知识点数量降序排列的相关错题，最多 5 张。
    private var relatedCards: [MistakeCard] {
        let myTags = Set(card.tags)
        guard !myTags.isEmpty else { return [] }
        return allCards
            .filter { other in
                other.id != card.id && !Set(other.tags).isDisjoint(with: myTags)
            }
            .sorted {
                Set($0.tags).intersection(myTags).count > Set($1.tags).intersection(myTags).count
            }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        Form {
            Section {
                if let image = UIImage(contentsOfFile: card.imageURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 320)
                        .background(.white)
                }
            }

            // 识别结果区
            recognitionSection

            Section("基本信息") {
                if !card.sourceDocumentTitle.isEmpty {
                    LabeledContent("来源试卷", value: card.sourceDocumentTitle)
                        .foregroundStyle(.secondary)
                }
                Picker("年级", selection: $card.grade) {
                    ForEach(Grade.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("学科", selection: $card.subject) {
                    ForEach(Subject.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("学期", selection: $card.semester) {
                    ForEach(Semester.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("标签")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if card.tags.isEmpty {
                        Text("暂无标签")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    } else {
                        KnowledgeTagLayout(spacing: 8) {
                            ForEach(card.tags, id: \.self) { tag in
                                EditableMistakeTag(title: tag) {
                                    removeTag(tag)
                                }
                            }
                        }
                    }

                    HStack {
                        TextField("新增标签", text: $newTagText)
                            .submitLabel(.done)
                            .onSubmit(addTags)

                        Button("添加", action: addTags)
                            .disabled(
                                newTagText
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                            )
                    }
                }
            }

            Section("复习信息") {
                Picker("错误原因", selection: $card.errorReason) {
                    ForEach(ErrorReason.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                HStack {
                    Picker("掌握状态", selection: $card.status) {
                        ForEach(MasteryStatus.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    if card.status != MasteryStatus.mastered.rawValue {
                        Spacer()
                        Button("升一级") {
                            card.status = MasteryStatus.nextLevel(after: card.status).rawValue
                            card.updatedAt = .now
                        }
                        .font(.subheadline)
                        .buttonStyle(.bordered)
                        .tint(.green)
                        .controlSize(.small)
                    }
                }
                TextField("备注", text: $card.note, axis: .vertical)
                    .lineLimit(3...8)
            }

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

            // 相关错题：按共同知识点数量排序
            if !relatedCards.isEmpty {
                Section {
                    ForEach(relatedCards) { related in
                        let sharedTags = Set(related.tags).intersection(Set(card.tags))
                        NavigationLink {
                            MistakeCardEditorView(card: related)
                        } label: {
                            HStack(spacing: 12) {
                                if let image = UIImage(contentsOfFile: related.imageURL.path) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 45)
                                        .background(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(related.subject)
                                        .font(.subheadline)
                                    Text(sharedTags.sorted().prefix(3).joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .lineLimit(1)
                                    Text(related.createdAt, format: .dateTime.year().month().day())
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                StatusBadge(status: related.status)
                            }
                            .padding(.vertical, 2)
                        }
                        .accessibilityLabel("\(related.subject)，共同知识点：\(sharedTags.sorted().joined(separator: "、"))")
                    }
                } header: {
                    Label("相关错题", systemImage: "link")
                } footer: {
                    Text("与本题存在共同知识点。点击编辑对应错题可查看详情。")
                }
            }
        }
        .navigationTitle("编辑错题卡")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    saveAndDismiss()
                }
            }
        }
        .interactiveDismissDisabled()
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("好"))
            )
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
                RecognitionPreviewView(
                    question: card.recognizedText,
                    isEmbedded: true
                )
            }

        case .processing:
            Section("AI 识别结果") {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("正在识别…")
                        .foregroundStyle(.secondary)
                }
            }

        case .failed:
            Section("AI 识别结果") {
                HStack {
                    Label("识别失败", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
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
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

        case .pending:
            Section("AI 识别结果") {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("等待识别…")
                        .foregroundStyle(.secondary)
                }
            }

        default:
            EmptyView()
        }
    }
}

/// 错题卡右上角的识别状态角标，仅在非 completed 状态下显示。
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

/// 错题库顶部掌握状态进度概览。
private struct MasteryProgressBar: View {
    let cards: [MistakeCard]

    private var masteredCount: Int {
        cards.filter { $0.status == MasteryStatus.mastered.rawValue }.count
    }
    private var reviewCount: Int {
        cards.filter { $0.status == MasteryStatus.review.rawValue }.count
    }
    private var unmasteredCount: Int {
        cards.filter { $0.status == MasteryStatus.unmastered.rawValue }.count
    }
    private var total: Int { cards.count }
    private var masteredPct: Int {
        total > 0 ? Int(Double(masteredCount) / Double(total) * 100) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 分段进度条：已掌握/待复习/未掌握 三色
            GeometryReader { proxy in
                let w = proxy.size.width
                HStack(spacing: 0) {
                    if masteredCount > 0 {
                        Color.green
                            .frame(width: w * CGFloat(masteredCount) / CGFloat(total))
                    }
                    if reviewCount > 0 {
                        Color.orange
                            .frame(width: w * CGFloat(reviewCount) / CGFloat(total))
                    }
                    // 未掌握填满剩余空间（避免浮点偏差留缝）
                    if unmasteredCount > 0 {
                        Color.red.opacity(0.65)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .frame(height: 10)
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))

            // 图例 + 百分比
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    statLabel(count: masteredCount, label: "已掌握", icon: "checkmark.circle.fill", color: .green)
                    Spacer()
                    statLabel(count: reviewCount, label: "待复习", icon: "clock.fill", color: .orange)
                    Spacer()
                    statLabel(count: unmasteredCount, label: "未掌握", icon: "xmark.circle.fill", color: .red)
                    Spacer()
                    masteryPercentage
                }

                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    GridRow {
                        statLabel(count: masteredCount, label: "已掌握", icon: "checkmark.circle.fill", color: .green)
                        statLabel(count: reviewCount, label: "待复习", icon: "clock.fill", color: .orange)
                    }
                    GridRow {
                        statLabel(count: unmasteredCount, label: "未掌握", icon: "xmark.circle.fill", color: .red)
                        masteryPercentage
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("掌握进度：\(masteredPct)%已掌握，共 \(total) 张错题")
    }

    private func statLabel(count: Int, label: String, icon: String, color: Color) -> some View {
        Label {
            Text("\(count) \(label)")
        } icon: {
            Image(systemName: icon)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(color)
    }

    private var masteryPercentage: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(masteredPct)%")
                .font(.title3.bold().monospacedDigit())
            Text("掌握")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status {
        case MasteryStatus.mastered.rawValue: .green
        case MasteryStatus.review.rawValue: .orange
        default: .red
        }
    }

    var body: some View {
        Text(status)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private struct EditableMistakeTag: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.small)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("移除标签 \(title)")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Color.accentColor)
        .padding(.leading, 11)
        .padding(.trailing, 7)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .contain)
    }
}
