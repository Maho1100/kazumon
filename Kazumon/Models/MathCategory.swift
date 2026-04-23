import Foundation

enum MathCategory: String, CaseIterable, Codable {
    case additionBasic     // たし算基礎（答え ≤ 10）
    case additionCarry     // くり上がりのたし算（答え ≥ 11）
    case subtractionBasic  // ひき算基礎（a ≤ 10）
    case subtractionBorrow // くり下がりのひき算（a ≥ 11）

    static let masteryThreshold = 20  // 各カテゴリ20問でマスター

    var label: String {
        switch self {
        case .additionBasic:     return NSLocalizedString("mastery_addition_basic", comment: "")
        case .additionCarry:     return NSLocalizedString("mastery_addition_carry", comment: "")
        case .subtractionBasic:  return NSLocalizedString("mastery_subtraction_basic", comment: "")
        case .subtractionBorrow: return NSLocalizedString("mastery_subtraction_borrow", comment: "")
        }
    }

    static func classify(a: Int, b: Int, operatorSymbol: String) -> MathCategory {
        if operatorSymbol == "＋" {
            return (a + b) <= 10 ? .additionBasic : .additionCarry
        } else {
            return a <= 10 ? .subtractionBasic : .subtractionBorrow
        }
    }
}
