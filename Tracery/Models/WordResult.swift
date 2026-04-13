import Foundation

struct WordResult: Identifiable {
    let id = UUID()
    let word: String
    let isInDictionary: Bool
    let isTraceable: Bool
    let isDuplicate: Bool   // set after cross-player comparison

    var isValid: Bool { isInDictionary && isTraceable && !isDuplicate }
    var points: Int { isValid ? ScoringEngine.points(for: word) : 0 }
}
