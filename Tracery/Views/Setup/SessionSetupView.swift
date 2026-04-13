import SwiftUI

struct SessionSetupView: View {
    let mode: GameMode
    @Bindable var sessionVM: SessionViewModel
    @Environment(DictionaryService.self) private var dictionary
    @State private var navigateToGame = false
    @State private var navigateToLobby = false

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
                if mode != .solo {
                    Button("Add Player") { sessionVM.addPlayer() }
                }
            }

            Section("Win Condition") {
                Stepper("First to \(sessionVM.winTarget) points", value: $sessionVM.winTarget, in: 10...200, step: 5)
            }

            if mode == .multiplayer {
                Section("Role") {
                    NavigationLink("Host a Game") {
                        LobbyView(isHost: true, playerName: firstName, winTarget: sessionVM.winTarget)
                            .environment(dictionary)
                    }
                    NavigationLink("Join a Game") {
                        LobbyView(isHost: false, playerName: firstName, winTarget: sessionVM.winTarget)
                            .environment(dictionary)
                    }
                }
            }
        }
        .navigationTitle(modeTitle)
        .navigationBarTitleDisplayMode(.inline)
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
            if let gameVM = sessionVM.gameVM, let activeSession = sessionVM.activeSession {
                GameBoardView(gameVM: gameVM, sessionVM: sessionVM)
            }
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
