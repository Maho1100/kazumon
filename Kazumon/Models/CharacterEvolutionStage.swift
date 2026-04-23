import Foundation

enum CharacterEvolutionStage: Int, CaseIterable {
    case base      = 0  // Lv1〜4
    case evolve1   = 1  // Lv5〜9
    case evolve2   = 2  // Lv10〜19
    case finalForm = 3  // Lv20+

    var displayName: String {
        switch self {
        case .base:      return NSLocalizedString("model_evolution_base", comment: "")
        case .evolve1:   return NSLocalizedString("model_evolution_stage1", comment: "")
        case .evolve2:   return NSLocalizedString("model_evolution_stage2", comment: "")
        case .finalForm: return NSLocalizedString("model_evolution_final", comment: "")
        }
    }
}
