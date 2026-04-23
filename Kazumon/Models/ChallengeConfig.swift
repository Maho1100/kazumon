import Foundation

// MARK: - くもん1年生完全制覇 フェーズ定義

enum MasteryPhase: String, CaseIterable {
    case addition          // たし算（答え≤10）
    case carryAddition     // くり上がり（答え11〜20）
    case subtraction       // ひき算（くり下がりなし）
    case borrowSubtraction // くり下がりひき算

    var label: String {
        switch self {
        case .addition:          return NSLocalizedString("mastery_phase_addition", comment: "")
        case .carryAddition:     return NSLocalizedString("mastery_phase_carry", comment: "")
        case .subtraction:       return NSLocalizedString("mastery_phase_subtraction", comment: "")
        case .borrowSubtraction: return NSLocalizedString("mastery_phase_borrow", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .addition:          return "📚"
        case .carryAddition:     return "🔢"
        case .subtraction:       return "➖"
        case .borrowSubtraction: return "⬇️"
        }
    }

    var days: ClosedRange<Int> {
        switch self {
        case .addition:          return 1...10
        case .carryAddition:     return 11...20
        case .subtraction:       return 21...25
        case .borrowSubtraction: return 26...30
        }
    }
}

// MARK: - ChallengeConfig

struct ChallengeConfig {
    let day: Int
    let title: String
    let problemType: ProblemType
    let difficulty: Difficulty
    let requiredCorrect: Int

    static let requiredCorrectPerDay = 10

    static func forDay(_ day: Int) -> ChallengeConfig {
        let phase = masteryPhase(for: day)
        let pt: ProblemType = (day <= 20) ? .addition : .subtraction
        return ChallengeConfig(
            day: day,
            title: phase.label,
            problemType: pt,
            difficulty: .easy,
            requiredCorrect: requiredCorrectPerDay
        )
    }

    static func masteryPhase(for day: Int) -> MasteryPhase {
        switch day {
        case 1...10:  return .addition
        case 11...20: return .carryAddition
        case 21...25: return .subtraction
        case 26...30: return .borrowSubtraction
        default:      return .addition
        }
    }

    static func phaseName(for day: Int) -> String {
        masteryPhase(for: day).label
    }

    static func phaseProgress(for day: Int) -> String {
        switch day {
        case 1...10:  return NSLocalizedString("mastery_progress_addition", comment: "")
        case 11...20: return NSLocalizedString("mastery_progress_carry", comment: "")
        case 21...25: return NSLocalizedString("mastery_progress_subtraction", comment: "")
        case 26...30: return NSLocalizedString("mastery_progress_borrow", comment: "")
        default:      return NSLocalizedString("mastery_progress_complete", comment: "")
        }
    }
}
