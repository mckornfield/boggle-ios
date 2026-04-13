import Foundation

struct Tile: Identifiable, Hashable, Equatable {
    let id: UUID
    let letter: String  // "A"–"Z", or "QU"
    let row: Int
    let col: Int

    init(letter: String, row: Int, col: Int) {
        self.id = UUID()
        self.letter = letter
        self.row = row
        self.col = col
    }

    /// The number of alphabet letters this tile represents (QU = 2, all others = 1)
    var letterCount: Int { letter == "QU" ? 2 : 1 }

    /// True if this tile is orthogonally or diagonally adjacent to the other tile
    func isAdjacent(to other: Tile) -> Bool {
        abs(row - other.row) <= 1 && abs(col - other.col) <= 1 && self != other
    }
}
