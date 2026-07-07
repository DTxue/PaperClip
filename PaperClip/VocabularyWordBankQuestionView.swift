import SwiftUI

struct VocabularyWordBankQuestionView: View {
    let definition: String
    let wordBankTiles: [VocabularyWordBankTile]
    let hasChecked: Bool
    @Binding var placedTileIDs: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(definition)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            placedTilesSection

            VocabularyTileFlowLayout(hSpacing: 8, vSpacing: 8) {
                ForEach(wordBankTiles) { tile in
                    let isPlaced = placedTileIDs.contains(tile.id)
                    Button {
                        placedTileIDs.append(tile.id)
                    } label: {
                        Text(tile.text)
                            .vocabularyTileStyle(placed: false)
                            .opacity(isPlaced ? 0.25 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPlaced || hasChecked)
                }
            }
        }
    }

    private var placedTilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VocabularyTileFlowLayout(hSpacing: 8, vSpacing: 8) {
                if placedTileIDs.isEmpty {
                    Text("点击下方词块组成答案")
                        .foregroundStyle(.tertiary)
                        .font(.subheadline)
                        .padding(.vertical, 6)
                } else {
                    ForEach(placedTileIDs, id: \.self) { tileID in
                        if let tile = wordBankTiles.first(where: { $0.id == tileID }) {
                            Button {
                                placedTileIDs.removeAll { $0 == tileID }
                            } label: {
                                Text(tile.text)
                                    .vocabularyTileStyle(placed: true)
                            }
                            .buttonStyle(.plain)
                            .disabled(hasChecked)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            Divider()
        }
    }
}
