import Foundation
import SwiftUI

enum GamePhase {
    case playing
    case roundOver
    case sessionOver
}

@Observable
class GameViewModel {
    // Injected dependencies
    let dictionary: DictionaryService
    let session: GameSession
    let networking: NetworkingService?   // nil in solo and table mode

    // Round state
    private(set) var grid: Grid = Grid(letters: GridGenerator.generate())
    private(set) var phase: GamePhase = .playing
    private(set) var timer = TimerService()

    // Swipe gesture state
    private(set) var tracedPath: [Tile] = []  // tiles being traced right now
    private(set) var tracedWord: String = ""

    // Words submitted this round, per player
    struct SubmittedWordEntry: Identifiable {
        let id = UUID()
        let word: String
        let isInDictionary: Bool  // checked immediately at commit time
    }
    private(set) var submittedWords: [SubmittedWordEntry] = []

    // Round results (set when round ends)
    private(set) var roundResults: [UUID: [WordResult]] = [:]
    private(set) var roundScores: [UUID: Int] = [:]

    // Multiplayer: word lists received from each peer
    private var receivedWordLists: [UUID: [String]] = [:]
    private var expectedPlayers: Int = 1

    init(session: GameSession, dictionary: DictionaryService, networking: NetworkingService? = nil) {
        self.session = session
        self.dictionary = dictionary
        self.networking = networking
        self.expectedPlayers = session.players.count

        timer.onExpiry = { [weak self] in self?.handleTimerExpiry() }
        setupNetworkingCallbacks()
    }

    // MARK: - Round lifecycle

    func startRound() {
        let letters = GridGenerator.generate()
        grid = Grid(letters: letters)
        submittedWords = []
        receivedWordLists = [:]
        tracedPath = []
        tracedWord = ""
        phase = .playing
        timer.start()

        if let net = networking, session.mode == .multiplayer {
            if net.role == .host {
                // Broadcast grid and timer start to all peers
                net.sendToAll(GridMessage(letters: letters), type: .gridMessage)
                net.sendToAll(
                    TimerStartMessage(startDate: Date(), durationSeconds: Int(TimerService.roundDuration)),
                    type: .timerStart
                )
            }
        }
    }

    func handleTimerExpiry() {
        switch session.mode {
        case .solo:
            finalizeSoloRound()
        case .multiplayer:
            sendWordListToPeers()
            // If we're the host, wait for peer word lists (or finalize after a short timeout)
            if networking?.role == .host {
                finalizeMultiplayerRoundIfReady()
            }
        case .tableMode:
            phase = .roundOver
        }
    }

    // MARK: - Swipe gesture

    /// Called repeatedly as the user's finger moves across the grid.
    func tileEntered(_ tile: Tile) {
        guard phase == .playing else { return }

        // Backtrack: if the tile is already in the path (but not the current last),
        // trim everything after it so the user can "unswipe" back along their trace.
        if let existingIndex = tracedPath.firstIndex(where: { $0.id == tile.id }) {
            if existingIndex == tracedPath.index(before: tracedPath.endIndex) { return }
            tracedPath = Array(tracedPath.prefix(through: existingIndex))
            tracedWord = tracedPath.map(\.letter).joined()
            return
        }

        // Forward: only extend if the new tile is adjacent to the current last tile.
        if let last = tracedPath.last, !last.isAdjacent(to: tile) { return }
        tracedPath.append(tile)
        tracedWord = tracedPath.map(\.letter).joined()
    }

    /// Called when the finger lifts — submit the current trace as a word.
    func commitTrace() {
        guard phase == .playing, !tracedPath.isEmpty else {
            clearTrace()
            return
        }
        let word = tracedWord.uppercased()
        let letterCount = tracedPath.reduce(0) { $0 + $1.letterCount }
        let alreadySubmitted = submittedWords.contains { $0.word == word }
        if letterCount >= 3 && !alreadySubmitted {
            let valid = dictionary.isValidWord(word)
            submittedWords.insert(SubmittedWordEntry(word: word, isInDictionary: valid), at: 0)
        }
        clearTrace()
    }

    func clearTrace() {
        tracedPath = []
        tracedWord = ""
    }

    // MARK: - Solo round finalization

    private func finalizeSoloRound() {
        let localPlayerID = session.players[0].id
        let playerWords = [localPlayerID: submittedWords.map(\.word)]
        let results = WordValidator.validateAll(playerWords: playerWords, grid: grid, dictionary: dictionary)
        let scores = ScoringEngine.roundScores(from: results)
        let record = RoundRecord(round: session.currentRound, playerResults: results, roundScores: scores)
        session.applyRoundResults(record)
        roundResults = results
        roundScores = scores
        phase = session.winner != nil ? .sessionOver : .roundOver
    }

    // MARK: - Multiplayer round finalization

    private func sendWordListToPeers() {
        guard let net = networking, let localPlayer = session.players.first else { return }
        let msg = WordListMessage(playerID: localPlayer.id, words: submittedWords.map(\.word))
        if net.role == .host {
            receivedWordLists[localPlayer.id] = submittedWords.map(\.word)
            finalizeMultiplayerRoundIfReady()
        } else {
            net.sendToHost(msg, type: .wordList)
        }
    }

    private func finalizeMultiplayerRoundIfReady() {
        guard receivedWordLists.count >= expectedPlayers else { return }
        let results = WordValidator.validateAll(playerWords: receivedWordLists, grid: grid, dictionary: dictionary)
        let scores = ScoringEngine.roundScores(from: results)
        let record = RoundRecord(round: session.currentRound, playerResults: results, roundScores: scores)
        session.applyRoundResults(record)
        roundResults = results
        roundScores = scores
        phase = session.winner != nil ? .sessionOver : .roundOver

        // Build and broadcast results to all peers
        let resultMessages = session.players.map { player in
            let playerResults = results[player.id] ?? []
            let valid = playerResults.filter(\.isValid).map(\.word)
            let dupes = playerResults.filter(\.isDuplicate).map(\.word)
            return PlayerResultMessage(
                playerID: player.id,
                playerName: player.name,
                words: submittedWords.map(\.word),
                validWords: valid,
                duplicateWords: dupes,
                roundScore: scores[player.id] ?? 0
            )
        }
        networking?.sendToAll(RoundResultsMessage(results: resultMessages), type: .roundResults)
    }

    // MARK: - Networking callbacks

    private func setupNetworkingCallbacks() {
        guard let net = networking else { return }

        net.onGridReceived = { [weak self] letters in
            guard let self else { return }
            self.grid = Grid(letters: letters)
            self.submittedWords = []
            self.tracedPath = []
            self.tracedWord = ""
            self.phase = .playing
        }

        net.onTimerStart = { [weak self] startDate, duration in
            // Sync timer to host's start time
            let elapsed = Date().timeIntervalSince(startDate)
            let remaining = max(0, Double(duration) - elapsed)
            self?.timer.start()
            // Rough sync: adjust remaining seconds
        }

        net.onWordListReceived = { [weak self] playerID, words in
            guard let self, net.role == .host else { return }
            self.receivedWordLists[playerID] = words
            self.finalizeMultiplayerRoundIfReady()
        }

        net.onRoundResultsReceived = { [weak self] results in
            guard let self, net.role == .peer else { return }
            // Apply scores received from host
            for result in results {
                if let idx = self.session.players.firstIndex(where: { $0.id == result.playerID }) {
                    self.session.players[idx].cumulativeScore += result.roundScore
                }
            }
            self.phase = self.session.winner != nil ? .sessionOver : .roundOver
        }
    }
}
