import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    let isHost: Bool
    let playerName: String
    let winTarget: Int
    @Environment(DictionaryService.self) private var dictionary
    @State private var lobbyVM: LobbyViewModel?
    @State private var navigateToGame = false

    var body: some View {
        Group {
            if let vm = lobbyVM {
                content(vm: vm)
            } else {
                ProgressView("Setting up...")
            }
        }
        .navigationTitle(isHost ? "Hosting" : "Join Game")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let vm = LobbyViewModel(playerName: playerName, winTarget: winTarget, isHost: isHost, dictionary: dictionary)
            lobbyVM = vm
            if isHost { vm.startHosting() } else { vm.startBrowsing() }
        }
        .onDisappear {
            lobbyVM?.networking.disconnect()
        }
    }

    @ViewBuilder
    private func content(vm: LobbyViewModel) -> some View {
        List {
            if isHost {
                Section("Connected Players (\(vm.joinedPlayers.count))") {
                    ForEach(vm.joinedPlayers) { player in
                        Label(player.name, systemImage: "person.circle.fill")
                    }
                }
                Section {
                    Button("Start Game") { vm.startGame() }
                        .disabled(vm.joinedPlayers.count < 1)
                        .font(.headline)
                }
            } else {
                Section("Available Games") {
                    if vm.networking.discoveredHosts.isEmpty {
                        Text("Looking for hosts...")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(vm.networking.discoveredHosts, id: \.self) { peer in
                        Button(peer.displayName) { vm.joinHost(peer) }
                    }
                }
                if vm.networking.isConnected {
                    Section {
                        Label("Connected — waiting for host to start", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .alert("Disconnected", isPresented: .constant(vm.disconnectAlert != nil), actions: {
            Button("OK") { lobbyVM?.disconnectAlert = nil }
        }, message: {
            Text(vm.disconnectAlert ?? "")
        })
        .navigationDestination(isPresented: $navigateToGame) {
            if let gameVM = vm.gameVM, let session = vm.activeSession {
                GameBoardView(gameVM: gameVM, sessionVM: SessionViewModel())
            }
        }
        .onChange(of: vm.isGameStarted) { _, started in
            if started { navigateToGame = true }
        }
    }
}
