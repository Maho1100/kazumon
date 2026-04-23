import Foundation

struct TimeBossConfig {
    static let fullTimeLimit: Double = 12.0     // 通常の制限時間（バーの全長）
    static let timeLimitSeconds: Double = 6.0    // 実際の制限時間（半分）
    static let xpBonus = 150
    static let triggerDay = 10   // Day10クリアで予告
    static let appearDay = 11    // Day11開始時に出現
    static let maxHP = 3
    static let requiredCorrect = 10

    static let introLines: [String] = [
        NSLocalizedString("time_boss_intro_1", comment: ""),
        NSLocalizedString("time_boss_intro_2", comment: ""),
        NSLocalizedString("time_boss_intro_3", comment: ""),
    ]

    static let defeatLines: [String] = [
        NSLocalizedString("time_boss_defeat_1", comment: ""),
        NSLocalizedString("time_boss_defeat_2", comment: ""),
        NSLocalizedString("time_boss_defeat_3", comment: ""),
    ]
}
