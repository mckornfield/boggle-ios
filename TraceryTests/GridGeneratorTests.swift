import XCTest
@testable import Tracery

final class GridGeneratorTests: XCTestCase {

    func testGeneratedGridIs4x4() {
        let letters = GridGenerator.generate()
        XCTAssertEqual(letters.count, 4)
        for row in letters { XCTAssertEqual(row.count, 4) }
    }

    func testAllTilesHaveLetters() {
        let letters = GridGenerator.generate()
        for row in letters {
            for letter in row {
                XCTAssertFalse(letter.isEmpty)
            }
        }
    }

    func testEachDieUsedExactlyOnce() {
        // Generate multiple grids; each should have exactly 16 tiles
        for _ in 0..<10 {
            let letters = GridGenerator.generate()
            let flat = letters.flatMap { $0 }
            XCTAssertEqual(flat.count, 16)
        }
    }

    func testDiceContainAllFaces() {
        XCTAssertEqual(GridGenerator.dice.count, 16)
        for die in GridGenerator.dice {
            XCTAssertEqual(die.count, 6, "Each die should have 6 faces")
        }
    }

    func testQuDieExists() {
        let hasQu = GridGenerator.dice.contains { $0.contains("QU") }
        XCTAssertTrue(hasQu, "One die should have a QU face")
    }
}
