import Foundation
import UIKit

@Observable
class SessionViewModel {
    // Setup state
    var playerNames: [String] = [SessionViewModel.inferPlayerName()]
    var winTarget: Int = 50
    var roundDurationSeconds: Int = 180
    var selectedMode: GameMode = .solo
    var localPlayerName: String = ""

    // Active session (nil until game starts)
    private(set) var activeSession: GameSession?
    private(set) var gameVM: GameViewModel?
    private(set) var isSessionActive: Bool = false

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
        let session = GameSession(players: [player], winTarget: winTarget, mode: .solo, roundDuration: roundDurationSeconds)
        activeSession = session
        isSessionActive = true
        gameVM = GameViewModel(session: session, dictionary: dictionary)
        gameVM?.startRound()
    }

    func nextRound() {
        gameVM?.startRound()
    }

    func markSessionActive(gameVM: GameViewModel? = nil) {
        self.gameVM = gameVM
        isSessionActive = true
    }

    private static func inferPlayerName() -> String {
        let deviceName = UIDevice.current.name
        // "Matt's iPhone" or "Matt\u{2019}s iPhone" → "Matt"
        for apostrophe in ["'s ", "\u{2019}s "] {
            if let range = deviceName.range(of: apostrophe) {
                return String(deviceName[..<range.lowerBound])
            }
        }
        return deviceName
    }

    func endSession() {
        gameVM?.networking?.disconnect()
        activeSession = nil
        gameVM = nil
        isSessionActive = false
    }
}
