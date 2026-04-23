import Foundation

struct FloorRank {

    /// メダル絵文字（フロア到達数）
    static func medal(for floor: Int) -> String {
        switch floor {
        case  1...4:  return "🥉"
        case  5...9:  return "🥈"
        case 10...14: return "🥇"
        case 15...19: return "🏅"
        case 20...24: return "🎖️"
        case 25...29: return "🏆"
        default:      return "👑"
        }
    }

    /// 星の数（正解率ベース、0〜5）
    static func stars(
        correctCount: Int,
        totalCount: Int,
        avgAnswerSeconds: Double? = nil
    ) -> Int {
        guard totalCount > 0 else { return 0 }
        let rate = Double(correctCount) / Double(totalCount)
        switch rate {
        case 0.0..<0.60:  return 1
        case 0.60..<0.75: return 2
        case 0.75..<0.85: return 3
        case 0.85..<0.95: return 4
        default:          return 5
        }
    }

    /// キャラクターのセリフ（リザルト画面用）
    static func characterComment(for floor: Int) -> String {
        switch floor {
        case 1...4:   return NSLocalizedString("floor_comment_1", comment: "")
        case 5...9:   return NSLocalizedString("floor_comment_2", comment: "")
        case 10...14: return NSLocalizedString("floor_comment_3", comment: "")
        case 15...19: return NSLocalizedString("floor_comment_4", comment: "")
        case 20...24: return NSLocalizedString("floor_comment_5", comment: "")
        case 25...29: return NSLocalizedString("floor_comment_6", comment: "")
        default:      return NSLocalizedString("floor_comment_7", comment: "")
        }
    }

    /// 星に対応するメッセージ
    static func starMessage(for stars: Int) -> String {
        switch stars {
        case 1:  return NSLocalizedString("star_msg_1", comment: "")
        case 2:  return NSLocalizedString("star_msg_2", comment: "")
        case 3:  return NSLocalizedString("star_msg_3", comment: "")
        case 4:  return NSLocalizedString("star_msg_4", comment: "")
        default: return NSLocalizedString("star_msg_5", comment: "")
        }
    }
}
