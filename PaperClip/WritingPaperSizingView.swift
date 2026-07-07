import SwiftUI

struct WritingPaperSizingView: View {
    @Environment(\.dismiss) private var dismiss

    let paperStyle: WritingPaperStyle
    @Binding var paperWidth: Double
    @Binding var paperHeight: Double
    @Binding var rulingSpacing: Double
    let onReset: () -> Void

    private var spacingTitle: String {
        switch paperStyle {
        case .lined: "横线行距"
        case .grid: "方格大小"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $paperWidth, in: WritingPaperMetrics.minWidth...WritingPaperMetrics.maxWidth, step: 20) {
                        LabeledContent("宽度", value: "\(Int(paperWidth)) pt")
                    }
                    Stepper(value: $paperHeight, in: WritingPaperMetrics.minHeight...WritingPaperMetrics.maxHeight, step: 50) {
                        LabeledContent("高度", value: "\(Int(paperHeight)) pt")
                    }
                } header: {
                    Text("纸张尺寸")
                } footer: {
                    Text("宽度和高度决定可书写范围；调大后可获得更大的书写空间，超出屏幕时可滚动。")
                }

                Section {
                    Stepper(
                        value: $rulingSpacing,
                        in: WritingPaperMetrics.minRulingSpacing...WritingPaperMetrics.maxRulingSpacing,
                        step: 2
                    ) {
                        LabeledContent(spacingTitle, value: "\(Int(rulingSpacing)) pt")
                    }
                } footer: {
                    Text("字写得偏大时可以调大行距或方格；字写得偏小时可以调小。")
                }

                Section {
                    Button("恢复默认纸张") {
                        onReset()
                    }
                }
            }
            .navigationTitle("纸张大小")
            .navigationBarTitleDisplayMode(.inline)
            .doneToolbar { dismiss() }
        }
    }
}
