import SwiftUI

struct MathematicsReferenceView: View {
    let kind: MathematicsReferenceKind

    @State private var grade = Grade.grade7
    @State private var semester = Semester.first

    private var chapters: [MathematicsReferenceChapter] {
        MathematicsReference.chapters(
            grade: grade.rawValue,
            semester: semester.rawValue,
            kind: kind
        )
    }

    private var catalog: MathematicsReferenceCatalog? {
        MathematicsReference.catalog
    }

    private var title: String {
        kind == .knowledgePoints ? "知识点" : "公式"
    }

    var body: some View {
        Group {
            if let error = MathematicsReference.loadingError {
                ContentUnavailableView {
                    Label("无法读取教材内容", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        MathematicsReferenceHeader(
                            grade: $grade,
                            semester: $semester,
                            catalog: catalog
                        )

                        if chapters.isEmpty {
                            ContentUnavailableView(
                                "暂无\(title)",
                                systemImage: kind == .formulas
                                    ? "function"
                                    : "point.3.connected.trianglepath.dotted",
                                description: Text("当前年级和学期尚未配置内容。")
                            )
                            .frame(maxWidth: .infinity, minHeight: 320)
                        } else {
                            ForEach(chapters) { chapter in
                                MathematicsReferenceChapterCard(chapter: chapter, kind: kind)
                            }
                        }
                    }
                    .frame(maxWidth: 1_000, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

}
