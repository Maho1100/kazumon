import Foundation

enum AgeGroup: String, Codable, Sendable, CaseIterable {
    case young4  // 4さい
    case young   // 5〜6さい
    case older   // 7さい以上

    var label: String {
        switch self {
        case .young4: return NSLocalizedString("age_group_young4", comment: "")
        case .young:  return NSLocalizedString("age_group_young", comment: "")
        case .older:  return NSLocalizedString("age_group_older", comment: "")
        }
    }

    var sublabel: String {
        switch self {
        case .young4: return NSLocalizedString("age_group_young4_sub", comment: "")
        case .young:  return NSLocalizedString("age_group_young_sub", comment: "")
        case .older:  return NSLocalizedString("age_group_older_sub", comment: "")
        }
    }

    /// キャラクターの外見レベル
    var characterLevel: Int {
        switch self {
        case .young4: return 1
        case .young:  return 5
        case .older:  return 10
        }
    }

    /// youngモード扱い（young4 と young は同じUI）
    var isYoungMode: Bool {
        self == .young4 || self == .young
    }
}
