import Foundation

@Observable
class SessionViewModel {
    // Setup state
    var playerNames: [String] = [""]
    var winTarget: Int = 50
    var selectedMode: GameMode = .solo
    var localPlayerName: String = ""

    // Active session (nil until game starts)
    private(set) var activeSession: GameSession?
    private(set) var gameVM: GameViewModel?

    func addPlayer() {
        guard playerNames.count < 8 else { return }
        playerNames.append("")
    }

    func removePlayer(at index: Int) {
        guard playerNames.count > 1 else { return }
        playerNames.remove(at: index)
    }

    func startSoloSession(dictionary: DictionaryService) {
        let name = playerNames[0].trimmingCharacters(in: .whitespaces)
        let player = Player(name: name.isEmpty ? "Player" : name)
        let session = GameSession(players: [player], winTarget: winTarget, mode: .solo)
        activeSession = session
        gameVM = GameViewModel(session: session, dictionary: dictionary)
        gameVM?.startRound()
    }

    func startTableModeSession() {
        let session = GameSession(players: [], winTarget: winTarget, mode: .tableMode)
        activeSession = session
        gameVM = GameViewModel(session: session, dictionary: DictionaryService())
        gameVM?.startRound()
    }

    func nextRound() {
        gameVM?.startRound()
    }

    func endSession() {
        activeSession = nil
        gameVM = nil
    }
}
