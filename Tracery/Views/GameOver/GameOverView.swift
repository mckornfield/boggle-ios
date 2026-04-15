import SwiftUI

struct GameOverView: View {
    let session: GameSession
    var sessionVM: SessionViewModel
    var gameVM: GameViewModel?
    @Environment(\.dismiss) private var dismiss
    @Environment(MusicService.self) private var music

    private var isMultiplayer: Bool { gameVM?.networking != nil }
    private var isHost: Bool { gameVM?.networking?.role == .host }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if let winner = session.winner {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.yellow)

                Text("\(winner.name) wins!")
                    .font(.largeTitle.bold())

                Text("\(winner.cumulativeScore) points")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Final Scores")
                    .font(.headline)
                    .padding(.bottom, 4)
                ForEach(session.players.sorted { $0.cumulativeScore > $1.cumulativeScore }) { player in
                    HStack {
                        Text(player.name)
                        Spacer()
                        Text("\(player.cumulativeScore) pts").bold()
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()

            if isMultiplayer && !isHost {
                Text("Waiting for host to start next game...")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if isHost {
                Button("Next Game") {
                    gameVM?.newGame()
                }
                .buttonStyle(.borderedProminent)
                .font(.title3.bold())
            }

            Button(isMultiplayer ? "End Session" : "New Session") {
                gameVM?.networking?.disconnect()
                music.play(.home)
                sessionVM.endSession()
            }
            .buttonStyle(.bordered)
            .font(.title3)
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Game Over")
        .navigationBarTitleDisplayMode(.inline)
        .muteButton()
        .onAppear { music.play(.home) }
        .onChange(of: gameVM?.phase) { _, phase in
            if phase == .playing { dismiss() }
        }
    }
}
