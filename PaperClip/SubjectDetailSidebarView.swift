import SwiftUI

struct SubjectDetailSidebarView: View {
    @Binding var topSection: SubjectTopSection
    @Binding var mistakeSection: SubjectMistakeSection?
    @Binding var selectedGrade: String
    @Binding var selectedSemester: String

    var body: some View {
        List {
            Section {
                Picker("内容", selection: $topSection) {
                    Text("试卷").tag(SubjectTopSection.papers)
                    Text("错题").tag(SubjectTopSection.mistakes)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            switch topSection {
            case .papers:
                paperFilters
            case .mistakes:
                mistakeSectionFilters
            }
        }
    }

    @ViewBuilder
    private var paperFilters: some View {
        Section("年级") {
            sidebarRow(label: "全部年级", isActive: selectedGrade.isEmpty) {
                selectedGrade = ""
            }
            ForEach(Grade.allCases) { grade in
                sidebarRow(label: grade.rawValue, isActive: selectedGrade == grade.rawValue) {
                    selectedGrade = selectedGrade == grade.rawValue ? "" : grade.rawValue
                }
            }
        }

        Section("学期") {
            sidebarRow(label: "全部学期", isActive: selectedSemester.isEmpty) {
                selectedSemester = ""
            }
            ForEach(Semester.allCases) { semester in
                sidebarRow(label: semester.rawValue, isActive: selectedSemester == semester.rawValue) {
                    selectedSemester = selectedSemester == semester.rawValue ? "" : semester.rawValue
                }
            }
        }

        if !selectedGrade.isEmpty || !selectedSemester.isEmpty {
            Section {
                Button(role: .destructive) {
                    selectedGrade = ""
                    selectedSemester = ""
                } label: {
                    Label("清除筛选", systemImage: "xmark.circle")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var mistakeSectionFilters: some View {
        Section {
            ForEach(SubjectMistakeSection.allCases) { section in
                sidebarRow(
                    label: section.rawValue,
                    icon: section.systemImage,
                    isActive: mistakeSection == section
                ) {
                    mistakeSection = section
                }
            }
        }
    }

    private func sidebarRow(
        label: String,
        icon: String? = nil,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        SidebarFilterRow(label: label, systemImage: icon, isActive: isActive, action: action)
    }
}
