import Foundation
import SwiftUI

// MARK: - キャラクター外見定義
struct CharacterAppearance: Equatable {
    let body: String
    var head: String? = nil       // 頭パーツ（nil = 非表示）
    let eyes: String              // スプライト目（フォールバック用）
    let mouth: String
    let leftArm: String?
    let rightArm: String?
    let legs: String?
    var bodyColor: Color? = nil   // ボディ全体の色乗算（nil = スプライトそのまま）
    var limbTint: Color? = nil    // 腕・足の色乗算（nil = bodyColorにフォールバック）
    var headTint: Color? = nil    // 頭の色乗算
    let detail: String
    var detail2: String = "detail_none"  // 2つ目のツノ等
    var detail3: String = "detail_none"  // 3つ目のツノ等
    let nose: String?
    let eyeOffsetY: CGFloat       // 体の高さに対する目の縦位置（0〜1）
    let mouthOffsetY: CGFloat     // 体の高さに対する口の縦位置（0〜1）

    // SwiftUI目パーツ（nilならスプライトにフォールバック）
    var eyeStyle: EyeStyle? = nil
    var browMood: BrowMood = .normal
    var eyeAnimated: Bool = true  // キョロキョロ有効
}

// MARK: - カズ（主人公）
extension CharacterAppearance {
    static let kazu = CharacterAppearance(
        body: "body_blueB",
        head: nil,                                            // 頭は非表示
        eyes: "eye_human",
        mouth: "mouth_closed_happy",
        leftArm: "arm_blueA",
        rightArm: "arm_blueA",
        legs: "leg_blueA",
        limbTint: Color(red: 0.53, green: 0.87, blue: 0.80),  // ミント色
        headTint: Color(red: 0.53, green: 0.87, blue: 0.80),  // 頭もミント色
        detail: "detail_none",
        nose: nil,
        eyeOffsetY: 0.33,
        mouthOffsetY: 0.62,
        eyeStyle: .friendly,
        browMood: .normal,
        eyeAnimated: true
    )
}

