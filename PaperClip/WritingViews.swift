import SwiftUI
import SwiftData

struct WritingWorkspaceView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase

    let prompt: WritingPrompt

    @State var activeDraft: WritingDraft?
    @State var recentReviews: [WritingReviewRowData] = []
    @State var drawingStore = WritingDrawingStore()
    @State var drawingRevision = 0
    @State var paperStyle = WritingPaperStyle.lined
    @State var blackPaperMode = false
    @State var paperWidth = WritingPaperMetrics.defaultWidth
    @State var paperHeight = WritingPaperMetrics.defaultHeight
    @State var rulingSpacing = WritingPaperMetrics.defaultLineSpacing
    @State var isRequirementExpanded = false
    @State var isShowingFullscreenWriter = false
    @State var isShowingPaperSizing = false
    @State var phase = WritingWorkspacePhase.idle
    @State var recognitionText = ""
    @State var isShowingRecognitionSheet = false
    @State var presentedReview: WritingReviewRowData?
    @State var shouldRestartReviewAfterDismiss = false
    @State var alert: AppAlert?
    @State var autosaveAction = DebouncedAction()
    @State var hasLoadedDraft = false
    @State var isRestoringDraft = false
    @State var reviewTaskSlot = ViewTaskSlot()
    @State var drawingDataCache = WritingDrawingDataCache()

    var availablePaperStyles: [WritingPaperStyle] {
        WritingPaperStyle.available(for: prompt.language)
    }

    var paperSize: CGSize {
        WritingPaperMetrics.clampedSize(width: paperWidth, height: paperHeight)
    }

    var paperSettingsSnapshot: WritingPaperSettingsSnapshot {
        WritingPaperSettingsSnapshot(
            style: paperStyle,
            blackPaperMode: blackPaperMode,
            width: paperWidth,
            height: paperHeight,
            rulingSpacing: rulingSpacing
        )
    }

    var body: some View {
        workspacePresentationModifiers(
            ZStack {
                GeometryReader { proxy in
                    ScrollView([.vertical, .horizontal]) {
                        VStack(alignment: .leading, spacing: 16) {
                            requirementSection
                            writingControls
                            writingCanvas
                            latestReviewSection
                        }
                        .frame(width: paperSize.width, alignment: .leading)
                        .padding()
                        .frame(minWidth: proxy.size.width, alignment: .center)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                }

                if phase.isWorking {
                    workingOverlay
                }
            }
            .navigationTitle(prompt.generatedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                writingWorkspaceToolbarContent
            }
        )
        .appAlert($alert)
        .task(id: prompt.id) {
            loadDraftIfNeeded()
            refreshReviewSummaries()
        }
        .onDisappear {
            reviewTaskSlot.cancel()
            autosaveAction.cancel()
            saveDraft()
        }
        .onChange(of: paperSettingsSnapshot) { _, newValue in
            handlePaperSettingsChange(newValue)
        }
        .onChange(of: scenePhase) { _, newValue in
            handleScenePhaseChange(newValue)
        }
    }

}
