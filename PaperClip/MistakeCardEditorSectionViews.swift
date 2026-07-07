import SwiftUI

struct MistakeCardMetadataSection<Thumbnail: View>: View {
    let sourceDocumentTitle: String
    let thumbnail: Thumbnail
    let subjects: [Subject]
    @Binding var grade: String
    @Binding var subject: String
    @Binding var semester: String

    init(
        sourceDocumentTitle: String,
        subjects: [Subject],
        grade: Binding<String>,
        subject: Binding<String>,
        semester: Binding<String>,
        @ViewBuilder thumbnail: () -> Thumbnail
    ) {
        self.sourceDocumentTitle = sourceDocumentTitle
        self.subjects = subjects
        self._grade = grade
        self._subject = subject
        self._semester = semester
        self.thumbnail = thumbnail()
    }

    var body: some View {
        Section {
            HStack(alignment: .top, spacing: 14) {
                thumbnail

                VStack(alignment: .leading, spacing: 2) {
                    if !sourceDocumentTitle.isEmpty {
                        Text(sourceDocumentTitle)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .padding(.bottom, 4)
                    }

                    HStack(spacing: 4) {
                        Picker("年级", selection: $grade) {
                            ForEach(Grade.allCases) { Text($0.rawValue).tag($0.rawValue) }
                        }
                        .pickerStyle(.menu)

                        Picker("学科", selection: $subject) {
                            ForEach(subjects) {
                                Text($0.rawValue).tag($0.rawValue)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("学期", selection: $semester) {
                            ForEach(Semester.allCases) { Text($0.rawValue).tag($0.rawValue) }
                        }
                        .pickerStyle(.menu)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct RelatedMistakeRow: View {
    let item: RelatedMistakeSnapshot

    var body: some View {
        NavigationLink {
            MistakeCardEditorLoader(cardID: item.card.id)
        } label: {
            HStack(spacing: 12) {
                CardImage(url: item.card.imageURL, maxPixelSize: 200)
                    .frame(width: 60, height: 45)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.card.subject).font(.subheadline)
                    Text(item.sharedTagPreviewText)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                    Text(item.card.createdAt, format: .dateTime.year().month().day())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
                StatusBadge(status: item.card.status)
            }
            .padding(.vertical, 2)
        }
        .accessibilityLabel(
            "\(item.card.subject)，共同知识点：\(item.sharedTagsAccessibilityText)"
        )
    }
}
