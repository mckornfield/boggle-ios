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
    let localPlayerID: UUID              // which player in session is "us"

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

    // Set when the remote side disconnects mid-game so views can show an alert
    private(set) var disconnectedFromGame: Bool = false

    init(session: GameSession, dictionary: DictionaryService, networking: NetworkingService? = nil, localPlayerID: UUID? = nil) {
        self.session = session
        self.dictionary = dictionary
        self.networking = networking
        self.localPlayerID = localPlayerID ?? session.players.first?.id ?? UUID()
        self.expectedPlayers = session.players.count

        timer.onExpiry = { [weak self] in self?.handleTimerExpiry() }
        setupNetworkingCallbacks()
    }

    // MARK: - Round lifecycle

    func newGame() {
        guard let net = networking, net.role == .host else { return }
        session.resetForNewGame()
        net.sendToAll(NewGameMessage(), type: .newGame)
        startRound()
    }

    func startRound() {
        let letters = GridGenerator.generate()
        grid = Grid(letters: letters)
        submittedWords = []
        receivedWordLists = [:]
        tracedPath = []
        tracedWord = ""
        phase = .playing
        timer.start(duration: TimeInterval(session.roundDuration))

        if let net = networking, session.mode == .multiplayer {
            if net.role == .host {
                // Broadcast grid and timer start to all peers
                net.sendToAll(GridMessage(letters: letters), type: .gridMessage)
                net.sendToAll(
                    TimerStartMessage(startDate: Date(), durationSeconds: session.roundDuration),
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
            if networking?.role == .host {
                finalizeMultiplayerRoundIfReady()
                scheduleRoundFinalizeTimeout()
            }
        }
    }

    private func scheduleRoundFinalizeTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self, self.phase == .playing else { return }
            // Force-finalize with whatever word lists arrived; treat missing peers as empty
            self.expectedPlayers = self.receivedWordLists.count
            self.finalizeMultiplayerRoundIfReady()
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
        guard let net = networking else { return }
        let words = submittedWords.map(\.word)
        if net.role == .host {
            receivedWordLists[localPlayerID] = words
            finalizeMultiplayerRoundIfReady()
        } else {
            net.sendToHost(WordListMessage(playerID: localPlayerID, words: words), type: .wordList)
        }
    }

    private func finalizeMultiplayerRoundIfReady() {
        guard phase == .playing else { return }
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
                words: receivedWordLists[player.id] ?? [],
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

        net.onPeerDisconnected = { [weak self] _ in
            guard let self else { return }
            if self.phase == .playing, net.role == .host {
                // Peer dropped mid-round — don't wait for their word list
                self.expectedPlayers = max(1, self.expectedPlayers - 1)
                self.finalizeMultiplayerRoundIfReady()
            }
            self.timer.stop()
            self.disconnectedFromGame = true
        }

        net.onGridReceived = { [weak self] letters in
            guard let self else { return }
            self.grid = Grid(letters: letters)
            self.submittedWords = []
            self.tracedPath = []
            self.tracedWord = ""
            self.phase = .playing
        }

        net.onTimerStart = { [weak self] startDate, duration in
            let elapsed = Date().timeIntervalSince(startDate)
            let remaining = max(0, Double(duration) - elapsed)
            self?.timer.start(duration: remaining)
        }

        net.onWordListReceived = { [weak self] playerID, words in
            guard let self, net.role == .host else { return }
            self.receivedWordLists[playerID] = words
            self.finalizeMultiplayerRoundIfReady()
        }

        net.onNewGame = { [weak self] in
            guard let self, net.role == .peer else { return }
            self.session.resetForNewGame()
            // Grid and timer will arrive from host via onGridReceived / onTimerStart
        }

        net.onRoundResultsReceived = { [weak self] results in
            guard let self, net.role == .peer, self.phase == .playing else { return }

            // Reconstruct full round results so RoundResultsView shows complete word lists
            var reconstructedResults: [UUID: [WordResult]] = [:]
            var reconstructedScores: [UUID: Int] = [:]
            for result in results {
                let validSet = Set(result.validWords)
                let dupeSet = Set(result.duplicateWords)
                let wordResults = result.words.map { word -> WordResult in
                    let passedChecks = validSet.contains(word) || dupeSet.contains(word)
                    return WordResult(
                        word: word,
                        isInDictionary: passedChecks,
                        isTraceable: passedChecks,
                        isDuplicate: dupeSet.contains(word)
                    )
                }
                reconstructedResults[result.playerID] = wordResults
                reconstructedScores[result.playerID] = result.roundScore

                if let idx = self.session.players.firstIndex(where: { $0.id == result.playerID }) {
                    self.session.players[idx].cumulativeScore += result.roundScore
                }
            }
            self.roundResults = reconstructedResults
            self.roundScores = reconstructedScores
            self.session.currentRound += 1
            self.phase = self.session.winner != nil ? .sessionOver : .roundOver
        }
    }
}
