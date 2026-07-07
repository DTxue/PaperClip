import SwiftUI

struct LearningSettingsView: View {
    @AppStorage("defaultGrade") private var defaultGrade = Grade.grade7.rawValue
    @AppStorage("defaultSemester") private var defaultSemester = Semester.first.rawValue
    @AppStorage("preferredSubjects") private var preferredSubjectsRaw = ""

    private var selectedSubjects: Set<String> {
        PreferredSubjects.parseSet(preferredSubjectsRaw)
    }

    var body: some View {
        Form {
            Section {
                Picker("年级", selection: $defaultGrade) {
                    ForEach(Grade.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Picker("学期", selection: $defaultSemester) {
                    ForEach(Semester.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
            } header: {
                Text("新建错题卡默认值")
            } footer: {
                Text("框选错题时自动填入的年级和学期，可在编辑错题卡时修改。")
            }

            Section {
                ForEach(Subject.allCases) { subject in
                    Toggle(subject.rawValue, isOn: Binding(
                        get: { selectedSubjects.contains(subject.rawValue) },
                        set: { isOn in
                            var set = selectedSubjects
                            if isOn { set.insert(subject.rawValue) } else { set.remove(subject.rawValue) }
                            preferredSubjectsRaw = PreferredSubjects.serialize(set)
                        }
                    ))
                }
            } header: {
                Text("常用学科")
            } footer: {
                if selectedSubjects.isEmpty {
                    Text("未勾选任何学科，编辑器将显示全部学科。")
                } else {
                    Text("编辑器学科选择器只显示已勾选的 \(selectedSubjects.count) 个学科。有数据的学科始终在错题库中可见。")
                }
            }
        }
        .navigationTitle("学习设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}
