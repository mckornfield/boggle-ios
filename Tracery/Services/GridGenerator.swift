import Foundation

enum GridGenerator {
    // Classic 4x4 Boggle dice (16 dice, historically accurate face distributions)
    static let dice: [[String]] = [
        ["A", "A", "E", "E", "G", "N"],
        ["A", "B", "B", "J", "O", "O"],
        ["A", "C", "H", "H", "O", "P"],
        ["A", "F", "F", "K", "P", "S"],
        ["A", "O", "O", "T", "T", "W"],
        ["C", "I", "M", "O", "T", "U"],
        ["D", "E", "I", "L", "R", "X"],
        ["D", "E", "L", "R", "V", "Y"],
        ["D", "I", "S", "T", "T", "Y"],
        ["E", "E", "G", "H", "N", "W"],
        ["E", "E", "I", "N", "S", "U"],
        ["E", "H", "R", "T", "V", "W"],
        ["E", "I", "O", "S", "S", "T"],
        ["E", "L", "R", "T", "T", "Y"],
        ["H", "I", "M", "N", "QU", "U"],
        ["H", "L", "N", "N", "R", "Z"],
    ]

    /// Generates a random 4×4 grid by shuffling and rolling all 16 dice.
    static func generate() -> [[String]] {
        var shuffled = dice.shuffled()
        let letters = shuffled.map { die in die.randomElement()! }
        return stride(from: 0, to: 16, by: 4).map { start in
            Array(letters[start..<start+4])
        }
    }
}
