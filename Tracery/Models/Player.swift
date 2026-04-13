import Foundation

struct Player: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var cumulativeScore: Int

    init(id: UUID = UUID(), name: String, cumulativeScore: Int = 0) {
        self.id = id
        self.name = name
        self.cumulativeScore = cumulativeScore
    }
}
