import XCTest
@testable import Tracery

// MARK: - Mock

/// Subclass that skips real MCSession/advertiser setup so tests run without a network.
/// stopHosting/stopBrowsing are no-ops so disconnect() doesn't crash on nil advertisers.
final class MockNetworkingService: NetworkingService {
    override func stopHosting() {}
    override func stopBrowsing() {}
}

// MARK: - Helpers

private func makeMultiplayerPair() -> (
    host: GameViewModel,
    peer: GameViewModel,
    hostNet: MockNetworkingService,
    peerNet: MockNetworkingService,
    hostPlayer: Player,
    peerPlayer: Player
) {
    let hostPlayer = Player(name: "Alice")
    let peerPlayer = Player(name: "Bob")
    let players = [hostPlayer, peerPlayer]

    let hostSession = GameSession(players: players, winTarget: 50, mode: .multiplayer)
    let peerSession = GameSession(players: players, winTarget: 50, mode: .multiplayer)

    let hostNet = MockNetworkingService(playerName: "Alice")
    hostNet.startHosting()   // sets role = .host

    let peerNet = MockNetworkingService(playerName: "Bob")
    // peerNet.role stays .peer (default)

    let dictionary = DictionaryService()

    let hostVM = GameViewModel(
        session: hostSession,
        dictionary: dictionary,
        networking: hostNet,
        localPlayerID: hostPlayer.id
    )
    let peerVM = GameViewModel(
        session: peerSession,
        dictionary: dictionary,
        networking: peerNet,
        localPlayerID: peerPlayer.id
    )

    return (hostVM, peerVM, hostNet, peerNet, hostPlayer, peerPlayer)
}

/// Build a RoundResultsMessage from the host VM's finalized state and deliver it to the peer.
private func deliverRoundResults(from hostVM: GameViewModel, to peerVM: GameViewModel) {
    guard hostVM.phase == .roundOver || hostVM.phase == .sessionOver else {
        XCTFail("Host round not yet finalized (phase=\(hostVM.phase))")
        return
    }
    let results = hostVM.session.players.map { player -> PlayerResultMessage in
        let wordResults = hostVM.roundResults[player.id] ?? []
        return PlayerResultMessage(
            playerID: player.id,
            playerName: player.name,
            words: wordResults.map(\.word),
            validWords: wordResults.filter(\.isValid).map(\.word),
            duplicateWords: wordResults.filter(\.isDuplicate).map(\.word),
            roundScore: hostVM.roundScores[player.id] ?? 0
        )
    }
    peerVM.networking?.onRoundResultsReceived?(results)
}

// MARK: - Tests

final class MultiplayerGameTests: XCTestCase {

    // MARK: Host finalization

