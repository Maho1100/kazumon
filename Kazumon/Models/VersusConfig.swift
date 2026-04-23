import Foundation

struct VersusConfig {
    static let questionCount = 30
    static let timeLimit: Double = 8.0
    static let winBP = 24
    static let loseBP = -8

    enum Rank: String {
        case C, B, A, S

        var title: String {
            switch self {
            case .C: return NSLocalizedString("versus_rank_c", comment: "")
            case .B: return NSLocalizedString("versus_rank_b", comment: "")
            case .A: return NSLocalizedString("versus_rank_a", comment: "")
            case .S: return NSLocalizedString("versus_rank_s", comment: "")
            }
        }

        var color: String {
            switch self {
            case .C: return "gray"
            case .B: return "blue"
            case .A: return "orange"
            case .S: return "purple"
            }
        }
    }

    static func rank(for bp: Int) -> Rank {
        switch bp {
        case 300...: return .S
        case 150...: return .A
        case 50...:  return .B
        default:     return .C
        }
    }
}
