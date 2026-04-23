import Foundation

struct PlayerData: Codable, Sendable {
    var playerName: String = "カズ" // overridden by DataStore for new users
    var level: Int = 1
    var totalXP: Int = 0
    var bestFloor: Int = 0
    var bestScore: Int = 0
    var streakDays: Int = 0
    var bestStreak: Int = 0
    var lastPlayDate: String? = nil
    var totalPlayCount: Int = 0
    var totalCorrect: Int = 0
    var totalAnswered: Int = 0
    var soundEnabled: Bool = true

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        playerName = try c.decodeIfPresent(String.self, forKey: .playerName) ?? "カズ"
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? 1
        totalXP = try c.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
        bestFloor = try c.decodeIfPresent(Int.self, forKey: .bestFloor) ?? 0
        bestScore = try c.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        lastPlayDate = try c.decodeIfPresent(String.self, forKey: .lastPlayDate)
        totalPlayCount = try c.decodeIfPresent(Int.self, forKey: .totalPlayCount) ?? 0
        totalCorrect = try c.decodeIfPresent(Int.self, forKey: .totalCorrect) ?? 0
        totalAnswered = try c.decodeIfPresent(Int.self, forKey: .totalAnswered) ?? 0
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
    }
}

enum LevelTable {
    static let xpRequired: [Int] = [
        0,      // Lv.1
        30,     // Lv.2
        80,     // Lv.3
        150,    // Lv.4
        250,    // Lv.5
        400,    // Lv.6
        600,    // Lv.7
        850,    // Lv.8
        1150,   // Lv.9
        1500,   // Lv.10
        2000,   // Lv.11
        2600,   // Lv.12
        3300,   // Lv.13
        4100,   // Lv.14
        5000,   // Lv.15
        6000,   // Lv.16
        7200,   // Lv.17
        8600,   // Lv.18
        10200,  // Lv.19
        12000,  // Lv.20
        14500,  // Lv.21
        17500,  // Lv.22
        21000,  // Lv.23
        25000,  // Lv.24
        30000,  // Lv.25
    ]

    static func calcLevel(totalXP: Int) -> Int {
        for i in stride(from: xpRequired.count - 1, through: 0, by: -1) {
            if totalXP >= xpRequired[i] {
                return i + 1
            }
        }
        return 1
    }

    static func xpForNextLevel(_ level: Int) -> Int? {
        let index = level // level is 1-based, next level index = level
        guard index < xpRequired.count else { return nil }
        return xpRequired[index]
    }

    static func xpProgress(totalXP: Int, level: Int) -> Double {
        let currentReq = level >= 1 && level <= xpRequired.count ? xpRequired[level - 1] : 0
        guard let nextReq = xpForNextLevel(level) else { return 1.0 }
        let range = nextReq - currentReq
        guard range > 0 else { return 1.0 }
        return Double(totalXP - currentReq) / Double(range)
    }
}
