import Foundation

struct MistakeBossConfig {
    static let minMistakesRequired = 3   // バナー表示・バトル開始の最低間違い数
    static let appearanceThreshold = 10  // 累計間違いでおに出現をスケジュール
    static let maxProblems = 20
    static let bossHP = 30          // 鬼のHP=必要正解数（HPバー連動）
    static let timeLimit = 15
    static let xpBonus = 100
    static let playerHP = 3

    static let introLines = [
        NSLocalizedString("mistake_boss_intro_1", comment: ""),
        NSLocalizedString("mistake_boss_intro_2", comment: ""),
        NSLocalizedString("mistake_boss_intro_3", comment: ""),
    ]

    static let defeatLines = [
        NSLocalizedString("mistake_boss_defeat_1", comment: ""),
        NSLocalizedString("mistake_boss_defeat_2", comment: ""),
        NSLocalizedString("mistake_boss_defeat_3", comment: ""),
    ]
}
