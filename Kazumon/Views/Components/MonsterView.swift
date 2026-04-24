import SwiftUI

struct MonsterView: View {
    let monster: Monster
    let floor: Int
    var isHit: Bool = false
    var isDefeated: Bool = false
    var isMistakeBossMode: Bool = false
    var isTimeBossMode: Bool = false
    var isMonsterAttacking: Bool = false
    var currentHP: Int = 1     // ボスの色変化用
    var maxHP: Int = 1
    var questionsAnswered: Int = 0   // 間違い鬼の段階変化用 (進捗バー連動)
    var totalQuestions: Int = 1

    @State private var shakeOffset: CGFloat = 0
    @State private var slimeHitTrigger: Int = 0
    @State private var slimeColor: Color = SlimeView.randomColor()

    /// スライム判定（4歳モードのみSlimeViewを使用）
    private var isSlime: Bool {
        monster.imageName == "monster_slime" && DataStore.loadAgeGroup() == .young4
    }

    /// ボススライムの色: 青(満タン) → 赤(瀕死)
    private var bossSlimeColor: Color {
        let damageRatio = maxHP > 0 ? Double(maxHP - currentHP) / Double(maxHP) : 0
        // 青 (0.40, 0.65, 0.95) → 赤 (0.95, 0.30, 0.30)
        let r = 0.40 + (0.95 - 0.40) * damageRatio
        let g = 0.65 + (0.30 - 0.65) * damageRatio
        let b = 0.95 + (0.30 - 0.95) * damageRatio
        return Color(red: r, green: g, blue: b)
    }

    private var appearance: CharacterAppearance {
        if isMistakeBossMode { return mistakeOniByHP }
        if isTimeBossMode { return .timeBoss }
        return .forFloor(floor)
    }

    /// 間違い鬼の HP 残量に応じた段階的変身（怖い→弱い、達成感重視）
    /// 正解するほど HP が減って弱体化していく
    private var mistakeOniStage: Int {
        guard maxHP > 0 else { return 0 }
        let damageRatio = Double(maxHP - currentHP) / Double(maxHP)
        // 0% = 通常の鬼 / 100% = 撃破直前
        if damageRatio < 0.2  { return 0 }   // HP満タン: 通常 (psycho, determined)
        if damageRatio < 0.4  { return 1 }   // ダメージ: red, surprised
        if damageRatio < 0.6  { return 2 }   // さらに: neutral, 80%
        if damageRatio < 0.8  { return 3 }   // さらに: body_whiteE, 60%
        return 4                              // 瀕死: eye_human (sprite), 80%
    }

    private var mistakeOniByHP: CharacterAppearance {
        var a = CharacterAppearance.mistakeOni
        switch mistakeOniStage {
        case 0:
            return a   // 通常
        case 1:
            // HP半分以下: BrowMood=surprised, EyeStyle=red
            a.browMood = .surprised
            a.eyeStyle = .red
            return a
        case 2:
            // さらにダメージ: EyeStyle=neutral, 大きさ80%
            a.browMood = .surprised
            a.eyeStyle = .neutral
            return a
        case 3:
            // さらに: body=body_whiteE, さらに-20%
            return CharacterAppearance(
                body: "body_whiteE",
                eyes: a.eyes, mouth: a.mouth,
                leftArm: a.leftArm, rightArm: a.rightArm, legs: a.legs,
                detail: a.detail, nose: a.nose,
                eyeOffsetY: a.eyeOffsetY, mouthOffsetY: a.mouthOffsetY,
                eyeStyle: .neutral,
                browMood: .surprised,
                eyeAnimated: a.eyeAnimated
            )
        default:
            // さらに: eye_human, +20%
            return CharacterAppearance(
                body: "body_whiteE",
                eyes: "eye_human", mouth: a.mouth,
                leftArm: a.leftArm, rightArm: a.rightArm, legs: a.legs,
                detail: a.detail, nose: a.nose,
                eyeOffsetY: a.eyeOffsetY, mouthOffsetY: a.mouthOffsetY,
                eyeStyle: nil,  // sprite eye を使用
                browMood: .surprised,
                eyeAnimated: a.eyeAnimated
            )
        }
    }

    private var monsterSize: CGFloat {
        if isMistakeBossMode {
            switch mistakeOniStage {
            case 0, 1: return 100
            case 2:    return 80   // 80%
            case 3:    return 60   // さらに -20%
            default:   return 45   // 瀕死: 45% (片目の弱体化版)
            }
        }
        if isTimeBossMode { return 100 }
        if monster.isBoss { return 100 }
        return 60
    }

