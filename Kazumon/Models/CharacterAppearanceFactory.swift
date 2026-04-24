import Foundation
import SwiftUI

enum CharacterAppearanceFactory {
    // 主人公（水滴キャラ）の腕・足の色補正
    static let heroLimbTint = Color(red: 0.53, green: 0.87, blue: 0.80)

    /// 色名 → Color値マッピング（グレースケールスプライトにcolorMultiplyで適用）
    static let colorValues: [String: Color] = [
        "blue":   Color(red: 0.35, green: 0.75, blue: 0.95),
        "red":    Color(red: 0.90, green: 0.35, blue: 0.30),
        "yellow": Color(red: 0.95, green: 0.80, blue: 0.20),
        "green":  Color(red: 0.30, green: 0.75, blue: 0.40),
        "dark":   Color(red: 0.30, green: 0.30, blue: 0.35),
        "white":  Color(red: 0.90, green: 0.90, blue: 0.92),
        "pink":   Color(red: 0.95, green: 0.60, blue: 0.75),
        "gold":   Color(red: 0.90, green: 0.75, blue: 0.30),
    ]

    /// グレースケールスプライトが存在するか（存在すればbodyColorで着色）
    static func hasBaseSprite(_ variant: String) -> Bool {
        // Assets.xcassetsの個別画像 or スプライトシートのどちらかに存在するか
        UIImage(named: "body_base_\(variant)") != nil || spriteFrames["body_base_\(variant)"] != nil
    }


    // MARK: - レベル → 進化段階

    static func stage(for level: Int) -> CharacterEvolutionStage {
        switch level {
        case ...4:    return .base
        case 5...9:   return .evolve1
        case 10...19: return .evolve2
        default:      return .finalForm
        }
    }

    // MARK: - レベル → 見た目（選択色を反映）

    static func appearance(for level: Int) -> CharacterAppearance {
        let selectedColor = DataStore.loadSelectedBodyColor()
        return appearance(for: stage(for: level), color: selectedColor)
    }

    static func appearance(for stage: CharacterEvolutionStage) -> CharacterAppearance {
        let selectedColor = DataStore.loadSelectedBodyColor()
        return appearance(for: stage, color: selectedColor)
    }

    static func appearance(for stage: CharacterEvolutionStage, color: String) -> CharacterAppearance {
        let detailType = DataStore.loadSelectedDetailType()
        return appearance(for: stage, color: color, detailType: detailType)
    }