    func testRoundFinalizesOnlyOnceWhenWordListsArrive() {
        let (hostVM, _, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        hostNet.onWordListReceived?(hostPlayer.id, ["CATS"])
        XCTAssertEqual(hostVM.phase, .playing, "Should not finalize with only one word list")

        hostNet.onWordListReceived?(peerPlayer.id, ["RATS"])
        XCTAssertEqual(hostVM.phase, .roundOver, "Should finalize once both word lists arrive")
    }

    func testFinalizeIsIdempotent() {
        let (hostVM, _, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        hostNet.onWordListReceived?(hostPlayer.id, [])
        hostNet.onWordListReceived?(peerPlayer.id, [])
        XCTAssertEqual(hostVM.session.currentRound, 1)

        // Delivering again must not re-finalize
        hostNet.onWordListReceived?(peerPlayer.id, [])
        XCTAssertEqual(hostVM.session.currentRound, 1, "Double delivery must not increment round again")
    }

    func testCurrentRoundIncrementsExactlyOncePerRound() {
        let (hostVM, _, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        XCTAssertEqual(hostVM.session.currentRound, 0)

        hostNet.onWordListReceived?(hostPlayer.id, [])
        hostNet.onWordListReceived?(peerPlayer.id, [])
        XCTAssertEqual(hostVM.session.currentRound, 1)

        hostVM.startRound()
        hostNet.onWordListReceived?(hostPlayer.id, [])
        hostNet.onWordListReceived?(peerPlayer.id, [])
        XCTAssertEqual(hostVM.session.currentRound, 2)
    }

    // MARK: Host round results

    func testRoundResultsContainBothPlayers() {
        let (hostVM, _, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        hostNet.onWordListReceived?(hostPlayer.id, [])
        hostNet.onWordListReceived?(peerPlayer.id, [])

        XCTAssertNotNil(hostVM.roundResults[hostPlayer.id], "Host results must include host player")
        XCTAssertNotNil(hostVM.roundResults[peerPlayer.id], "Host results must include peer player")
    }

    func testEachPlayersWordsAreStoredSeparately() {
        let (hostVM, _, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        hostNet.onWordListReceived?(hostPlayer.id, ["CATS", "RATS"])
        hostNet.onWordListReceived?(peerPlayer.id, ["DOGS"])

        let hostWords = hostVM.roundResults[hostPlayer.id]?.map(\.word) ?? []
        let peerWords = hostVM.roundResults[peerPlayer.id]?.map(\.word) ?? []

        XCTAssertEqual(Set(hostWords), ["CATS", "RATS"])
        XCTAssertEqual(Set(peerWords), ["DOGS"])
    }

    func testSharedWordIsMarkedDuplicate() {
        let (hostVM, _, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        hostNet.onWordListReceived?(hostPlayer.id, ["CATS"])
        hostNet.onWordListReceived?(peerPlayer.id, ["CATS", "RATS"])

        let hostResults = hostVM.roundResults[hostPlayer.id] ?? []
        let peerResults = hostVM.roundResults[peerPlayer.id] ?? []

        XCTAssertTrue(hostResults.first { $0.word == "CATS" }?.isDuplicate ?? false,
                      "CATS should be duplicate for host")
        XCTAssertTrue(peerResults.first { $0.word == "CATS" }?.isDuplicate ?? false,
                      "CATS should be duplicate for peer")
        XCTAssertFalse(peerResults.first { $0.word == "RATS" }?.isDuplicate ?? true,
                       "RATS should not be duplicate")
    }

    // MARK: Peer sync

    func testPeerPhaseBecomesRoundOverAfterResults() {
        let (hostVM, peerVM, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        hostNet.onWordListReceived?(hostPlayer.id, [])
        hostNet.onWordListReceived?(peerPlayer.id, [])
        deliverRoundResults(from: hostVM, to: peerVM)

        XCTAssertEqual(peerVM.phase, .roundOver)
    }

    func testPeerReceivesResultsForBothPlayers() {
        let (hostVM, peerVM, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        hostNet.onWordListReceived?(hostPlayer.id, [])
        hostNet.onWordListReceived?(peerPlayer.id, [])
        deliverRoundResults(from: hostVM, to: peerVM)

        XCTAssertNotNil(peerVM.roundResults[hostPlayer.id], "Peer should have results for host player")
        XCTAssertNotNil(peerVM.roundResults[peerPlayer.id], "Peer should have results for peer player")
    }

    func testPeerCurrentRoundIncrementsOnce() {
        let (hostVM, peerVM, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        XCTAssertEqual(peerVM.session.currentRound, 0)

        hostNet.onWordListReceived?(hostPlayer.id, [])
        hostNet.onWordListReceived?(peerPlayer.id, [])
        deliverRoundResults(from: hostVM, to: peerVM)
        XCTAssertEqual(peerVM.session.currentRound, 1)

        // Delivering the same results again must not double-increment
        deliverRoundResults(from: hostVM, to: peerVM)
        XCTAssertEqual(peerVM.session.currentRound, 1, "Duplicate delivery must not increment round again")
    }

    func testPeerScoresMatchHost() {
        let (hostVM, peerVM, hostNet, _, hostPlayer, peerPlayer) = makeMultiplayerPair()

        hostNet.onWordListReceived?(hostPlayer.id, [])
        hostNet.onWordListReceived?(peerPlayer.id, [])
        deliverRoundResults(from: hostVM, to: peerVM)

        XCTAssertEqual(peerVM.roundScores[hostPlayer.id], hostVM.roundScores[hostPlayer.id])
        XCTAssertEqual(peerVM.roundScores[peerPlayer.id], hostVM.roundScores[peerPlayer.id])
    }
}
