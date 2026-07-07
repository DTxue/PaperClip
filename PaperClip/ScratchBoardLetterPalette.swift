import SwiftUI

struct ScratchLetterPalette: View {
    @Binding var selectedLetter: String

    private let geometryLetters: [String] = [
        "A","B","C","D","E","F","G","H","I","M","N","O","P","Q","R","S","T","X","Y","Z",
        "α","β","γ","θ","φ","ω","°","′","∠","⊥","∥"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Label("点击已有字母，替换为", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                ForEach(geometryLetters, id: \.self) { letter in
                    Button {
                        selectedLetter = letter
                    } label: {
                        Text(letter)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .frame(width: 32, height: 32)
                            .background(
                                selectedLetter == letter ? Color.blue.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        selectedLetter == letter ? Color.blue : Color.secondary.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .foregroundStyle(selectedLetter == letter ? .blue : .primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(height: 48)
    }
}
