import SwiftUI
import SwiftData
import UIKit

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MistakeCard.createdAt, order: .reverse) private var cards: [MistakeCard]

    @State private var selectedIDs: Set<UUID> = []
    @State private var layout: ExportLayout = .two
    @State private var kind: ExportKind = .practice
    @State private var groupBySubject = false
    @State private var includeCoverPage = true
    @State private var generatedURL: URL?
    @State private var alert: AppAlert?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GroupBox("导出设置") {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 20) {
                            kindPicker
                            layoutPicker
                            optionToggles
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            kindPicker
                            layoutPicker
                            optionToggles
                        }
                    }
                    .padding(.top, 8)
                }

                Text("已选择 \(selectedIDs.count) 张，共 \(cards.count) 张")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                cardSelection
            }
            .frame(maxWidth: 1_400, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("生成错题集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    generatePDF()
                } label: {
                    Label("生成 PDF", systemImage: "doc.badge.plus")
                }
                .disabled(selectedIDs.isEmpty)

                if let generatedURL {
                    ShareLink(item: generatedURL) {
                        Label("分享 PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("好"))
            )
        }
    }

    private var kindPicker: some View {
        Picker("版本", selection: $kind) {
            ForEach(ExportKind.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 280)
    }

    private var layoutPicker: some View {
        Picker("排版", selection: $layout) {
            ForEach(ExportLayout.allCases) { Text($0.title).tag($0) }
        }
        .frame(maxWidth: 220)
    }

    private var optionToggles: some View {
        HStack {
            Toggle("包含封面", isOn: $includeCoverPage)
            Toggle("按学科分组", isOn: $groupBySubject)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var cardSelection: some View {
        Group {
            if cards.isEmpty {
                ContentUnavailableView(
                    "还没有错题卡",
                    systemImage: "doc.badge.plus",
                    description: Text("先在 PDF 中框选题目，再到这里生成错题集。")
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 16)], spacing: 16) {
                    ForEach(cards) { card in
                        Button {
                            if selectedIDs.contains(card.id) {
                                selectedIDs.remove(card.id)
                            } else {
                                selectedIDs.insert(card.id)
                            }
                        } label: {
                            SelectableCard(
                                card: card,
                                isSelected: selectedIDs.contains(card.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(
                            selectedIDs.contains(card.id) ? .isSelected : []
                        )
                    }
                }
            }
        }
    }

    private func generatePDF() {
        let selectedCards = cards.filter { selectedIDs.contains($0.id) }
        do {
            let title = "错题集-\(Date.now.formatted(.dateTime.year().month().day()))"
            let url = try MistakePDFExporter.export(
                title: title,
                cards: selectedCards,
                layout: layout,
                kind: kind,
                groupBySubject: groupBySubject,
                includeCoverPage: includeCoverPage
            )
            let record = ExportRecord(
                title: title,
                cardIDs: selectedCards.map(\.id),
                layoutType: layout.title,
                exportType: kind.rawValue,
                pdfFileName: url.lastPathComponent
            )
            modelContext.insert(record)
            do {
                try modelContext.save()
            } catch {
                modelContext.delete(record)
                StorageService.deleteFile(at: url)
                throw error
            }
            generatedURL = url
        } catch {
            alert = AppAlert(title: "无法生成 PDF", error: error)
        }
    }
}

private struct SelectableCard: View {
    let card: MistakeCard
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                if let image = UIImage(contentsOfFile: card.imageURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .background(.white)
                } else {
                    ContentUnavailableView("图片不可用", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                }
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .padding(8)
            }
            Text(card.subject.isEmpty ? "未设置学科" : card.subject)
                .font(.headline)
            Text(card.status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? Color.accentColor : Color(uiColor: .separator),
                    lineWidth: isSelected ? 2 : 1
                )
        }
    }
}
