import SwiftUI

struct SessionSetupView: View {
    let mode: GameMode
    @Bindable var sessionVM: SessionViewModel
    @Environment(DictionaryService.self) private var dictionary
    @State private var navigateToGame = false
    @State private var navigateToLobby = false
    @State private var navigateToTable = false

    var body: some View {
        Form {
            Section("Players") {
                ForEach(sessionVM.playerNames.indices, id: \.self) { idx in
                    HStack {
                        TextField("Player \(idx + 1) name", text: $sessionVM.playerNames[idx])
                            .autocorrectionDisabled()
                        if mode == .solo && sessionVM.playerNames.count > 1 {
                            Button(role: .destructive) {
                                sessionVM.removePlayer(at: idx)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                        }
                    }
                }
                if mode == .tableMode {
                    Button("Add Player") { sessionVM.addPlayer() }
                }
            }

            if mode != .tableMode {
                Section("Win Condition") {
                    Stepper("First to \(sessionVM.winTarget) points", value: $sessionVM.winTarget, in: 10...200, step: 5)
                }
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
        .navigationTitle(modeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .muteButton()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                switch mode {
                case .solo:
                    Button("Start") {
                        sessionVM.startSoloSession(dictionary: dictionary)
                        navigateToGame = true
                    }
                    .disabled(sessionVM.playerNames[0].trimmingCharacters(in: .whitespaces).isEmpty)
                case .tableMode:
                    Button("Start") { navigateToTable = true }
                        .disabled(sessionVM.playerNames[0].trimmingCharacters(in: .whitespaces).isEmpty)
                case .multiplayer:
                    EmptyView()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            if let gameVM = sessionVM.gameVM {
                GameBoardView(gameVM: gameVM, sessionVM: sessionVM)
            }
        }
        .navigationDestination(isPresented: $navigateToTable) {
            TableModeView(playerNames: sessionVM.playerNames.map {
                $0.trimmingCharacters(in: .whitespaces).isEmpty ? "Player" : $0
            })
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

    private var modeTitle: String {
        switch mode {
        case .solo: return "Solo Game"
        case .multiplayer: return "Multiplayer"
        case .tableMode: return "Table Mode"
        }
    }
}
