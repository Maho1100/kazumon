import Foundation

struct DifficultyConfig: Sendable {
    let minA: Int
    let maxA: Int
    let minB: Int
    let maxB: Int
    let errorRange: Int

    static func forFloor(_ floor: Int, difficulty: Difficulty = .hard) -> DifficultyConfig {
        switch difficulty {
        case .easy:
            return forFloorEasy(floor)
        case .normal:
            return forFloorNormal(floor)
        case .hard:
            return forFloorHard(floor)
        }
    }

    // MARK: - かんたん（数値範囲を小さめに）

    private static func forFloorEasy(_ floor: Int) -> DifficultyConfig {
        switch floor {
        case 1...5:   return DifficultyConfig(minA: 1, maxA: 3, minB: 1, maxB: 3, errorRange: 2)
        case 6...10:  return DifficultyConfig(minA: 1, maxA: 5, minB: 1, maxB: 5, errorRange: 2)
        case 11...20: return DifficultyConfig(minA: 1, maxA: 9, minB: 1, maxB: 9, errorRange: 3)
        case 21...30: return DifficultyConfig(minA: 3, maxA: 9, minB: 3, maxB: 9, errorRange: 3)
        default:      return DifficultyConfig(minA: 5, maxA: 9, minB: 5, maxB: 9, errorRange: 4)
        }
    }

    // MARK: - ふつう

    private static func forFloorNormal(_ floor: Int) -> DifficultyConfig {
        switch floor {
        case 1...5:   return DifficultyConfig(minA: 1,  maxA: 5,  minB: 1,  maxB: 4,  errorRange: 2)
        case 6...10:  return DifficultyConfig(minA: 1,  maxA: 9,  minB: 1,  maxB: 9,  errorRange: 3)
        case 11...15: return DifficultyConfig(minA: 3,  maxA: 9,  minB: 3,  maxB: 9,  errorRange: 3)
        case 16...20: return DifficultyConfig(minA: 5,  maxA: 30, minB: 1,  maxB: 9,  errorRange: 4)
        case 21...30: return DifficultyConfig(minA: 5,  maxA: 30, minB: 5,  maxB: 30, errorRange: 6)
        case 31...40: return DifficultyConfig(minA: 10, maxA: 40, minB: 10, maxB: 40, errorRange: 8)
        case 41...50: return DifficultyConfig(minA: 15, maxA: 50, minB: 15, maxB: 50, errorRange: 10)
        default:      return DifficultyConfig(minA: 20, maxA: 60, minB: 20, maxB: 60, errorRange: 12)
        }
    }

    // MARK: - むずかしい

    private static func forFloorHard(_ floor: Int) -> DifficultyConfig {
        switch floor {
        case 1...5:   return DifficultyConfig(minA: 1,  maxA: 5,  minB: 1,  maxB: 4,  errorRange: 2)
        case 6...10:  return DifficultyConfig(minA: 1,  maxA: 9,  minB: 1,  maxB: 9,  errorRange: 3)
        case 11...15: return DifficultyConfig(minA: 5,  maxA: 9,  minB: 6,  maxB: 9,  errorRange: 4)
        case 16...20: return DifficultyConfig(minA: 10, maxA: 50, minB: 1,  maxB: 9,  errorRange: 5)
        case 21...30: return DifficultyConfig(minA: 10, maxA: 50, minB: 10, maxB: 50, errorRange: 8)
        case 31...40: return DifficultyConfig(minA: 10, maxA: 50, minB: 10, maxB: 50, errorRange: 8)
        case 41...50: return DifficultyConfig(minA: 20, maxA: 60, minB: 20, maxB: 60, errorRange: 10)
        case 51...60: return DifficultyConfig(minA: 30, maxA: 70, minB: 30, maxB: 70, errorRange: 12)
        case 61...70: return DifficultyConfig(minA: 40, maxA: 80, minB: 40, maxB: 80, errorRange: 15)
        default:      return DifficultyConfig(minA: 50, maxA: 99, minB: 50, maxB: 99, errorRange: 20)
        }
    }
}
