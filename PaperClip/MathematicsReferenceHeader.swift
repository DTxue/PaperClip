import SwiftUI

struct MathematicsReferenceHeader: View {
    @Binding var grade: Grade
    @Binding var semester: Semester
    let catalog: MathematicsReferenceCatalog?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    gradePicker
                    semesterPicker
                }
                VStack(alignment: .leading, spacing: 12) {
                    gradePicker
                    semesterPicker
                }
            }

            Label(catalogTitle, systemImage: "book.closed")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var catalogTitle: String {
        catalog.map {
            "\($0.publisher) · \($0.edition) · 内容版本 \($0.contentVersion)"
        } ?? "苏科版数学教材"
    }

    private var gradePicker: some View {
        Picker("年级", selection: $grade) {
            ForEach(Grade.allCases) { grade in
                Text(grade.rawValue).tag(grade)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 420)
    }

    private var semesterPicker: some View {
        Picker("学期", selection: $semester) {
            ForEach(Semester.allCases) { semester in
                Text(semester.rawValue).tag(semester)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 300)
    }
}