// MARK: - モンスター（フロア別）
extension CharacterAppearance {
    static let slime = CharacterAppearance(
        body: "body_greenB", eyes: "eye_cute_dark", mouth: "mouth_closed_happy",
        leftArm: nil, rightArm: nil, legs: nil, detail: "detail_none", nose: nil,
        eyeOffsetY: 0.35, mouthOffsetY: 0.65,
        eyeStyle: .cute, browMood: .normal, eyeAnimated: true
    )
    static let enemySlime = CharacterAppearance(
        body: "body_base_B", eyes: "eye_human", mouth: "mouth_closed_happy",
        leftArm: nil, rightArm: nil, legs: nil,
        bodyColor: Color(red: 0.45, green: 0.75, blue: 0.40),
        detail: "detail_none", nose: nil,
        eyeOffsetY: 0.35, mouthOffsetY: 0.65,
        eyeStyle: .neutral, browMood: .angry, eyeAnimated: true
    )
    static let bossSlime = CharacterAppearance(
        body: "body_greenC", eyes: "eye_angry_green", mouth: "mouth_closed_fangs",
        leftArm: "arm_greenA", rightArm: "arm_greenA", legs: nil,
        detail: "detail_green_horn_large", nose: nil,
        eyeOffsetY: 0.33, mouthOffsetY: 0.53,
        eyeStyle: .angry, browMood: .angry, eyeAnimated: true
    )
    static let goblin = CharacterAppearance(
        body: "body_darkB", eyes: "eye_human", mouth: "mouthA",
        leftArm: "arm_darkA", rightArm: "arm_darkA", legs: "leg_darkA",
        detail: "detail_none", nose: "nose_brown",
        eyeOffsetY: 0.33, mouthOffsetY: 0.53,
        eyeStyle: .neutral, browMood: .normal, eyeAnimated: true
    )
    static let bossGoblin = CharacterAppearance(
        body: "body_base_C", eyes: "eye_angry_blue", mouth: "mouthH",
        leftArm: "arm_base_A", rightArm: "arm_base_A", legs: "leg_base_A",
        bodyColor: Color(red: 0.30, green: 0.30, blue: 0.35),
        detail: "detail_base_horn_large", nose: "nose_brown",
        eyeOffsetY: 0.31, mouthOffsetY: 0.55,
        eyeStyle: .angry, browMood: .angry, eyeAnimated: true
    )
    static let orc = CharacterAppearance(
        body: "body_redB", eyes: "eye_human_red", mouth: "mouthC",
        leftArm: "arm_redA", rightArm: "arm_redA", legs: "leg_redA",
        detail: "detail_none", nose: "nose_red",
        eyeOffsetY: 0.33, mouthOffsetY: 0.53,
        eyeStyle: .neutral, browMood: .angry, eyeAnimated: true
    )
    static let bossOrc = CharacterAppearance(
        body: "body_redC", eyes: "eye_human_red", mouth: "mouthE",
        leftArm: "arm_redA", rightArm: "arm_redA", legs: "leg_redA",
        detail: "detail_red_horn_large", nose: "nose_red",
        eyeOffsetY: 0.31, mouthOffsetY: 0.51,
        eyeStyle: .angry, browMood: .angry, eyeAnimated: true
    )
    static let dragon = CharacterAppearance(
        body: "body_blueC", eyes: "eye_blue", mouth: "mouthB",
        leftArm: "arm_blueA", rightArm: "arm_blueA", legs: "leg_blueA",
        detail: "detail_blue_horn_large", nose: nil,
        eyeOffsetY: 0.33, mouthOffsetY: 0.53,
        eyeStyle: .neutral, browMood: .normal, eyeAnimated: true
    )
    static let bossDragon = CharacterAppearance(
        body: "body_blueA", eyes: "eye_angry_blue", mouth: "mouthH",
        leftArm: "arm_blueA", rightArm: "arm_blueA", legs: "leg_blueA",
        detail: "detail_blue_horn_large", nose: nil,
        eyeOffsetY: 0.30, mouthOffsetY: 0.50,
        eyeStyle: .angry, browMood: .angry, eyeAnimated: true
    )
    static let demon = CharacterAppearance(
        body: "body_darkA", eyes: "eye_human_green", mouth: "mouthD",
        leftArm: "arm_darkA", rightArm: "arm_darkA", legs: "leg_darkA",
        detail: "detail_yellow_horn_large", nose: nil,
        eyeOffsetY: 0.33, mouthOffsetY: 0.53,
        eyeStyle: .angry, browMood: .angry, eyeAnimated: true
    )
    static let demonLord = CharacterAppearance(
        body: "body_yellowB", eyes: "eye_yellow", mouth: "mouthH",
        leftArm: "arm_yellowA", rightArm: "arm_yellowA", legs: "leg_yellowA",
        detail: "detail_yellow_horn_large", nose: nil,
        eyeOffsetY: 0.28, mouthOffsetY: 0.50,
        eyeStyle: .angry, browMood: .angry, eyeAnimated: true
    )

    static let mistakeOni = CharacterAppearance(
        body: "body_whiteF", eyes: "eye_yellow", mouth: "mouthH",
        leftArm: "arm_darkB", rightArm: "arm_darkB", legs: "leg_darkD",
        detail: "detail_dark_ear_round", nose: nil,
        eyeOffsetY: 0.30, mouthOffsetY: 0.50,
        eyeStyle: .psycho, browMood: .determined, eyeAnimated: true
    )

    static let timeBoss = CharacterAppearance(
        body: "body_darkB", eyes: "eye_yellow", mouth: "mouthH",
        leftArm: "arm_darkE", rightArm: "arm_darkE", legs: "leg_darkE",
        detail: "detail_yellow_horn_large", nose: nil,
        eyeOffsetY: 0.20, mouthOffsetY: 0.50,
        eyeStyle: .psycho, browMood: .determined, eyeAnimated: true
    )

    // フロアからモンスター外見を取得
    static func forFloor(_ floor: Int) -> CharacterAppearance {
        switch floor {
        case 1...4:   return .enemySlime
        case 5:       return .bossSlime
        case 6...9:   return .goblin
        case 10:      return .bossGoblin
        case 11...14: return .orc
        case 15:      return .bossOrc
        case 16...19: return .dragon
        case 20:      return .bossDragon
        case 21...29: return .demon
        default:      return .demonLord
        }
    }
}
