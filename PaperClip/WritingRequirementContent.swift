import SwiftUI

struct WritingRequirementContent: View {
    let prompt: WritingPrompt

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(prompt.generatedRequirement)
                .fixedSize(horizontal: false, vertical: true)
            if !prompt.constraints.isEmpty {
                Divider()
                Label("要求", systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                ForEach(prompt.constraints, id: \.self) { item in
                    Text("• \(item)")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
            }
            if !prompt.rubric.isEmpty {
                Divider()
                Label("批阅关注", systemImage: "scope")
                    .font(.subheadline.weight(.semibold))
                ForEach(prompt.rubric, id: \.self) { item in
                    Text("• \(item)")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
