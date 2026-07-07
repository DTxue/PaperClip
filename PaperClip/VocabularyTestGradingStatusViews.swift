import SwiftUI

struct VocabularyTestGradingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VocabularyTestExamFinalizingView: View {
    let gradedBatchCount: Int
    let batchCount: Int

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text("正在完成后台批阅")
                .font(.headline)
            Text("已批阅 \(gradedBatchCount) / \(batchCount) 组")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VocabularyTestFailureView: View {
    let failedBatchIndices: [Int]
    let batches: [VocabularyTestBatch]
    let retryAll: () -> Void
    let retryBatch: (Int) -> Void

    var body: some View {
        List {
            Section {
                ContentUnavailableView {
                    Label("部分批阅未完成", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("以下组别已自动重试一次，仍未完成批阅。请手动重新提交 AI 批阅。")
                } actions: {
                    Button("重新批阅失败组", systemImage: "arrow.clockwise") {
                        retryAll()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .listRowBackground(Color.clear)

            Section("失败组别") {
                ForEach(failedBatchIndices, id: \.self) { index in
                    if batches.indices.contains(index) {
                        VocabularyTestFailedBatchRow(
                            batch: batches[index],
                            retry: { retryBatch(index) }
                        )
                    }
                }
            }
        }
    }
}

private struct VocabularyTestFailedBatchRow: View {
    let batch: VocabularyTestBatch
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("第 \(batch.id + 1) 组")
                    .font(.headline)
                Spacer()
                Button("重新批阅", action: retry)
                    .buttonStyle(.bordered)
            }
            Text("题目 \(batch.startIndex + 1)-\(batch.endIndex + 1)，已尝试 \(batch.gradingAttempts) 次")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let error = batch.errorMessage, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 6)
    }
}
