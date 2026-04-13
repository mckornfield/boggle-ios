import Foundation
import MultipeerConnectivity

@Observable
class LobbyViewModel {
    let networking: NetworkingService
    let dictionary: DictionaryService

    var playerName: String
    var winTarget: Int
    var isHost: Bool

    // Lobby state
    private(set) var joinedPlayers: [Player] = []       // host sees this
    private(set) var isGameStarted = false
    private(set) var activeSession: GameSession?
    private(set) var gameVM: GameViewModel?
    var disconnectAlert: String?

    init(playerName: String, winTarget: Int, isHost: Bool, dictionary: DictionaryService) {
        self.playerName = playerName
        self.winTarget = winTarget
        self.isHost = isHost
        self.dictionary = dictionary
        self.networking = NetworkingService(playerName: playerName)
        let localPlayer = Player(name: playerName)
        joinedPlayers = [localPlayer]
        setupCallbacks()
    }

    // MARK: - Host actions

    func startHosting() {
        networking.startHosting()
    }

    func startGame() {
        guard isHost else { return }
        let players = joinedPlayers
        let msg = StartGameMessage(
            players: players.map { PlayerJoinedMessage(playerID: $0.id, playerName: $0.name) },
            winTarget: winTarget
        )
        networking.sendToAll(msg, type: .startGame)
        launchGame(players: players)
    }

    // MARK: - Peer actions

    func startBrowsing() {
        networking.startBrowsing()
    }

    func joinHost(_ peerID: MCPeerID) {
        networking.connect(to: peerID)
        // Announce ourselves to host once connected
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            let localPlayer = self.joinedPlayers[0]
            self.networking.sendToHost(
                PlayerJoinedMessage(playerID: localPlayer.id, playerName: self.playerName),
                type: .playerJoined
            )
        }
    }

    // MARK: - Internal

    private func setupCallbacks() {
        networking.onPlayerJoined = { [weak self] playerID, name in
            guard let self, self.isHost else { return }
            if !self.joinedPlayers.contains(where: { $0.id == playerID }) {
                self.joinedPlayers.append(Player(id: playerID, name: name))
            }
        }

        networking.onStartGame = { [weak self] playerMessages, winTarget in
            guard let self, !self.isHost else { return }
            let players = playerMessages.map { Player(id: $0.playerID, name: $0.playerName) }
            self.winTarget = winTarget
            self.launchGame(players: players)
        }

        networking.onPeerDisconnected = { [weak self] name in
            self?.disconnectAlert = "\(name) disconnected."
        }
    }

    private func launchGame(players: [Player]) {
        let session = GameSession(players: players, winTarget: winTarget, mode: .multiplayer)
        activeSession = session
        gameVM = GameViewModel(session: session, dictionary: dictionary, networking: networking)
        isGameStarted = true
        gameVM?.startRound()
    }
}
