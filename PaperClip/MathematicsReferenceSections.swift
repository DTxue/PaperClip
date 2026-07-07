import SwiftUI

struct MathematicsReferenceChapterCard: View {
    let chapter: MathematicsReferenceChapter
    let kind: MathematicsReferenceKind

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(chapter.title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))

            if kind == .formulas {
                FormulaChapterView(chapter: chapter)
            } else {
                ForEach(chapter.entries.indices, id: \.self) { index in
                    MathematicsReferenceEntryRow(entry: chapter.entries[index], kind: kind)
                    if index + 1 < chapter.entries.count {
                        Divider()
                            .padding(.leading, 18)
                    }
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
        }
    }
}

struct MathematicsReferenceEntryRow: View {
    let entry: MathematicsReferenceEntry
    let kind: MathematicsReferenceKind

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title)
                .font(kind == .formulas ? .body.monospaced().weight(.semibold) : .body.weight(.semibold))
            Text(entry.detail)
                .font(kind == .formulas ? .body.monospaced() : .subheadline)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title)，\(entry.detail)")
    }
}
