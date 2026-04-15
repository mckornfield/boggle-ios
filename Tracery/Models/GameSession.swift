import Foundation

enum GameMode {
    case solo
    case multiplayer
    case tableMode
}

struct RoundRecord {
    let round: Int
    let playerResults: [UUID: [WordResult]]  // playerID → their results
    let roundScores: [UUID: Int]
}

@Observable
class GameSession {
    var players: [Player]
    var winTarget: Int
    var mode: GameMode
    var roundDuration: Int
    var currentRound: Int = 0
    var roundHistory: [RoundRecord] = []

    init(players: [Player], winTarget: Int, mode: GameMode, roundDuration: Int = 180) {
        self.players = players
        self.winTarget = winTarget
        self.mode = mode
        self.roundDuration = roundDuration
    }

    var winner: Player? {
        players.first { $0.cumulativeScore >= winTarget }
    }

    func applyRoundResults(_ record: RoundRecord) {
        roundHistory.append(record)
        for idx in players.indices {
            let pid = players[idx].id
            players[idx].cumulativeScore += record.roundScores[pid, default: 0]
        }
        currentRound += 1
    }

    func resetForNewGame() {
        for idx in players.indices {
            players[idx].cumulativeScore = 0
        }
        currentRound = 0
        roundHistory = []
    }
}
