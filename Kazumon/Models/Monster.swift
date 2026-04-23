import Foundation

struct Monster: Sendable {
    let name: String
    let maxHP: Int
    let questionsPerFloor: Int
    let isBoss: Bool
    let timeLimit: Int?

    static func forFloor(_ floor: Int) -> Monster {
        let isBoss = floor % 5 == 0
        switch floor {
        case 1...4:
            return Monster(name: NSLocalizedString("model_monster_slime", comment: ""), maxHP: 1, questionsPerFloor: 1, isBoss: false, timeLimit: nil)
        case 5:
            return Monster(name: NSLocalizedString("model_monster_boss_slime", comment: ""), maxHP: 3, questionsPerFloor: 3, isBoss: true, timeLimit: nil)
        case 6...9:
            return Monster(name: NSLocalizedString("model_monster_goblin", comment: ""), maxHP: 1, questionsPerFloor: 1, isBoss: false, timeLimit: nil)
        case 10:
            return Monster(name: NSLocalizedString("model_monster_boss_goblin", comment: ""), maxHP: 4, questionsPerFloor: 4, isBoss: true, timeLimit: nil)
        case 11...14:
            return Monster(name: NSLocalizedString("model_monster_orc", comment: ""), maxHP: 2, questionsPerFloor: 2, isBoss: false, timeLimit: nil)
        case 15:
            return Monster(name: NSLocalizedString("model_monster_boss_orc", comment: ""), maxHP: 5, questionsPerFloor: 5, isBoss: true, timeLimit: nil)
        case 16...19:
            return Monster(name: NSLocalizedString("model_monster_dragon", comment: ""), maxHP: 2, questionsPerFloor: 2, isBoss: false, timeLimit: 15)
        case 20:
            return Monster(name: NSLocalizedString("model_monster_boss_dragon", comment: ""), maxHP: 6, questionsPerFloor: 6, isBoss: true, timeLimit: 15)
        case 21...29:
            return Monster(name: NSLocalizedString("model_monster_demon", comment: ""), maxHP: 2, questionsPerFloor: 2, isBoss: false, timeLimit: 12)
        case 30:
            return Monster(name: NSLocalizedString("model_monster_maou", comment: ""), maxHP: 8, questionsPerFloor: 8, isBoss: true, timeLimit: 12)
        default:
            let hp = 2 + (floor - 30) / 5
            let q = 2 + (floor - 30) / 5
            let time = max(5, 12 - (floor - 30) / 5)
            return Monster(name: NSLocalizedString("model_monster_unknown", comment: ""), maxHP: hp, questionsPerFloor: q, isBoss: isBoss, timeLimit: time)
        }
    }

    var emoji: String {
        switch name {
        case NSLocalizedString("model_monster_slime", comment: ""):       return "👿"
        case NSLocalizedString("model_monster_boss_slime", comment: ""):  return "👿"
        case NSLocalizedString("model_monster_goblin", comment: ""):      return "👿"
        case NSLocalizedString("model_monster_boss_goblin", comment: ""): return "👿"
        case NSLocalizedString("model_monster_orc", comment: ""):         return "👿"
        case NSLocalizedString("model_monster_boss_orc", comment: ""):    return "👿"
        case NSLocalizedString("model_monster_dragon", comment: ""):      return "👿"
        case NSLocalizedString("model_monster_boss_dragon", comment: ""): return "👿"
        case NSLocalizedString("model_monster_demon", comment: ""):       return "😈"
        case NSLocalizedString("model_monster_maou", comment: ""):        return "👿"
        default:            return "👿"
        }
    }

    /// 水彩スプライト画像名（無ければnil → emoji フォールバック）
    var imageName: String? {
        switch name {
        case NSLocalizedString("model_monster_slime", comment: ""),
             NSLocalizedString("model_monster_boss_slime", comment: ""):
            return "monster_slime"
        case NSLocalizedString("model_monster_goblin", comment: ""),
             NSLocalizedString("model_monster_boss_goblin", comment: ""):
            return "monster_goblin"
        case NSLocalizedString("model_monster_orc", comment: ""),
             NSLocalizedString("model_monster_boss_orc", comment: ""):
            return "monster_orc"
        case NSLocalizedString("model_monster_dragon", comment: ""),
             NSLocalizedString("model_monster_boss_dragon", comment: ""):
            return "monster_dragon"
        case NSLocalizedString("model_monster_demon", comment: ""),
             NSLocalizedString("model_monster_maou", comment: ""):
            return "monster_demon"
        default:
            return nil
        }
    }
}
