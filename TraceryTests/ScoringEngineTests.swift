import XCTest
@testable import Tracery

final class ScoringEngineTests: XCTestCase {

    func testThreeLetterWord() {
        XCTAssertEqual(ScoringEngine.points(for: "CAT"), 1)
    }

    func testFourLetterWord() {
        XCTAssertEqual(ScoringEngine.points(for: "CATS"), 1)
    }

    func testFiveLetterWord() {
        XCTAssertEqual(ScoringEngine.points(for: "CRANE"), 2)
    }

    func testSixLetterWord() {
        XCTAssertEqual(ScoringEngine.points(for: "CRANES"), 3)
    }

    func testSevenLetterWord() {
        XCTAssertEqual(ScoringEngine.points(for: "STRANGE"), 5)
    }

    func testEightLetterWord() {
        XCTAssertEqual(ScoringEngine.points(for: "STRANGER"), 11)
    }

    func testNineLetterWord() {
        XCTAssertEqual(ScoringEngine.points(for: "STRANGERS"), 11)
    }

    func testTwoLetterWordIsZero() {
        XCTAssertEqual(ScoringEngine.points(for: "AT"), 0)
    }

    func testRoundScoresSum() {
        let playerID = UUID()
        let grid = Grid(letters: [
            ["C", "A", "T", "S"],
            ["E", "R", "N", "G"],
            ["I", "O", "P", "L"],
            ["M", "U", "B", "D"]
        ])
        let results: [UUID: [WordResult]] = [
            playerID: [
                WordResult(word: "CAT", isInDictionary: true, isTraceable: true, isDuplicate: false),
                WordResult(word: "CATS", isInDictionary: true, isTraceable: true, isDuplicate: false),
                WordResult(word: "XYZ", isInDictionary: false, isTraceable: false, isDuplicate: false),
            ]
        ]
        let scores = ScoringEngine.roundScores(from: results)
        // CAT=1, CATS=1, XYZ=0 → total 2
        XCTAssertEqual(scores[playerID], 2)
    }
}
