import Foundation

struct Grid {
    static let size = 4
    let tiles: [[Tile]]  // [row][col]

    init(letters: [[String]]) {
        precondition(letters.count == Grid.size && letters.allSatisfy { $0.count == Grid.size })
        tiles = letters.enumerated().map { row, rowLetters in
            rowLetters.enumerated().map { col, letter in
                Tile(letter: letter, row: row, col: col)
            }
        }
    }

    subscript(row: Int, col: Int) -> Tile { tiles[row][col] }

    var allTiles: [Tile] { tiles.flatMap { $0 } }
}
