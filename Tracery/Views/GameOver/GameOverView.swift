import SwiftUI

struct GameOverView: View {
    let session: GameSession
    var sessionVM: SessionViewModel
    @Environment(\.dismiss) private var dismiss

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

            Button("New Session") {
                sessionVM.endSession()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .font(.title3.bold())
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Game Over")
        .navigationBarTitleDisplayMode(.inline)
    }
}
