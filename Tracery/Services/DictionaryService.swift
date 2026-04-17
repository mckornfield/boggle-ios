import Foundation

@Observable
class DictionaryService {
    private(set) var isLoaded = false
    private(set) var loadFailed = false
    private var wordSet: Set<String> = []

    init() {
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.load()
        }
    }

    private func load() async {
        guard let url = Bundle.main.url(forResource: "twl", withExtension: "txt") else {
            print("[DictionaryService] twl.txt not found in bundle")
            await MainActor.run {
                self.loadFailed = true
                self.isLoaded = true
            }
            return
        }
        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            let words = Set(contents.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
                .filter { !$0.isEmpty })
            await MainActor.run {
                self.wordSet = words
                self.isLoaded = true
            }
        } catch {
            print("[DictionaryService] Failed to load dictionary: \(error)")
            await MainActor.run {
                self.loadFailed = true
                self.isLoaded = true
            }
        }
    }

    func isValidWord(_ word: String) -> Bool {
        let upper = word.uppercased()
        return wordSet.contains(upper)
    }
}
