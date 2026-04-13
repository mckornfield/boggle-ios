import Foundation

enum ScoringEngine {
    /// Points for a valid word based on its letter count (QU counts as 2 letters).
    static func points(for word: String) -> Int {
        let letterCount = letterLength(of: word)
        switch letterCount {
        case ..<3: return 0
        case 3...4: return 1
        case 5: return 2
        case 6: return 3
        case 7: return 5
        default: return 11
        }
    }

    /// Letter count treating "QU" as 2 letters.
    static func letterLength(of word: String) -> Int {
        // Words are stored as plain strings; "QU" within a word contributes 2 letters naturally
        // since the tile letter "QU" gets stored as "QU" in the traced word.
        return word.uppercased().count
    }

    /// Computes round scores from validated word results.
    static func roundScores(from results: [UUID: [WordResult]]) -> [UUID: Int] {
        results.mapValues { wordResults in
            wordResults.reduce(0) { $0 + $1.points }
        }
    }
}
