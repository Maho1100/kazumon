import Foundation

/// 家族メンバー1人分のベストスコア記録
struct FamilyScore: Codable, Equatable {
    var bestScore: Int
    var lastPlayedAt: Date?
    var playCount: Int

    init(bestScore: Int = 0, lastPlayedAt: Date? = nil, playCount: Int = 0) {
        self.bestScore = bestScore
        self.lastPlayedAt = lastPlayedAt
        self.playCount = playCount
    }
}
