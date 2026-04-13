import SwiftUI

struct RoundResultsView: View {
    let gameVM: GameViewModel
    var sessionVM: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(MusicService.self) private var music
    @State private var showQuitConfirm = false

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
        .muteButton()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Next Round") {
                    dismiss()
                    sessionVM.nextRound()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(role: .destructive) {
                showQuitConfirm = true
            } label: {
                Text("Quit Game")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .padding()
            .background(.background)
            .confirmationDialog("Quit this game?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
                Button("Quit", role: .destructive) {
                    music.play(.home)
                    sessionVM.endSession()
                    dismiss()
                }
                Button("Keep Playing", role: .cancel) {}
            } message: {
                Text("Your progress in this session will be lost.")
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
