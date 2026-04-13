import SwiftUI

struct RoundResultsView: View {
    let gameVM: GameViewModel
    var sessionVM: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(gameVM.session.players) { player in
                Section(header: playerHeader(player)) {
                    let results = gameVM.roundResults[player.id] ?? []
                    if results.isEmpty {
                        Text("No words found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(results) { result in
                            WordResultRow(result: result)
                        }
                    }
                }
            }
        }
        .navigationTitle("Round \(gameVM.session.currentRound) Results")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Next Round") {
                    dismiss()
                    sessionVM.nextRound()
                }
            }
        }
    }

    private func playerHeader(_ player: Player) -> some View {
        HStack {
            Text(player.name)
                .font(.headline)
            Spacer()
            let round = gameVM.roundScores[player.id] ?? 0
            Text("+\(round) pts")
                .foregroundStyle(.blue)
            Text("Total: \(player.cumulativeScore)")
                .foregroundStyle(.secondary)
        }
    }
}

struct WordResultRow: View {
    let result: WordResult

    var body: some View {
        HStack {
            Text(result.word)
                .strikethrough(result.isDuplicate || !result.isValid)
                .foregroundStyle(result.isValid ? .primary : .secondary)
            Spacer()
            if result.isDuplicate {
                Label("Duplicate", systemImage: "equal.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if !result.isInDictionary {
                Label("Not a word", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if !result.isTraceable {
                Label("Not traceable", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("+\(result.points)")
                    .foregroundStyle(.green)
                    .bold()
            }
        }
    }
}
