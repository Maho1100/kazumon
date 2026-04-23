import Foundation

/// 家族モードの参加メンバー（子供視点での呼称）
enum FamilyMember: String, Codable, CaseIterable, Identifiable {
    case father         // おとうさん
    case mother         // おかあさん
    case grandfather    // おじいちゃん
    case grandmother    // おばあちゃん
    case olderBrother   // おにいちゃん
    case olderSister    // おねえちゃん
    case self_          // じぶん
    case youngerBrother // おとうと
    case youngerSister  // いもうと

    var id: String { rawValue }

    var labelKey: String {
        switch self {
        case .father:         return "family_member_father"
        case .mother:         return "family_member_mother"
        case .grandfather:    return "family_member_grandfather"
        case .grandmother:    return "family_member_grandmother"
        case .olderBrother:   return "family_member_older_brother"
        case .olderSister:    return "family_member_older_sister"
        case .self_:          return "family_member_self"
        case .youngerBrother: return "family_member_younger_brother"
        case .youngerSister:  return "family_member_younger_sister"
        }
    }

    var label: String {
        NSLocalizedString(labelKey, comment: "")
    }

    var emoji: String {
        switch self {
        case .father:         return "👨"
        case .mother:         return "👩"
        case .grandfather:    return "👴"
        case .grandmother:    return "👵"
        case .olderBrother:   return "👦"
        case .olderSister:    return "👧"
        case .self_:          return "🧒"
        case .youngerBrother: return "👶"
        case .youngerSister:  return "👶"
        }
    }

    var isParent: Bool {
        self == .father || self == .mother || self == .grandfather || self == .grandmother
    }
}
