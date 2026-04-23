import Foundation

/// 家族モードで子供が選べるモンスター（挑戦相手）
/// 既存のMonster.forFloor() の階層に対応した「開始フロア」を持つ
enum MonsterChoice: String, CaseIterable, Identifiable {
    case slime    // 1F〜
    case goblin   // 6F〜
    case orc      // 11F〜
    case dragon   // 16F〜
    case demon    // 21F〜

    var id: String { rawValue }

    /// バトル開始時のフロア（既存Monster.forFloor()と整合）
    var startFloor: Int {
        switch self {
        case .slime:  return 1
        case .goblin: return 6
        case .orc:    return 11
        case .dragon: return 16
        case .demon:  return 21
        }
    }

    /// ボスフロア（Monster.forFloor()のボス階）
    var bossFloor: Int {
        switch self {
        case .slime:  return 5
        case .goblin: return 10
        case .orc:    return 15
        case .dragon: return 20
        case .demon:  return 30
        }
    }

    /// 一つ下のモンスター（ザコ戦用）
    var previousTier: MonsterChoice? {
        switch self {
        case .slime:  return nil
        case .goblin: return .slime
        case .orc:    return .goblin
        case .dragon: return .orc
        case .demon:  return .dragon
        }
    }

    /// 強さの星の数（UI表示用）
    var starCount: Int {
        switch self {
        case .slime:  return 1
        case .goblin: return 2
        case .orc:    return 3
        case .dragon: return 4
        case .demon:  return 5
        }
    }

    var emoji: String {
        switch self {
        case .slime:  return "🟢"
        case .goblin: return "👹"
        case .orc:    return "👺"
        case .dragon: return "🐉"
        case .demon:  return "😈"
        }
    }

    /// 水彩スプライト画像名
    var imageName: String {
        switch self {
        case .slime:  return "monster_slime"
        case .goblin: return "monster_goblin"
        case .orc:    return "monster_orc"
        case .dragon: return "monster_dragon"
        case .demon:  return "monster_demon"
        }
    }

    var labelKey: String {
        switch self {
        case .slime:  return "monster_choice_slime"
        case .goblin: return "monster_choice_goblin"
        case .orc:    return "monster_choice_orc"
        case .dragon: return "monster_choice_dragon"
        case .demon:  return "monster_choice_demon"
        }
    }

    var label: String {
        NSLocalizedString(labelKey, comment: "")
    }
}