    static func appearance(for stage: CharacterEvolutionStage, color: String, detailType: String) -> CharacterAppearance {
        // ステージに応じたバリアント
        let variant: String
        switch stage {
        case .base, .evolve1, .evolve2: variant = "B"
        case .finalForm:                variant = "C"
        }

        // グレースケールベーススプライトが存在すればそちらを使い、bodyColorで着色
        let useBase = hasBaseSprite(variant)
        let bodyName: String
        let armName: String
        let legName: String
        let tintColor: Color?

        if useBase {
            bodyName = "body_base_\(variant)"
            armName  = (UIImage(named: "arm_base_A") != nil || spriteFrames["arm_base_A"] != nil) ? "arm_base_A" : "arm_blueA"
            legName  = (UIImage(named: "leg_base_A") != nil || spriteFrames["leg_base_A"] != nil) ? "leg_base_A" : "leg_blueA"
            tintColor = colorValues[color] ?? colorValues["blue"]
        } else {
            let bn = "body_\(color)\(variant)"
            bodyName = CharacterPartOffsets.isRegistered(bn) ? bn : "body_blue\(variant)"
            let an = "arm_\(color)A"
            let ln = "leg_\(color)A"
            armName = spriteFrames[an] != nil ? an : "arm_blueA"
            legName = spriteFrames[ln] != nil ? ln : "leg_blueA"
            tintColor = nil
        }

        let safeBody = bodyName
        let safeArm = armName
        let safeLeg = legName

        // ツノ: グレースケールベースがあればベースを使用、なければ色別スプライト
        let detailColor = useBase ? "base" : color
        let (d1, d2, d3) = resolveDetails(type: detailType, color: detailColor)

        switch stage {
        case .base:
            return CharacterAppearance(
                body: safeBody,
                eyes: "eye_human",
                mouth: "mouth_closed_happy",
                leftArm: safeArm, rightArm: safeArm,
                legs: safeLeg,
                bodyColor: tintColor,
                limbTint: tintColor != nil ? nil : heroLimbTint,
                detail: d1, detail2: d2, detail3: d3,
                nose: nil,
                eyeOffsetY: 0.33, mouthOffsetY: 0.62,
                eyeStyle: .friendly, browMood: .normal, eyeAnimated: true
            )

        case .evolve1:
            return CharacterAppearance(
                body: safeBody,
                eyes: "eye_human",
                mouth: "mouthA",
                leftArm: safeArm, rightArm: safeArm,
                legs: safeLeg,
                bodyColor: tintColor,
                limbTint: tintColor != nil ? nil : heroLimbTint,
                detail: d1, detail2: d2, detail3: d3,
                nose: nil,
                eyeOffsetY: 0.33, mouthOffsetY: 0.58,
                eyeStyle: .neutral, browMood: .normal, eyeAnimated: true
            )

        case .evolve2:
            return CharacterAppearance(
                body: safeBody,
                eyes: "eye_human",
                mouth: "mouthB",
                leftArm: safeArm, rightArm: safeArm,
                legs: safeLeg,
                bodyColor: tintColor,
                limbTint: tintColor != nil ? nil : heroLimbTint,
                detail: d1, detail2: d2, detail3: d3,
                nose: nil,
                eyeOffsetY: 0.33, mouthOffsetY: 0.58,
                eyeStyle: .neutral, browMood: .normal, eyeAnimated: true
            )

        case .finalForm:
            return CharacterAppearance(
                body: safeBody,
                eyes: "eye_blue",
                mouth: "mouthB",
                leftArm: safeArm, rightArm: safeArm,
                legs: safeLeg,
                bodyColor: tintColor,
                limbTint: tintColor != nil ? nil : heroLimbTint,
                detail: d1, detail2: d2, detail3: d3,
                nose: nil,
                eyeOffsetY: 0.33, mouthOffsetY: 0.53,
                eyeStyle: .neutral, browMood: .determined, eyeAnimated: true
            )
        }
    }

    /// ツノ種類 + 色 → (detail, detail2, detail3) スプライト名
    /// 例: "horn_x2" + "blue" → ("detail_blue_horn_large", "detail_blue_horn_large", "detail_none")
    private static func resolveDetails(type: String, color: String) -> (String, String, String) {
        if type == "none" { return ("detail_none", "detail_none", "detail_none") }

        // 種類と個数を分離: "horn_x2" → base="horn_large", count=2
        let (base, count) = parseDetailType(type)
        let name = "detail_\(color)_\(base)"
        let safeName = spriteFrames[name] != nil ? name : "detail_none"

        switch count {
        case 1:  return (safeName, "detail_none", "detail_none")
        case 2:  return (safeName, safeName, "detail_none")
        default: return (safeName, safeName, safeName)
        }
    }

    /// "horn_x2" → ("horn_large", 2), "ear_round_x2" → ("ear_round", 2)
    private static func parseDetailType(_ type: String) -> (String, Int) {
        // x1/x2/x3 サフィックスを解析
        if type.hasSuffix("_x1") {
            let base = String(type.dropLast(3))
            return (detailBaseSprite(base), 1)
        } else if type.hasSuffix("_x2") {
            let base = String(type.dropLast(3))
            return (detailBaseSprite(base), 2)
        } else if type.hasSuffix("_x3") {
            let base = String(type.dropLast(3))
            return (detailBaseSprite(base), 3)
        }
        // レガシー: "horn_large" 等
        return (type, 1)
    }

    /// ショップID → スプライト名のベース部分
    private static func detailBaseSprite(_ id: String) -> String {
        switch id {
        case "horn":      return "horn_large"
        case "antenna":   return "antenna_large"
        case "ear":       return "ear"
        case "ear_round": return "ear_round"
        default:          return id
        }
    }

    // MARK: - 次の進化レベル

    static func nextEvolutionLevel(after level: Int) -> Int? {
        switch stage(for: level) {
        case .base:      return 5
        case .evolve1:   return 10
        case .evolve2:   return 20
        case .finalForm: return nil
        }
    }
}
