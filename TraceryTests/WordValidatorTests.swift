import XCTest
@testable import Tracery

final class WordValidatorTests: XCTestCase {

    // A fixed 4x4 grid for testing:
    // A  B  C  D
    // E  F  G  H
    // I  J  K  L
    // M  N  O  P
    let testGrid = Grid(letters: [
        ["A", "B", "C", "D"],
        ["E", "F", "G", "H"],
        ["I", "J", "K", "L"],
        ["M", "N", "O", "P"]
    ])

    func testAdjacentWordIsTraceable() {
        // "AB" is adjacent — but only 2 letters; minimum is 3
        XCTAssertFalse(WordValidator.isTraceable("AB", on: testGrid))
    }

    func testThreeLetterAdjacentWord() {
        // A(0,0)→B(0,1)→C(0,2): each adjacent
        XCTAssertTrue(WordValidator.isTraceable("ABC", on: testGrid))
    }

    func testDiagonalTrace() {
        // A(0,0)→F(1,1)→K(2,2): diagonal adjacency
        XCTAssertTrue(WordValidator.isTraceable("AFK", on: testGrid))
    }

    func testWordRequiresReusedTile() {
        // "ABA" would need A twice — should be false
        XCTAssertFalse(WordValidator.isTraceable("ABA", on: testGrid))
    }

    func testNonAdjacentWordFails() {
        // A(0,0) and P(3,3) are not adjacent
        XCTAssertFalse(WordValidator.isTraceable("AP", on: testGrid))
    }

    func testLongerPath() {
        // A(0,0)→B(0,1)→F(1,1)→E(1,0)→I(2,0): each adjacent
        XCTAssertTrue(WordValidator.isTraceable("ABFEI", on: testGrid))
    }

    func testWordNotOnGrid() {
        XCTAssertFalse(WordValidator.isTraceable("XYZ", on: testGrid))
    }

    // Grid with QU tile
    let quGrid = Grid(letters: [
        ["QU", "E", "E", "N"],
        ["A",  "R", "I", "G"],
        ["L",  "S", "T", "H"],
        ["E",  "D", "O", "P"]
    ])

    func testQuTileMatchesTwoLetters() {
        // QU(0,0)→E(0,1)→E(0,2)→N(0,3) → "QUEEN"
        XCTAssertTrue(WordValidator.isTraceable("QUEEN", on: quGrid))
    }

    func testQuTileDoesNotMatchSingleQ() {
        XCTAssertFalse(WordValidator.isTraceable("Q", on: quGrid))
    }
}
