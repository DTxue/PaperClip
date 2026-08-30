import SwiftUI
import SwiftData
import PhotosUI
import VisionKit
import AVFoundation

private struct PendingMistakeAttachment: Identifiable {
    let id = UUID()
    let data: Data
    let pathExtension: String?
    let originalFileName: String
}

struct MistakeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MistakeAttachment.sortIndex)
    private var storedAttachments: [MistakeAttachment]

    let item: MistakeLibraryItem?

    @State private var questionText: String
    @State private var subject: String
    @State private var grade: String
    @State private var semester: String
    @State private var source: String
    @State private var tagsText: String
    @State private var selectedErrorReasons: Set<String>
    @State private var customErrorReason: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingAttachments: [PendingMistakeAttachment] = []
    @State private var cropQueue: [MistakeCropSource] = []
    @State private var activeCropSource: MistakeCropSource?
    @State private var scanSession: MistakeDocumentScanSession?
    @State private var isScanning = false
    @State private var isRequestingCameraAccess = false
    @State private var isRecognizing = false
    @State private var isSaving = false
    @State private var recognitionTask: Task<Void, Never>?
    @State private var cameraAccessTask: Task<Void, Never>?
    @State private var alert: AppAlert?

    init(item: MistakeLibraryItem? = nil) {
        self.item = item
        let errorReasonDraft = MistakeErrorReasonDraft.parse(item?.errorReason ?? "")
        _questionText = State(initialValue: item?.questionText ?? "")
        _subject = State(initialValue: item?.subject ?? Subject.math.rawValue)
        _grade = State(initialValue: item?.grade ?? Grade.grade7.rawValue)
        _semester = State(initialValue: item?.semester ?? Semester.first.rawValue)
        _source = State(initialValue: item?.source ?? "")
        _tagsText = State(initialValue: item?.tagsText ?? "")
        _selectedErrorReasons = State(initialValue: errorReasonDraft.selected)
        _customErrorReason = State(initialValue: errorReasonDraft.custom)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("错题图片") {
                    if hasAttachments {
                        VStack(spacing: 14) {
                            ForEach(existingAttachments) { attachment in
                                storedAttachmentPreview(attachment)
                            }
                            ForEach(pendingAttachments) { attachment in
                                pendingAttachmentPreview(attachment)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    HStack {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("从相册录入", systemImage: "photo.on.rectangle")
                        }
                        Spacer()
                        if VNDocumentCameraViewController.isSupported {
                            Button {
                                openDocumentScanner()
                            } label: {
                                if isRequestingCameraAccess {
                                    Label("正在准备相机…", systemImage: "camera")
                                } else {
                                    Label("扫描文档录入", systemImage: "doc.viewfinder")
                                }
                            }
                            .disabled(isRequestingCameraAccess)
                        }
                    }
                    Text("选择相册图片或完成文档扫描后，需要手动框选一道错题。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        recognizeQuestionText()
                    } label: {
                        if isRecognizing {
                            Label("豆包正在识别并整理…", systemImage: "sparkles")
                        } else {
                            Label("识别题目并整理", systemImage: "text.viewfinder")
                        }
                    }
                    .disabled(!hasAttachments || isRecognizing)
                }

                Section("题目文字") {
                    TextEditor(text: $questionText)
                        .frame(minHeight: 110)
                    if !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("公式预览")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            MistakeQuestionTextView(text: questionText)
                        }
                    }
                    Text("豆包识别结果会显示在这里，并自动填写学科、年级和知识点；所有内容均可手动修改。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("整理") {
                    Picker("学科", selection: $subject) {
                        ForEach(Subject.allCases) { subject in
                            Text(subject.rawValue).tag(subject.rawValue)
                        }
                    }
                    Picker("年级", selection: $grade) {
                        ForEach(Grade.allCases) { grade in
                            Text(grade.rawValue).tag(grade.rawValue)
                        }
                    }
                    Picker("学期", selection: $semester) {
                        ForEach(Semester.allCases) { semester in
                            Text(semester.rawValue).tag(semester.rawValue)
                        }
                    }
                    TextField("来源，例如：数学练习册第 24 页", text: $source)
                    TextField("知识点，用逗号分隔", text: $tagsText)
                }

                Section("错误原因") {
                    KnowledgeTagLayout(spacing: 8) {
                        ForEach(MistakeErrorReasonTag.allCases) { reason in
                            errorReasonButton(reason)
                        }
                    }
                    TextField("其他原因（可选）", text: $customErrorReason)
                }
            }
            .navigationTitle(item == nil ? "录入错题" : "编辑错题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave || isSaving || isRecognizing)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("正在保存…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onDisappear {
            recognitionTask?.cancel()
            cameraAccessTask?.cancel()
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task { await loadPhoto(newValue) }
        }
        .fullScreenCover(isPresented: $isScanning, onDismiss: presentNextCrop) {
            MistakeDocumentScanner(
                onComplete: { scan in
                    scanSession = MistakeDocumentScanSession(scan: scan)
                    isScanning = false
                },
                onCancel: { isScanning = false },
                onFailure: { error in
                    isScanning = false
                    alert = AppAlert(title: "扫描错题失败", error: error)
                }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $activeCropSource, onDismiss: presentNextCrop) { source in
            MistakeCropView(
                source: source,
                onComplete: { data in
                    pendingAttachments.append(
                        PendingMistakeAttachment(
                            data: data,
                            pathExtension: "jpg",
                            originalFileName: source.originalFileName
                        )
                    )
                    activeCropSource = nil
                },
                onCancel: {
                    activeCropSource = nil
                }
            )
        }
        .appAlert($alert)
    }

    private var canSave: Bool {
        item != nil || !pendingAttachments.isEmpty
    }

    private var existingAttachments: [MistakeAttachment] {
        guard let item else { return [] }
        return storedAttachments.filter { $0.itemID == item.id }
    }

    private var hasAttachments: Bool {
        !existingAttachments.isEmpty || !pendingAttachments.isEmpty
    }

    private func storedAttachmentPreview(
        _ attachment: MistakeAttachment
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            MistakeAttachmentThumbnail(fileName: attachment.fileName)
                .frame(maxWidth: .infinity, maxHeight: 360)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("已保存图片 \(attachment.originalFileName)")
            Text(attachment.originalFileName.isEmpty ? "已保存图片" : attachment.originalFileName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func pendingAttachmentPreview(
        _ attachment: PendingMistakeAttachment
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 5) {
                Group {
                    if let image = UIImage(data: attachment.data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "photo")
                            .frame(maxWidth: .infinity, minHeight: 160)
                            .background(.secondary.opacity(0.12))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 360)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("已录入图片 \(attachment.originalFileName)")

                Text(attachment.originalFileName.isEmpty ? "待保存图片" : attachment.originalFileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button(role: .destructive) {
                pendingAttachments.removeAll { $0.id == attachment.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
            }
            .buttonStyle(.borderless)
            .disabled(isRecognizing)
            .accessibilityLabel("移除 \(attachment.originalFileName)")
            .padding(6)
        }
    }

    private func errorReasonButton(_ reason: MistakeErrorReasonTag) -> some View {
        let isSelected = selectedErrorReasons.contains(reason.rawValue)
        let color = errorReasonColor(reason)
        return Button {
            if isSelected {
                selectedErrorReasons.remove(reason.rawValue)
            } else {
                selectedErrorReasons.insert(reason.rawValue)
            }
        } label: {
            HStack(spacing: 5) {
                Text(reason.rawValue)
                    .lineLimit(1)
                if isSelected {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                color.opacity(isSelected ? 0.22 : 0.11),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(color.opacity(isSelected ? 0.85 : 0.3), lineWidth: isSelected ? 1.5 : 1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func errorReasonColor(_ reason: MistakeErrorReasonTag) -> Color {
        switch reason {
        case .careless: .orange
        case .misunderstood: .pink
        case .concept: .purple
        case .calculation: .blue
        case .method: .indigo
        case .omitted: .teal
        }
    }

    @MainActor
    private func loadPhoto(_ photo: PhotosPickerItem) async {
        do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            guard let image = UIImage(data: data) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            selectedPhoto = nil
            enqueueForCropping([
                MistakeCropSource(image: image, originalFileName: "相册图片")
            ])
        } catch {
            selectedPhoto = nil
            alert = AppAlert(title: "读取图片失败", error: error)
        }
    }

    private func enqueueForCropping(_ sources: [MistakeCropSource]) {
        cropQueue.append(contentsOf: sources)
        guard !isScanning else { return }
        presentNextCrop()
    }

    private func openDocumentScanner() {
        let state: MistakeCameraAuthorizationState = switch AVCaptureDevice.authorizationStatus(
            for: .video
        ) {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .restricted
        }

        switch MistakeScannerAccessPolicy.action(for: state) {
        case .presentScanner:
            isScanning = true
        case .showPermissionError:
            alert = AppAlert(
                title: "无法使用相机",
                message: "请在系统设置中允许 PaperClip 使用相机后，再扫描文档。"
            )
        case .requestAccess:
            requestCameraAccessAndOpenScanner()
        }
    }

    private func requestCameraAccessAndOpenScanner() {
        guard !isRequestingCameraAccess else { return }
        isRequestingCameraAccess = true
        cameraAccessTask?.cancel()
        cameraAccessTask = Task {
            defer {
                isRequestingCameraAccess = false
                cameraAccessTask = nil
            }
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard !Task.isCancelled else { return }
            if granted {
                isScanning = true
            } else {
                alert = AppAlert(
                    title: "无法使用相机",
                    message: "相机权限未开启，请在系统设置中允许 PaperClip 使用相机。"
                )
            }
        }
    }

    private func presentNextCrop() {
        guard activeCropSource == nil, !isScanning else { return }
        if !cropQueue.isEmpty {
            activeCropSource = cropQueue.removeFirst()
            return
        }
        if let nextPage = scanSession?.nextCropSource() {
            activeCropSource = nextPage
        } else {
            scanSession = nil
        }
    }

    private func recognizeQuestionText() {
        let existingImages = existingAttachments.compactMap { attachment in
            UIImage(contentsOfFile: StoredFile.mistakeAttachment(fileName: attachment.fileName).url.path)
        }
        let pendingImages = pendingAttachments.compactMap { UIImage(data: $0.data) }
        let images = existingImages + pendingImages
        guard existingImages.count == existingAttachments.count,
              pendingImages.count == pendingAttachments.count,
              !images.isEmpty
        else {
            alert = AppAlert(title: "无法识别图片", message: "图片数据不完整，请重新录入。")
            return
        }

        recognitionTask?.cancel()
        isRecognizing = true
        let questionTextAtRequestStart = questionText
        let subjectAtRequestStart = subject
        let gradeAtRequestStart = grade
        recognitionTask = Task {
            do {
                let result = try await AIService.recognizeMistakeImages(images)
                try Task.checkCancellation()
                let recognized = result.questionText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !recognized.isEmpty else {
                    alert = AppAlert(title: "未识别到题目文字", message: "请调整框选范围后重新录入，或手动输入题目。")
                    isRecognizing = false
                    recognitionTask = nil
                    return
                }
                if MistakeRecognitionAutofill.shouldApplyRecognizedValue(
                    current: questionText,
                    requestStart: questionTextAtRequestStart
                ) {
                    questionText = recognized
                }
                applyRecognizedOrganization(
                    result,
                    subjectAtRequestStart: subjectAtRequestStart,
                    gradeAtRequestStart: gradeAtRequestStart
                )
                isRecognizing = false
                recognitionTask = nil
            } catch is CancellationError {
                isRecognizing = false
                recognitionTask = nil
            } catch {
                alert = AppAlert(title: "识别图片文字失败", error: error)
                isRecognizing = false
                recognitionTask = nil
            }
        }
    }

    private func applyRecognizedOrganization(
        _ result: AIMistakeRecognitionResult,
        subjectAtRequestStart: String,
        gradeAtRequestStart: String
    ) {
        if MistakeRecognitionAutofill.shouldApplyRecognizedValue(
            current: subject,
            requestStart: subjectAtRequestStart
        ),
           let recognizedSubject = result.subject,
           let resolvedSubject = Subject.from(aiString: recognizedSubject) {
            subject = resolvedSubject.rawValue
        }

        if MistakeRecognitionAutofill.shouldApplyRecognizedValue(
            current: grade,
            requestStart: gradeAtRequestStart
        ),
           let recognizedGrade = result.grade,
           let resolvedGrade = Grade.allCases.first(where: {
               $0.rawValue == recognizedGrade || recognizedGrade.contains($0.rawValue)
           }) {
            grade = resolvedGrade.rawValue
        }

        tagsText = MistakeRecognitionAutofill.mergedKnowledgePoints(
            existing: tagsText,
            recognized: result.knowledgePoints ?? []
        )
    }

    private func save() {
        isSaving = true
        do {
            try MistakeLibraryPersistence.saveItem(
                existing: item,
                input: MistakeEditorInput(
                    questionText: questionText,
                    errorReason: MistakeErrorReasonDraft.storedValue(
                        selected: selectedErrorReasons,
                        custom: customErrorReason
                    ),
                    subject: subject,
                    grade: grade,
                    semester: semester,
                    source: source,
                    tagsText: tagsText
                ),
                pendingAttachments: pendingAttachments.map {
                    MistakePendingAttachment(
                        data: $0.data,
                        pathExtension: $0.pathExtension,
                        originalFileName: $0.originalFileName
                    )
                },
                in: modelContext
            )
            dismiss()
        } catch {
            alert = AppAlert(title: "保存错题失败", error: error)
            isSaving = false
        }
    }
}
