import SwiftUI

struct WritingFullscreenWriterSettingsMenu: View {
    let language: WritingLanguage
    let availablePaperStyles: [WritingPaperStyle]
    @Binding var paperStyle: WritingPaperStyle
    @Binding var blackPaperMode: Bool
    @Binding var isShowingRequirement: Bool
    @Binding var isShowingPaperSizing: Bool

    var body: some View {
        Menu {
            Button {
                isShowingRequirement = true
            } label: {
                Label("写作要求", systemImage: "doc.text")
            }

            Button {
                isShowingPaperSizing = true
            } label: {
                Label("纸张大小", systemImage: "ruler")
            }

            if language == .chinese {
                Picker("纸张", selection: $paperStyle) {
                    ForEach(availablePaperStyles) { style in
                        Text(style.title).tag(style)
                    }
                }
            }

            Toggle("黑纸白字", isOn: $blackPaperMode)
        } label: {
            Label("书写设置", systemImage: "slider.horizontal.3")
        }
    }
}

struct WritingRequirementSheet: View {
    let prompt: WritingPrompt
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                WritingRequirementContent(prompt: prompt)
                    .padding()
            }
            .navigationTitle("写作要求")
            .navigationBarTitleDisplayMode(.inline)
            .doneToolbar { isPresented = false }
        }
    }
}
