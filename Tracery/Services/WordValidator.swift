import Foundation

enum WordValidator {
    /// Returns true if `word` can be traced on the grid — adjacent tiles, each used at most once.
    /// The "QU" tile matches the two-character sequence "QU" in the word.
    static func isTraceable(_ word: String, on grid: Grid) -> Bool {
        let upper = word.uppercased()
        guard upper.count >= 3 else { return false }

        for startTile in grid.allTiles {
            if dfs(word: upper, index: upper.startIndex, tile: startTile, grid: grid, used: []) {
                return true
            }
        }
        return false
    }

    private static func dfs(
        word: String,
        index: String.Index,
        tile: Tile,
        grid: Grid,
        used: Set<UUID>
    ) -> Bool {
        guard index < word.endIndex else { return true }

        // Check that the current tile matches at the current word index
        let tileLetter = tile.letter  // e.g. "A" or "QU"
        let remaining = word[index...]

        guard remaining.hasPrefix(tileLetter) else { return false }

        let nextIndex = word.index(index, offsetBy: tileLetter.count)
        var newUsed = used
        newUsed.insert(tile.id)

        // Base case: consumed entire word
        if nextIndex == word.endIndex { return true }

        // Recurse into adjacent, unused tiles
        for neighbor in grid.allTiles where !newUsed.contains(neighbor.id) && tile.isAdjacent(to: neighbor) {
            if dfs(word: word, index: nextIndex, tile: neighbor, grid: grid, used: newUsed) {
                return true
            }
        }
        return false
    }

    /// Validates a list of words against the dictionary and grid, and marks duplicates.
    /// `playerWords` maps playerID → [word]. Duplicate words (found by >1 player) are flagged.
    static func validateAll(
        playerWords: [UUID: [String]],
        grid: Grid,
        dictionary: DictionaryService
    ) -> [UUID: [WordResult]] {
        // Count how many players submitted each word
        var wordPlayerCount: [String: Int] = [:]
        for words in playerWords.values {
            for word in words {
                let upper = word.uppercased()
                wordPlayerCount[upper, default: 0] += 1
            }
        }

        var results: [UUID: [WordResult]] = [:]
        for (playerID, words) in playerWords {
            // Deduplicate within a single player's list (case-insensitive)
            var seen: Set<String> = []
            var deduped: [String] = []
            for word in words {
                let upper = word.uppercased()
                if seen.insert(upper).inserted { deduped.append(upper) }
            }

            results[playerID] = deduped.map { upper in
                WordResult(
                    word: upper,
                    isInDictionary: dictionary.isValidWord(upper),
                    isTraceable: isTraceable(upper, on: grid),
                    isDuplicate: (wordPlayerCount[upper] ?? 0) > 1
                )
            }
        }
        return results
    }
}