    var body: some View {
        Group {
            // 間違い鬼の瀕死(stage 4): 片目+小さい体の専用描画
            if isMistakeBossMode && mistakeOniStage == 4 {
                weakMistakeOniView
            }
            // ボス特殊モードは既存の KennyCharacterView を使用
            else if isMistakeBossMode || isTimeBossMode {
                KennyCharacterView(
                    appearance: appearance,
                    size: monsterSize,
                    isAttacking: isMonsterAttacking,
                    isHurt: isHit,
                    isDefeated: isDefeated,
                    facing: .right
                )
            } else if isSlime {
                // スライム: 4歳モード用 SlimeView を流用、isHit でタップ反応をトリガー
                // ボス(5F) は HP に応じて青→赤に変化
                SlimeView(
                    color: monster.isBoss ? bossSlimeColor : slimeColor,
                    size: monsterImageSize,
                    externalHitTrigger: slimeHitTrigger
                )
                .scaleEffect(isDefeated ? 0.0 : 1.0)
                .opacity(isDefeated ? 0.0 : 1.0)
                .rotationEffect(.degrees(isDefeated ? 30 : 0))
                .animation(.easeOut(duration: 0.4), value: isDefeated)
                .animation(.easeInOut(duration: 0.4), value: currentHP)
                .onChange(of: isHit) { _, hit in
                    if hit { slimeHitTrigger += 1 }
                }
                .onChange(of: floor) { _, _ in
                    slimeColor = SlimeView.randomColor()
                }
            } else {
                // 通常モンスター（ゴブリン/オーク/ドラゴン/デーモン等）: スプライトシートで描画
                KennyCharacterView(
                    appearance: appearance,
                    size: monsterSize,
                    isAttacking: isMonsterAttacking,
                    isHurt: isHit,
                    isDefeated: isDefeated,
                    facing: .right
                )
            }
        }
        .offset(x: shakeOffset)
        .onChange(of: isHit) { _, hit in
            if hit { playShake() }
        }
    }

    /// 間違い鬼の瀕死(stage 4)用: 小さい体 + 片目1つ + ゆらめき
    @ViewBuilder
    private var weakMistakeOniView: some View {
        WeakMistakeOniInner(
            size: monsterSize,
            isHit: isHit,
            isDefeated: isDefeated
        )
    }

    /// 水彩画像表示時のサイズ（元の monsterSize より大きめに）
    private var monsterImageSize: CGFloat {
        // スライムはプレイヤーと同じサイズ感で表示
        if isSlime {
            if monster.isBoss { return 70 }   // ボススライム
            return 50                          // 通常スライム = プレイヤー(40)と同程度
        }
        if monster.isBoss { return 180 }
        return 130
    }

    private func playShake() {
        // WEB版の anim-shake と同じ: 左右に素早く揺れる
        let sequence: [(CGFloat, Double)] = [
            (-8,  0.00),
            ( 8,  0.06),
            (-6,  0.12),
            ( 6,  0.18),
            (-4,  0.24),
            ( 4,  0.30),
            ( 0,  0.38),
        ]
        for (offset, delay) in sequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }
}

/// 間違い鬼の瀕死(stage 4)専用: 小さい片目+ゆらゆら浮遊
private struct WeakMistakeOniInner: View {
    let size: CGFloat
    let isHit: Bool
    let isDefeated: Bool

    @State private var floatY: CGFloat = 0
    @State private var swayAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 体（卵型、白っぽい）
            Capsule()
                .fill(LinearGradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.92),
                    Color(red: 0.85, green: 0.85, blue: 0.82)
                ], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size * 1.2)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 3)

            // 片目
            ZStack {
                Circle().fill(.white).frame(width: size * 0.4, height: size * 0.4)
                Circle().fill(Color(white: 0.15)).frame(width: size * 0.22, height: size * 0.22)
                Circle().fill(.white.opacity(0.8))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(x: -size * 0.04, y: -size * 0.04)
            }
            .offset(y: -size * 0.1)

            // しょんぼり口
            Capsule()
                .fill(Color(white: 0.3))
                .frame(width: size * 0.15, height: size * 0.04)
                .offset(y: size * 0.2)
        }
        // ゆらゆら浮遊 + 大小ゆらめき
        .scaleEffect(pulseScale)
        .rotationEffect(.degrees(swayAngle))
        .offset(y: floatY + 70)  // プレイヤーと同じ高さに下げる
        .scaleEffect(isHit ? 1.05 : 1.0)
        .scaleEffect(isDefeated ? 0.0 : 1.0)
        .opacity(isDefeated ? 0.0 : 1.0)
        .rotationEffect(.degrees(isDefeated ? 30 : 0))
        .animation(.easeOut(duration: 0.4), value: isDefeated)
        .animation(.easeInOut(duration: 0.1), value: isHit)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                floatY = -8
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                swayAngle = 5
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}
