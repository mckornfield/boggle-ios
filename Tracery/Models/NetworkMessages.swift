import Foundation

enum MessageType: String, Codable {
    case gridMessage
    case timerStart
    case wordList
    case roundResults
    case playerJoined
    case startGame
}

struct NetworkMessage: Codable {
    let type: MessageType
    let payload: Data
}

struct GridMessage: Codable {
    let letters: [[String]]  // 4x4
}

struct TimerStartMessage: Codable {
    let startDate: Date
    let durationSeconds: Int
}

struct WordListMessage: Codable {
    let playerID: UUID
    let words: [String]
}

struct PlayerResultMessage: Codable {
    let playerID: UUID
    let playerName: String
    let words: [String]
    let validWords: [String]
    let duplicateWords: [String]
    let roundScore: Int
}

struct RoundResultsMessage: Codable {
    let results: [PlayerResultMessage]
}

struct PlayerJoinedMessage: Codable {
    let playerID: UUID
    let playerName: String
}

struct StartGameMessage: Codable {
    let players: [PlayerJoinedMessage]
    let winTarget: Int
}

// MARK: - Encode/Decode helpers

extension NetworkMessage {
    static func encode<T: Encodable>(_ value: T, type messageType: MessageType) throws -> Data {
        let payload = try JSONEncoder().encode(value)
        let msg = NetworkMessage(type: messageType, payload: payload)
        return try JSONEncoder().encode(msg)
    }

    static func decode(from data: Data) throws -> NetworkMessage {
        try JSONDecoder().decode(NetworkMessage.self, from: data)
    }

    func decoded<T: Decodable>(as type: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: payload)
    }
}
