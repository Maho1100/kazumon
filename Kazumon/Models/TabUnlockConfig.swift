import Foundation

enum KazumonTab: String, CaseIterable {
    case home       // 常時解放
    case collection // 100XP
    case bgm        // 500XP
    case extra      // 800XP
    case settings   // 常時解放

    var requiredXP: Int {
        switch self {
        case .home:       return 0
        case .collection: return 100
        case .bgm:        return 500
        case .extra:      return 800
        case .settings:   return 0
        }
    }

    var icon: String {
        switch self {
        case .home:       return "house.fill"
        case .collection: return "books.vertical.fill"
        case .bgm:        return "music.note"
        case .extra:      return "bolt.fill"
        case .settings:   return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .home:       return NSLocalizedString("tab_home", comment: "")
        case .collection: return NSLocalizedString("tab_collection", comment: "")
        case .bgm:        return NSLocalizedString("tab_bgm", comment: "")
        case .extra:      return NSLocalizedString("tab_extra", comment: "")
        case .settings:   return NSLocalizedString("tab_settings", comment: "")
        }
    }

    func isUnlocked(totalXP: Int) -> Bool {
        totalXP >= requiredXP
    }
}
