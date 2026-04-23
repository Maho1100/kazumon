import Foundation
import SwiftUI

enum Difficulty: String, CaseIterable, Codable {
    case easy, normal, hard

    var label: String {
        switch self {
        case .easy:   return NSLocalizedString("difficulty_easy", comment: "")
        case .normal: return NSLocalizedString("difficulty_normal", comment: "")
        case .hard:   return NSLocalizedString("difficulty_hard", comment: "")
        }
    }

    var goalFloor: Int {
        switch self {
        case .easy:   return 10
        case .normal: return 20
        case .hard:   return 30
        }
    }

    var icon: String {
        switch self {
        case .easy:   return "star.fill"
        case .normal: return "flame.fill"
        case .hard:   return "flame.fill"
        }
    }

    var starCount: Int {
        switch self {
        case .easy:   return 1
        case .normal: return 2
        case .hard:   return 3
        }
    }

    var color: Color {
        switch self {
        case .easy:   return .green
        case .normal: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .hard:   return .red
        }
    }

    /// 推定プレイ時間（分）
    var estimatedMinutes: Int {
        switch self {
        case .easy:   return 2
        case .normal: return 6
        case .hard:   return 11
        }
    }

    /// 時間ラベル（「やく2ふん」）
    var labelWithTime: String {
        let about = NSLocalizedString("difficulty_about", comment: "")
        let min = NSLocalizedString("difficulty_minutes", comment: "")
        return "\(about)\(estimatedMinutes)\(min)"
    }
}
