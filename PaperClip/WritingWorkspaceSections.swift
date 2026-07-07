import SwiftUI

extension WritingWorkspaceView {
    var workingOverlay: some View {
        ProgressView(phase.title)
            .padding(18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    var requirementSection: some View {
        DisclosureGroup(isExpanded: $isRequirementExpanded) {
            WritingRequirementContent(prompt: prompt)
            .padding(.top, 8)
        } label: {
            Label("写作要求", systemImage: "doc.text")
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    var writingControls: some View {
        HStack(spacing: 16) {
            if prompt.language == .chinese {
                Picker("纸张", selection: $paperStyle) {
                    ForEach(availablePaperStyles) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            } else {
                Label("英文写作使用横线纸", systemImage: "line.3.horizontal")
                    .foregroundStyle(.secondary)
            }

            Toggle("黑纸白字", isOn: $blackPaperMode)
                .toggleStyle(.switch)
                .frame(width: 160)

            Button {
                isShowingPaperSizing = true
            } label: {
                Label("纸张大小", systemImage: "ruler")
            }

            Button {
                isShowingFullscreenWriter = true
            } label: {
                Label("全屏书写", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .disabled(phase.isWorking)

            Spacer()

            if let activeDraft {
                Text("自动保存：\(activeDraft.updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var writingCanvas: some View {
        WritingPaperCanvasView(
            drawingStore: drawingStore,
            paperSize: paperSize,
            paperStyle: paperStyle,
            blackPaperMode: blackPaperMode,
            rulingSpacing: rulingSpacing,
            reloadToken: drawingRevision,
            onDrawingChanged: scheduleAutosave
        )
    }

}
