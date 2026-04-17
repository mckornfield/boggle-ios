import SwiftUI

struct SessionSetupView: View {
    let mode: GameMode
    @Bindable var sessionVM: SessionViewModel
    @Environment(DictionaryService.self) private var dictionary
    @State private var navigateToGame = false

    var body: some View {
        Form {
            Section("Players") {
                ForEach(sessionVM.playerNames.indices, id: \.self) { idx in
                    HStack {
                        TextField("Player \(idx + 1) name", text: $sessionVM.playerNames[idx])
                            .autocorrectionDisabled()
                    }
                }
            }

            Section("Win Condition") {
                Stepper("First to \(sessionVM.winTarget) points", value: $sessionVM.winTarget, in: 10...200, step: 5)
            }

            Section("Round Duration") {
                Stepper(
                    formattedDuration(sessionVM.roundDurationSeconds),
                    value: $sessionVM.roundDurationSeconds,
                    in: 30...600,
                    step: 30
                )
            }

            if mode == .multiplayer {
                Section("Role") {
                    NavigationLink("Host a Game") {
                        LobbyView(isHost: true, playerName: firstName, winTarget: sessionVM.winTarget, roundDuration: sessionVM.roundDurationSeconds, sessionVM: sessionVM)
                            .environment(dictionary)
                    }
                    NavigationLink("Join a Game") {
                        LobbyView(isHost: false, playerName: firstName, winTarget: sessionVM.winTarget, roundDuration: sessionVM.roundDurationSeconds, sessionVM: sessionVM)
                            .environment(dictionary)
                    }
                }
            }
        }
        .navigationTitle(mode == .solo ? "Solo Game" : "Multiplayer")
        .navigationBarTitleDisplayMode(.inline)
        .muteButton()
        .toolbar {
            if mode == .solo {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        sessionVM.startSoloSession(dictionary: dictionary)
                        navigateToGame = true
                    }
                    .disabled(sessionVM.playerNames[0].trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            if let gameVM = sessionVM.gameVM {
                GameBoardView(gameVM: gameVM, sessionVM: sessionVM)
            }
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if s == 0 {
            return "\(m) min"
        } else {
            return "\(m):\(String(format: "%02d", s)) min"
        }
    }

    private var firstName: String {
        sessionVM.playerNames[0].trimmingCharacters(in: .whitespaces).isEmpty
            ? "Player"
            : sessionVM.playerNames[0].trimmingCharacters(in: .whitespaces)
    }
}
