import SwiftUI

struct ScoreboardView: View {
    let session: GameSession

    var body: some View {
        List {
            ForEach(session.players.sorted { $0.cumulativeScore > $1.cumulativeScore }) { player in
                HStack {
                    Text(player.name)
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(player.cumulativeScore) pts")
                            .font(.title3.bold())
                        Text("\(max(0, session.winTarget - player.cumulativeScore)) to win")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Scoreboard")
    }
}
