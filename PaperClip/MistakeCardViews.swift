import SwiftUI
import SwiftData

// MARK: - MistakeCardEditorView（极简宽屏编辑）

struct MistakeCardEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    let card: MistakeCard
    @AppStorage("preferredSubjects") var preferredSubjectsRaw = ""

    @State var relatedCandidateCards: [MistakeCardRowData] = []
    @State var newTagText = ""
    @State var alert: AppAlert?
    @State var isCropPresented = false
    @State var draftGrade = ""
    @State var draftSemester = ""
    @State var draftSubject = ""
    @State var draftQuestionType = ""
    @State var draftCorrectAnswer = ""
    @State var draftTagsText = ""
    @State var draftErrorReason = ""
    @State var draftStatus = ""
    @State var draftNote = ""
    @State var draftPrintWidthMM = 170.0
    @State var draftQuestionCrop: String?
    /// 打开时记录关键字段快照，用于判断是否有未保存改动
    @State var initialFingerprint = ""

    init(card: MistakeCard) {
        self.card = card
    }

    var currentFingerprint: String {
        "\(draftGrade)|\(draftSemester)|\(draftSubject)|\(draftQuestionType)|\(draftCorrectAnswer)|\(draftTagsText)|\(draftErrorReason)|\(draftStatus)|\(draftNote)|\(draftPrintWidthMM)|\(draftQuestionCrop ?? "")"
    }
    var hasChanges: Bool { !initialFingerprint.isEmpty && currentFingerprint != initialFingerprint }

    var draftTags: [String] {
        MistakeTagParser.parse(draftTagsText)
    }

    var subjectsForPicker: [Subject] {
        MistakeCardEditorDraftLogic.subjectsForPicker(
            preferredSubjectsRaw: preferredSubjectsRaw,
            currentSubject: draftSubject
        )
    }

    func addTags() {
        guard !MistakeTagParser.parse(newTagText).isEmpty else { return }
        draftTagsText = MistakeCardEditorDraftLogic.appendingTags(newTagText, to: draftTagsText)
        newTagText = ""
    }

    func removeTag(_ tag: String) {
        draftTagsText = MistakeCardEditorDraftLogic.removingTag(tag, from: draftTagsText)
    }

    var body: some View {
        let currentDraftTags = draftTags
        Form {
            metadataSection
            recognitionSection
            questionTypeSection
            answerSection
            tagSection(currentDraftTags)
            reviewSection
            printSizeSection
            relatedMistakesSection(currentDraftTags)
        }
        .navigationTitle("编辑错题卡")
        .navigationBarTitleDisplayMode(.inline)
        .doneToolbar { saveAndDismiss() }
        .interactiveDismissDisabled(hasChanges)
        .onAppear {
            loadDraftIfNeeded()
        }
        .task(id: card.id) {
            refreshRelatedCandidateCards()
        }
        .fullScreenCover(isPresented: $isCropPresented) {
            AsyncLocalImage(path: card.imageURL.path) { image in
                QuestionCropView(
                    image: image,
                    existingCrop: draftQuestionCrop
                ) { cropString in
                    draftQuestionCrop = cropString.isEmpty ? nil : cropString
                }
            } placeholder: {
                ProgressView("正在载入图片…")
            }
        }
        .appAlert($alert)
    }

}
