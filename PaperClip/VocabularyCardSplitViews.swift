import SwiftData
import SwiftUI

struct VocabularyCardSplitView: View {
    let deck: VocabularyDeck
    let card: VocabularyCard

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State var isLoading = true
    @State var splits: [VocabularyCardSplitResult.SplitCard] = []
    @State var errorMessage: String?
    @State var splitTaskSlot = ViewTaskSlot()
    @State var alert: AppAlert?

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("AI 正在拆分…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("拆分失败", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("重试") { startLoad() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.term).font(.headline)
                            Text(card.definition).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    } header: {
                        Text("原卡片")
                    }

                    Section {
                        ForEach(splits.indices, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(splits[i].term).font(.headline)
                                Text(splits[i].definition).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("拆分为 \(splits.count) 张")
                    } footer: {
                        Text("确认后原卡片将被删除，替换为以上拆分结果。")
                    }
                }
            }
        }
        .navigationTitle("智能拆分")
        .navigationBarTitleDisplayMode(.inline)
        .appAlert($alert)
        .cancelToolbar { dismiss() }
        .toolbar {
            if !splits.isEmpty {
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认拆分") { confirmSplit() }
                        .disabled(splits.count < 2)
                }
            }
        }
        .task { startLoad() }
        .onDisappear {
            cancelSplitTask()
        }
    }
}
