import SwiftUI

// MARK: - アイドルアニメーション状態
private struct IdleAnimationState {
    var bounceOffset: CGFloat = 0
    var swayAngle: Double     = 0
    var blinkPhase: Bool      = false
    var eyeShiftX: CGFloat    = 0

    // 手足アニメーション
    var leftArmAngle: Double  = 0
    var rightArmAngle: Double = 0
    var leftLegAngle: Double  = 0
    var rightLegAngle: Double = 0

    // B. Squash & Stretch（息してる感）
    var squashY: CGFloat = 1.0    // 胴体の縦伸縮（<1で潰れ、>1で伸び）
    var squashX: CGFloat = 1.0    // 胴体の横伸縮

    // D. 頭と胴体の分離（別周期の揺れ）
    var headSwayAngle: Double = 0  // 頭の独立揺れ

    // 登場演出（playEntrance 時のみ使用、通常は中立値のまま）
    var entranceOpacity: Double   = 1
    var entranceOffsetY: CGFloat  = 0
}

/// 表情オーバーレイ調整用パラメータ
struct MoodOverlayOffsets {
    var blushX: CGFloat = 0.32
    var blushY: CGFloat = -0.34
    var blushSize: CGFloat = 0.14
    var blushOpacity: CGFloat = 0.33
    var smirkX: CGFloat = 0.01
    var smirkY: CGFloat = -0.07
    var smirkW: CGFloat = 0.14
    var smirkH: CGFloat = 0.07
    var squintW: CGFloat = 0.83
    var squintH: CGFloat = 0.04
    var squintSpread: CGFloat = 1.41
    // 寝る表情
    var sleepyW: CGFloat = 0.568
    var sleepyH: CGFloat = 0.015
    var sleepySpread: CGFloat = 3.984
    var surprisedX: CGFloat = 0.25
    var surprisedY: CGFloat = 0.10
    var surprisedScale: CGFloat = 0.25
    // 片目サイズ
    var leftEyeScale: CGFloat = 1.0
    var rightEyeScale: CGFloat = 1.0
}

struct KennyCharacterView: View {
    let appearance: CharacterAppearance
    let size: CGFloat
    var isAttacking: Bool = false
    var isHurt: Bool = false
    var isDefeated: Bool = false
    var playEntrance: Bool = false
    var isJoyPose: Bool = false

    enum Facing { case front, right, left }
    var facing: Facing = .front

    /// タイトル画面用表情（バトル状態が優先）
    enum IdleMood { case normal, smirk, blush, squint, surprised, sleepy }
    var idleMood: IdleMood = .normal

    /// DEBUG 用: 外部から渡すパーツオフセット（nilなら固定値を使用）
    var debugPartOffsets: CharacterPartOffsets? = nil
    /// DEBUG 用: 表情オーバーレイのオフセット
    var debugMoodOffsets: MoodOverlayOffsets? = nil

    @State private var idle = IdleAnimationState()
    @State private var blinkTask: Task<Void, Never>?

    // バトル演出の視覚状態（withAnimation で駆動）
    @State private var attackRotation: Double = 0
    @State private var attackOffsetX: CGFloat = 0
    @State private var attackOffsetY: CGFloat = 0
    @State private var defeatOpacity: Double  = 1.0
    @State private var hurtColor: Color       = .white

    /// オフセット値の基準サイズ（CharacterPartOffsets の値はこのサイズ前提で調整されている）
    private static let referenceSize: CGFloat = 160

    /// bodyに応じたパーツ微調整オフセット（sizeに合わせてスケール済み）
    private var partOffsets: CharacterPartOffsets {
        let raw = debugPartOffsets ?? CharacterPartOffsets.forBody(appearance.body)
        let k = size / Self.referenceSize
        // pt単位のオフセットだけスケール。scale/rotationはそのまま。
        var s = raw
        s.eyes    = CGSize(width: raw.eyes.width    * k, height: raw.eyes.height    * k)
        s.mouth   = CGSize(width: raw.mouth.width   * k, height: raw.mouth.height   * k)
        s.detail  = CGSize(width: raw.detail.width  * k, height: raw.detail.height  * k)
        s.detail2 = CGSize(width: raw.detail2.width * k, height: raw.detail2.height * k)
        s.detail3 = CGSize(width: raw.detail3.width * k, height: raw.detail3.height * k)
        s.detailSpread = raw.detailSpread * k
        s.nose    = CGSize(width: raw.nose.width    * k, height: raw.nose.height    * k)
        s.head    = CGSize(width: raw.head.width    * k, height: raw.head.height    * k)
        s.armOffset = CGSize(width: raw.armOffset.width * k, height: raw.armOffset.height * k)
        s.leftArmOffsetX  = raw.leftArmOffsetX  * k
        s.rightArmOffsetX = raw.rightArmOffsetX * k
        s.legOffset = CGSize(width: raw.legOffset.width * k, height: raw.legOffset.height * k)
        s.legSpread = raw.legSpread * k
        s.eyeSpread = raw.eyeSpread * k
        s.pmouthOffsetX = raw.pmouthOffsetX * k
        s.pmouthOffsetY = raw.pmouthOffsetY * k
        return s
    }

    // MARK: - パーツサイズ
    private var bodyFrame: SpriteFrame? { spriteFrames[appearance.body] }
    private var bodyH: CGFloat {
        guard let bf = bodyFrame else { return size }
        return bf.height * size / bf.width
    }
    private var eyeSize: CGFloat    { size * 0.20 * partOffsets.eyeScale }
    private var mouthSize: CGFloat  { size * 0.24 }
    private var armSize: CGFloat    { size * 0.22 * partOffsets.armScale }
    private var legSize: CGFloat    { size * 0.12 * partOffsets.legScale }
    private var detailSize: CGFloat { size * 0.20 }
    private var noseSize: CGFloat   { size * 0.18 }
    private var headSize: CGFloat   { size * 0.30 * partOffsets.headScale }

    // MARK: - 配置パラメータ（微調整用）
    private let eyeSpread: CGFloat  = 0.25   // 目の左右間隔
    private let armOverlap: CGFloat = 0.10   // 腕の横位置（小=外側に出る）
    private let armYRatio: CGFloat  = 0.55   // 腕の縦位置
    private let legSpread: CGFloat  = 0.55   // 足の左右間隔（大=離れる）
    private let legOverlap: CGFloat = 1.20   // 足の縦位置

    // MARK: - 横ずらし微調整（0=中央）
    private let faceOffsetX: CGFloat = 0     // 顔パーツ全体の横位置
    private let armsOffsetX: CGFloat = 0
    private let legsOffsetX: CGFloat = 0

    // MARK: - 縦ずらし
    private let eyeLiftPx: CGFloat = 6       // 目を上にずらす

    // MARK: - アイドルアニメーション定数
    private let bounceAmplitude: CGFloat = 4.0
    private let bouncePeriod: Double     = 1.2
    private let swayAmplitude: Double    = 2.0
    private let swayPeriod: Double       = 2.5

    // 手足アニメーション定数
    private let armSwingAmplitude: Double = 6.0   // 腕の振り幅（度）
    private let armSwingPeriod: Double    = 1.4   // 腕の周期（秒）
    private let legSwingAmplitude: Double = 4.0   // 足の振り幅（度）
    private let legSwingPeriod: Double    = 1.2   // 足の周期（秒・バウンスに同期）

    private func bodyY(_ ratio: CGFloat) -> CGFloat {
        bodyH * (ratio - 0.5)
    }

    // MARK: - body
    //
    // ── 構造 ──
    // ZStack {                         ← 全パーツ同一コンテナ
    //     armsLayer                    ← 腕（コンテナ内 .offset で相対配置）
    //     SpriteView(body)             ← 体スプライト（中央配置）
    //     faceLayer                    ← 目・口・鼻・ディテール（コンテナ内 .offset で相対配置）
    //     legsLayer                    ← 足（コンテナ内 .offset で相対配置）
    // }
    // .offset(idle.bounceOffset)       ← アイドルバウンス（コンテナ全体）
    // .rotationEffect(idle.swayAngle)  ← アイドルスウェイ（コンテナ全体）
    // .rotationEffect(attackRotation)  ← 攻撃回転（コンテナ全体）
    // .offset(attackOffset)            ← 攻撃移動（コンテナ全体）
    //
    // ★ 個別パーツへの scale / offset / rotation は「コンテナ内の静的位置」のみ。
    //   キャラクターアニメーションは必ずコンテナ全体に適用する。
    //   これにより body / eyes / mouth / detail が常に同一変形を受ける。
    //
    // ★ すべてのアニメーションを withAnimation で駆動する。
    //   .animation(value:) は使わない。
    //   .animation(value:) はサブツリー全体にスコープし、
    //   withAnimation で指定したアイドル用カーブを上書きしてパーツ間ズレの原因になる。

    var body: some View {
        ZStack(alignment: .center) {
            legsLayer
            rightArmLayer          // 右腕: 胴体の後ろ
            joyRightArmLayer       // 喜びポーズ右腕（通常は非表示）
            SpriteView(frameName: appearance.body, displayWidth: size * partOffsets.bodyScale, tintColor: appearance.bodyColor)
                .opacity(bodyFrame != nil || UIImage(named: appearance.body) != nil ? 1 : 0)
            leftArmLayer           // 左腕: 胴体の前
            joyLeftArmLayer        // 喜びポーズ左腕（通常は非表示）
            headLayer
            faceLayer
        }
        .frame(width: size + armSize, height: bodyH + legSize * 0.8)
        .scaleEffect(x: facing == .right ? -1 : 1, y: 1)

        // ── アイドルアニメーション（withAnimation 駆動、コンテナ全体に適用）──
        .scaleEffect(x: idle.squashX, y: idle.squashY, anchor: .bottom)  // B. Squash & Stretch
        .offset(y: idle.bounceOffset)
        .rotationEffect(.degrees(idle.swayAngle), anchor: .bottom)

        // ── バトル演出（withAnimation 駆動、コンテナ全体に適用）──
        // @State 値を onChange + withAnimation で制御。
        // .animation(value:) を使わないことで、アイドル用 withAnimation と
        // バトル用アニメーションカーブが干渉しない。
        .rotationEffect(.degrees(attackRotation), anchor: .bottom)
        .offset(x: attackOffsetX, y: attackOffsetY)
        .opacity(defeatOpacity)
        .colorMultiply(hurtColor)

        // ── 登場演出（playEntrance 時のみ作用、通常は中立値で無影響）──
        .opacity(idle.entranceOpacity)
        .offset(y: idle.entranceOffsetY)
        .onAppear {
            if isAttacking { attackRotation = 12; attackOffsetX = 8; attackOffsetY = -4 }
            if isHurt { hurtColor = Color(red: 1, green: 0.4, blue: 0.4) }
            if isDefeated { defeatOpacity = 0.3 }

            if playEntrance {
                playEntranceAnimation()
            } else {
                startIdleAnimations()
            }
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
            stopIdleAnimations()
        }
        .onChange(of: appearance) { _, _ in
            restartIdleAnimations()
        }
        .onChange(of: idleMood) { _, _ in
            restartIdleAnimations()
        }
        .onChange(of: isAttacking) { _, attacking in
            if attacking {
                suppressIdleForBattle()
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    attackRotation = 12
                    attackOffsetX = 8
                    attackOffsetY = -4
                }
            } else {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    attackRotation = 0
                    attackOffsetX = 0
                    attackOffsetY = 0
                }
                if !isHurt && !isDefeated {
                    restartIdleAnimations()
                }
            }
        }
        .onChange(of: isHurt) { _, hurt in
            if hurt {
                suppressIdleForBattle()
                withAnimation(.easeOut(duration: 0.25)) {
                    hurtColor = Color(red: 1, green: 0.4, blue: 0.4)
                }
            } else {
                withAnimation(.easeOut(duration: 0.25)) {
                    hurtColor = .white
                }
                if !isAttacking && !isDefeated {
                    restartIdleAnimations()
                }
            }
        }
        .onChange(of: isDefeated) { _, defeated in
            if defeated {
                suppressIdleForBattle()
                withAnimation(.easeOut(duration: 0.4)) {
                    defeatOpacity = 0.3
                }
            } else {
                withAnimation(.easeOut(duration: 0.4)) {
                    defeatOpacity = 1.0
                }
                if !isAttacking && !isHurt {
                    restartIdleAnimations()
                }
            }
        }
    }

    // MARK: - 頭レイヤー（1要素）
    // ★ スプライトシートではなく独立画像（Assets.xcassets 直接）。
    //   帽子・頭パーツ等を自由に追加できる。

    @ViewBuilder
    private var headLayer: some View {
        let headName = appearance.head ?? ""
        let visible = appearance.head != nil && !headName.isEmpty
        ZStack {
            // 頭本体（colorMultiplyで色乗算）
            Image(headName)
                .resizable()
                .scaledToFit()
                .frame(width: headSize, height: headSize)
                .colorMultiply(appearance.headTint ?? .white)

            // 白いシャイン（colorMultiplyの影響を受けない）
            Ellipse()
                .fill(Color.white.opacity(partOffsets.shineOpacity))
                .frame(width: headSize * partOffsets.shineW, height: headSize * partOffsets.shineH)
                .rotationEffect(.degrees(partOffsets.shineRotation))
                .offset(x: headSize * partOffsets.shineX, y: headSize * partOffsets.shineY)
        }
        .frame(width: headSize, height: headSize)
        .rotationEffect(.degrees(partOffsets.headRotation + idle.headSwayAngle), anchor: .bottom)
        .offset(
            x: partOffsets.head.width,
            y: -bodyH / 2 - headSize * 0.3 + partOffsets.head.height
        )
        .opacity(visible ? 1 : 0)
    }

    // MARK: - 腕レイヤー（左右分割: 左=胴体の後ろ、右=胴体の前）

    @ViewBuilder
    private var leftArmLayer: some View {
        let armX = size * 0.5 - armSize * armOverlap
        let armYPos = bodyY(armYRatio)
        let leftArm = appearance.leftArm ?? "detail_none"
        SpriteView(frameName: leftArm, displayWidth: armSize, flipped: true, tintColor: appearance.limbTint ?? appearance.bodyColor)
            .rotationEffect(
                .degrees(
                    isAttacking
                        ? idle.leftArmAngle + partOffsets.armRotation + (-90)
                        : idle.leftArmAngle + partOffsets.armRotation + partOffsets.leftArmRotation
                ),
                anchor: .init(x: 0.8, y: 0.15)
            )
            .offset(
                x: -armX + armsOffsetX + partOffsets.armOffset.width + partOffsets.leftArmOffsetX,
                y: armYPos + partOffsets.armOffset.height
            )
            .opacity(appearance.leftArm != nil && !isJoyPose ? 1 : 0)
    }

    @ViewBuilder
    private var rightArmLayer: some View {
        let armX = size * 0.5 - armSize * armOverlap
        let armYPos = bodyY(armYRatio)
        let rightArm = appearance.rightArm ?? "detail_none"
        SpriteView(frameName: rightArm, displayWidth: armSize, tintColor: appearance.limbTint ?? appearance.bodyColor)
            .rotationEffect(
                .degrees(
                    isAttacking
                        ? idle.rightArmAngle + partOffsets.armRotation + (-90)
                        : idle.rightArmAngle + partOffsets.armRotation + partOffsets.rightArmRotation
                ),
                anchor: .init(x: 0.2, y: 0.15)
            )
            .offset(
                x: armX + armsOffsetX + partOffsets.armOffset.width + partOffsets.rightArmOffsetX,
                y: armYPos + partOffsets.armOffset.height
            )
            .opacity(appearance.rightArm != nil && !isJoyPose ? 1 : 0)
    }

    // MARK: - 喜びポーズ腕（普段は非表示）

    @ViewBuilder
    private var joyLeftArmLayer: some View {
        let arm = appearance.rightArm ?? "detail_none"
        SpriteView(frameName: arm, displayWidth: armSize, tintColor: appearance.limbTint ?? appearance.bodyColor)
            .rotationEffect(.degrees(partOffsets.joyLeftArmR + partOffsets.armRotation), anchor: .init(x: 0.8, y: 0.15))
            .offset(
                x: partOffsets.armOffset.width + partOffsets.joyLeftArmX,
                y: partOffsets.armOffset.height + bodyY(armYRatio)
            )
            .opacity(isJoyPose ? 1 : 0)
    }

    @ViewBuilder
    private var joyRightArmLayer: some View {
        let arm = appearance.leftArm ?? "detail_none"
        SpriteView(frameName: arm, displayWidth: armSize, flipped: true, tintColor: appearance.limbTint ?? appearance.bodyColor)
            .rotationEffect(.degrees(partOffsets.joyRightArmR + partOffsets.armRotation), anchor: .init(x: 0.2, y: 0.15))
            .offset(
                x: partOffsets.armOffset.width + partOffsets.joyRightArmX,
                y: partOffsets.armOffset.height + bodyY(armYRatio)
            )
            .opacity(isJoyPose ? 1 : 0)
    }

    // MARK: - 顔レイヤー
    //
    // ★ @ViewBuilder の TupleView は最大 10 要素。超えるとネスト境界で
    //   アニメーションコンテキストの伝播が途切れる。
    //   faceLayer を detailLayer / eyeLayer / noseAndMouthLayer に分割し、
    //   各サブレイヤーを 3〜4 要素に収めることで全パーツに repeatForever が伝播する。

    @ViewBuilder
    private var faceLayer: some View {
        detailLayer
        eyeLayer
        noseAndMouthLayer
        moodOverlayLayer
    }

    // ── ツノ類（3要素）──
    @ViewBuilder
    private var detailLayer: some View {
        let dh = spriteFrameHeight(appearance.detail, displayWidth: detailSize)
        let dh2 = spriteFrameHeight(appearance.detail2, displayWidth: detailSize)
        let dh3 = spriteFrameHeight(appearance.detail3, displayWidth: detailSize)
        SpriteView(frameName: appearance.detail, displayWidth: detailSize, tintColor: appearance.bodyColor)
            .rotationEffect(.degrees(partOffsets.detailRotation))
            .offset(
                x: faceOffsetX + partOffsets.detail.width,
                y: -bodyH / 2 - dh * 0.5 + partOffsets.detail.height
            )
            .opacity(appearance.detail != "detail_none" && (spriteFrames[appearance.detail] != nil || UIImage(named: appearance.detail) != nil) ? 1 : 0)
        SpriteView(frameName: appearance.detail2, displayWidth: detailSize, tintColor: appearance.bodyColor)
            .rotationEffect(.degrees(partOffsets.detail2Rotation))
            .offset(
                x: faceOffsetX + partOffsets.detail2.width - partOffsets.detailSpread,
                y: -bodyH / 2 - dh2 * 0.5 + partOffsets.detail2.height
            )
            .opacity(appearance.detail2 != "detail_none" && (spriteFrames[appearance.detail2] != nil || UIImage(named: appearance.detail2) != nil) ? 1 : 0)
        SpriteView(frameName: appearance.detail3, displayWidth: detailSize, tintColor: appearance.bodyColor)
            .rotationEffect(.degrees(partOffsets.detail3Rotation))
            .offset(
                x: faceOffsetX + partOffsets.detail3.width + partOffsets.detailSpread,
                y: -bodyH / 2 - dh3 * 0.5 + partOffsets.detail3.height
            )
            .opacity(appearance.detail3 != "detail_none" && (spriteFrames[appearance.detail3] != nil || UIImage(named: appearance.detail3) != nil) ? 1 : 0)
    }

    // ── 目（SwiftUI目 + スプライト目）（4要素）──
    @ViewBuilder
    private var eyeLayer: some View {
        let eyeY = bodyY(appearance.eyeOffsetY) - eyeLiftPx
        let eyeVisible = !(idleMood == .squint || idleMood == .sleepy) && !isHurt
        CharacterEyeView(
            style: appearance.eyeStyle ?? .neutral,
            size: eyeSize,
            spread: eyeSize * eyeSpread + partOffsets.eyeSpread * 0.6,
            browMood: appearance.browMood,
            animated: appearance.eyeAnimated,
            isAttacking: isAttacking,
            isHurt: isHurt,
            isDefeated: isDefeated,
            idleBlinking: idle.blinkPhase,
            idleEyeShiftX: idle.eyeShiftX,
            leftEyeScale: (debugMoodOffsets ?? partOffsets.mood).leftEyeScale,
            rightEyeScale: (debugMoodOffsets ?? partOffsets.mood).rightEyeScale
        )
        .offset(
            x: faceOffsetX + partOffsets.eyes.width,
            y: eyeY + partOffsets.eyes.height
        )
        .opacity(appearance.eyeStyle != nil && eyeVisible ? 1 : 0)
        let spriteEyeName = appearance.eyes
        let seh = spriteFrameHeight(spriteEyeName, displayWidth: eyeSize)
        let spriteEyeY = bodyY(appearance.eyeOffsetY) - seh / 2 - eyeLiftPx
        let spriteEyeSpread = eyeSize * eyeSpread + partOffsets.eyeSpread
        let spriteEyeVisible = appearance.eyeStyle == nil && eyeVisible && spriteFrames[spriteEyeName] != nil
        SpriteView(frameName: spriteEyeName, displayWidth: eyeSize, flipped: true)
            .offset(
                x: -spriteEyeSpread + faceOffsetX + partOffsets.eyes.width,
                y: spriteEyeY + partOffsets.eyes.height
            )
            .opacity(spriteEyeVisible ? 1 : 0)
        SpriteView(frameName: spriteEyeName, displayWidth: eyeSize)
            .offset(
                x: spriteEyeSpread + faceOffsetX + partOffsets.eyes.width,
                y: spriteEyeY + partOffsets.eyes.height
            )
            .opacity(spriteEyeVisible ? 1 : 0)

        // 不正解時の驚き目（SlimeView と同じ: 白目+小黒目+ハイライト）
        // ★ 白目どうしが重ならないように、最低でも eyeSize 分の間隔を確保
        let hurtEyeSpread = max(spriteEyeSpread, eyeSize * 0.65)
        hurtSurprisedEye(isLeft: true,
                          x: -hurtEyeSpread + faceOffsetX + partOffsets.eyes.width,
                          y: eyeY + partOffsets.eyes.height)
        hurtSurprisedEye(isLeft: false,
                          x: hurtEyeSpread + faceOffsetX + partOffsets.eyes.width,
                          y: eyeY + partOffsets.eyes.height)
    }

    @ViewBuilder
    private func hurtSurprisedEye(isLeft: Bool, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            // 白目
            Circle().fill(.white)
                .frame(width: eyeSize, height: eyeSize)
            // 黒目（驚き時は小さい）
            Circle().fill(Color(white: 0.15))
                .frame(width: eyeSize * 0.36, height: eyeSize * 0.36)
            // ハイライト
            Circle().fill(.white.opacity(0.85))
                .frame(width: eyeSize * 0.18, height: eyeSize * 0.18)
                .offset(x: -eyeSize * 0.09, y: -eyeSize * 0.09)
        }
        .offset(x: x, y: y)
        .opacity(isHurt ? 1 : 0)
    }

    // ── 鼻・口（2要素）──
    @ViewBuilder
    private var noseAndMouthLayer: some View {
        let noseName = appearance.nose ?? "detail_none"
        let nh = spriteFrameHeight(noseName, displayWidth: noseSize)
        let noseRatio = (appearance.eyeOffsetY + appearance.mouthOffsetY) / 2
        SpriteView(frameName: noseName, displayWidth: noseSize)
            .offset(
                x: faceOffsetX + partOffsets.nose.width,
                y: bodyY(noseRatio) - nh / 2 + partOffsets.nose.height
            )
            .opacity(appearance.nose != nil && spriteFrames[noseName] != nil ? 1 : 0)
        let mh = spriteFrameHeight(appearance.mouth, displayWidth: mouthSize)
        SpriteView(frameName: appearance.mouth, displayWidth: mouthSize)
            .offset(
                x: faceOffsetX + partOffsets.mouth.width,
                y: bodyY(appearance.mouthOffsetY) - mh / 2 + partOffsets.mouth.height
            )
            .opacity(!partOffsets.useProgrammaticMouth && !isHurt && !isJoyPose && spriteFrames[appearance.mouth] != nil && idleMood != .smirk ? 1 : 0)
        // プログラミック口（カーブ可、にっこり笑顔も描ける）
        SmileShape(curve: isJoyPose ? 2.5 : partOffsets.pmouthCurve)
            .stroke(Color(white: 0.2), style: StrokeStyle(lineWidth: max(2, size * (isJoyPose ? 0.08 : partOffsets.pmouthH) * 0.5), lineCap: .round, lineJoin: .round))
            .frame(width: size * (isJoyPose ? 0.22 : partOffsets.pmouthW), height: size * (isJoyPose ? 0.08 : partOffsets.pmouthH))
            .offset(
                x: faceOffsetX + partOffsets.mouth.width + partOffsets.pmouthOffsetX,
                y: bodyY(appearance.mouthOffsetY) + partOffsets.mouth.height + partOffsets.pmouthOffsetY
            )
            .opacity(partOffsets.useProgrammaticMouth && !isHurt && idleMood != .smirk ? 1 : 0)
        // 喜びポーズ時のスプライト口（useProgrammaticMouth=falseのボディ用）
        SmileShape(curve: 2.5)
            .stroke(Color(white: 0.2), style: StrokeStyle(lineWidth: max(2, size * 0.08 * 0.5), lineCap: .round, lineJoin: .round))
            .frame(width: size * 0.22, height: size * 0.08)
            .offset(
                x: faceOffsetX + partOffsets.mouth.width,
                y: bodyY(appearance.mouthOffsetY) + partOffsets.mouth.height
            )
            .opacity(isJoyPose && !partOffsets.useProgrammaticMouth ? 1 : 0)
        // 不正解時の驚いた口（小さな丸）
        Circle()
            .fill(Color(white: 0.2))
            .frame(width: size * 0.10, height: size * 0.10)
            .offset(
                x: faceOffsetX + partOffsets.mouth.width + partOffsets.pmouthOffsetX,
                y: bodyY(appearance.mouthOffsetY) + partOffsets.mouth.height + partOffsets.pmouthOffsetY
            )
            .opacity(isHurt ? 1 : 0)
    }

    /// spriteFrames から安全に高さを計算（フレームが無い場合は 0）
    private func spriteFrameHeight(_ name: String, displayWidth: CGFloat) -> CGFloat {
        guard let f = spriteFrames[name] else { return 0 }
        return f.height * displayWidth / f.width
    }

    // MARK: - 表情オーバーレイ（idleMood用・常在ビュー）

    private var moodVisible: Bool {
        !isAttacking && !isHurt && !isDefeated && idleMood != .normal
    }

    @ViewBuilder
    private var moodOverlayLayer: some View {
        let m = debugMoodOffsets ?? partOffsets.mood
        let eyeY = bodyY(appearance.eyeOffsetY) - eyeLiftPx
        let mouthY = bodyY(appearance.mouthOffsetY)
        let showBlush = moodVisible && (idleMood == .blush || idleMood == .smirk)
        let showSmirk = moodVisible && idleMood == .smirk
        let showSquint = moodVisible && idleMood == .squint
        let showSleepy = moodVisible && idleMood == .sleepy
        let showSurprised = moodVisible && idleMood == .surprised
        let spread = eyeSize * eyeSpread + partOffsets.eyeSpread * 0.6

        // ほっぺ赤 左（てれ/ニヤッ共通）
        Circle()
            .fill(Color.pink)
            .frame(width: size * m.blushSize, height: size * m.blushSize * 0.7)
            .blur(radius: 2)
            .offset(x: -size * m.blushX + faceOffsetX, y: eyeY + size * m.blushY)
            .opacity(showBlush ? 1 : 0)

        // ほっぺ赤 右
        Circle()
            .fill(Color.pink)
            .frame(width: size * m.blushSize, height: size * m.blushSize * 0.7)
            .blur(radius: 2)
            .offset(x: size * m.blushX + faceOffsetX, y: eyeY + size * m.blushY)
            .opacity(showBlush ? 1 : 0)

        // ニヤッ口
        SmirkShape()
            .stroke(Color.black.opacity(0.6), lineWidth: 1.5)
            .frame(width: size * m.smirkW, height: size * m.smirkH)
            .offset(x: faceOffsetX + partOffsets.mouth.width + size * m.smirkX, y: mouthY + size * m.smirkY)
            .opacity(showSmirk ? 1 : 0)

        // ジト目 左
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.black)
            .frame(width: eyeSize * m.squintW, height: size * m.squintH)
            .offset(x: -spread * m.squintSpread + faceOffsetX + partOffsets.eyes.width, y: eyeY + partOffsets.eyes.height)
            .opacity(showSquint ? 1 : 0)

        // ジト目 右
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.black)
            .frame(width: eyeSize * m.squintW, height: size * m.squintH)
            .offset(x: spread * m.squintSpread + faceOffsetX + partOffsets.eyes.width, y: eyeY + partOffsets.eyes.height)
            .opacity(showSquint ? 1 : 0)

        // びっくり
        Text("!")
            .font(.system(size: size * m.surprisedScale, weight: .black, design: .rounded))
            .foregroundStyle(.yellow)
            .shadow(color: .black.opacity(0.3), radius: 2)
            .offset(x: size * m.surprisedX, y: -bodyH / 2 - size * m.surprisedY)
            .opacity(showSurprised ? 1 : 0)

        // 寝る（ジト目と同じ描画）左
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.black)
            .frame(width: eyeSize * m.squintW, height: size * m.squintH)
            .offset(x: -spread * m.squintSpread + faceOffsetX + partOffsets.eyes.width, y: eyeY + partOffsets.eyes.height)
            .opacity(showSleepy ? 1 : 0)

        // 寝る 右
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.black)
            .frame(width: eyeSize * m.squintW, height: size * m.squintH)
            .offset(x: spread * m.squintSpread + faceOffsetX + partOffsets.eyes.width, y: eyeY + partOffsets.eyes.height)
            .opacity(showSleepy ? 1 : 0)
    }

    // ニヤッ口シェイプ
    private struct SmirkShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.5)
            )
            return path
        }
    }

    /// 笑顔のカーブ口（curve=0で直線、+で笑顔、-で悲しみ）
    private struct SmileShape: Shape {
        let curve: CGFloat
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            // curve > 0: 下に膨らむ（笑顔）。control の y を midY より下に。
            let controlY = rect.midY + rect.height * curve
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.midY),
                control: CGPoint(x: rect.midX, y: controlY)
            )
            return p
        }
    }

    // MARK: - 足レイヤー

    @ViewBuilder
    private var legsLayer: some View {
        let legs = appearance.legs ?? "detail_none"
        let hasLegs = appearance.legs != nil && (spriteFrames[legs] != nil || UIImage(named: legs) != nil)
        let legH = spriteFrameHeight(legs, displayWidth: legSize)
        let legY = bodyY(1.0) - legH * (0.5 - legOverlap)
        let spread = legSize * legSpread + partOffsets.legSpread

        SpriteView(frameName: legs, displayWidth: legSize, flipped: true, tintColor: appearance.limbTint ?? appearance.bodyColor)
            .rotationEffect(
                .degrees(idle.leftLegAngle + partOffsets.legRotation),
                anchor: .init(x: 0.5, y: 0.1)
            )
            .offset(
                x: -spread + legsOffsetX + partOffsets.legOffset.width,
                y: legY + partOffsets.legOffset.height
            )
            .opacity(hasLegs ? 1 : 0)
        SpriteView(frameName: legs, displayWidth: legSize, tintColor: appearance.limbTint ?? appearance.bodyColor)
            .rotationEffect(
                .degrees(idle.rightLegAngle + partOffsets.legRotation),
                anchor: .init(x: 0.5, y: 0.1)
            )
            .offset(
                x: spread + legsOffsetX + partOffsets.legOffset.width,
                y: legY + partOffsets.legOffset.height
            )
            .opacity(hasLegs ? 1 : 0)
    }

    // MARK: - バトル演出突入時にアイドルモーションを停止
    //
    // アイドル @State 値を 0 にリセットする。
    // バトル演出の視覚状態（attackRotation 等）は onChange 側で withAnimation 制御。
    // .animation(value:) を一切使わないため、カーブ干渉が起きない。

    private func suppressIdleForBattle() {
        withAnimation(.easeOut(duration: 0.12)) {
            idle.bounceOffset  = 0
            idle.swayAngle     = 0
            idle.leftArmAngle  = 0
            idle.rightArmAngle = 0
            idle.leftLegAngle  = 0
            idle.rightLegAngle = 0
            idle.headSwayAngle = 0
            idle.squashX       = 1.0
            idle.squashY       = 1.0
        }
    }

    private func restartIdleAnimations() {
        // suppressIdleForBattle の withAnimation が残った状態で
        // 新しい repeatForever を始めると SwiftUI が無視することがある。
        // Transaction.disablesAnimations で既存アニメーションを強制クリアし、
        // 非ゼロ値にリセットしてから再起動する。
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            idle.bounceOffset  = 0.01
            idle.swayAngle     = 0.01
            idle.leftArmAngle  = 0.01
            idle.rightArmAngle = 0.01
            idle.leftLegAngle  = 0.01
            idle.rightLegAngle = 0.01
            idle.headSwayAngle = 0.01
            idle.squashX       = 1.0
            idle.squashY       = 1.0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            startIdleAnimations()
        }
    }

    // MARK: - 登場演出（リザルト画面用）

    private func playEntranceAnimation() {
        // 初期状態: 少し下に隠れた状態（サイズ・回転は固定）
        idle.entranceOpacity = 0
        idle.entranceOffsetY = 25

        Task { @MainActor in
            // ① 登場: 下からスッと現れる
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.easeOut(duration: 0.3)) {
                idle.entranceOpacity = 1
                idle.entranceOffsetY = 0
            }

            // ② 両腕を外側に開いて「やったー！」ポーズ + 軽くジャンプ
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                idle.leftArmAngle  =  12   // 正=左外側へ開く
                idle.rightArmAngle = -12   // 負=右外側へ開く
                idle.leftLegAngle  =   4
                idle.rightLegAngle =  -4
                idle.bounceOffset  =  -6
            }

            // ③ 着地してポーズを見せる
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                idle.bounceOffset  = 0
                idle.leftLegAngle  = 0
                idle.rightLegAngle = 0
            }

            // ④ ポーズをキープ
            try? await Task.sleep(for: .milliseconds(400))

            // ⑤ 腕を下ろしてリザルト用アイドルへ
            withAnimation(.easeOut(duration: 0.3)) {
                idle.leftArmAngle  = 0
                idle.rightArmAngle = 0
            }
            try? await Task.sleep(for: .milliseconds(300))
            startResultIdleAnimations()
        }
    }

    /// リザルト画面用アイドルモーション（うれしそうに手を外側に振るループ）
    private func startResultIdleAnimations() {
        // body: うれしそうに弾む上下動
        withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
            idle.bounceOffset = -3.0
        }
        // sway: 微小な揺れ
        withAnimation(.easeInOut(duration: 1.4).delay(0.2).repeatForever(autoreverses: true)) {
            idle.swayAngle = 1.5
        }

        // arms: 外側方向へ交互に振る（正=左外, 負=右外）
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            idle.leftArmAngle = 10
        }
        withAnimation(.easeInOut(duration: 0.8).delay(0.4).repeatForever(autoreverses: true)) {
            idle.rightArmAngle = -10
        }

        // legs: 交互にぴこぴこ
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            idle.leftLegAngle = 3.5
        }
        withAnimation(.easeInOut(duration: 0.6).delay(0.3).repeatForever(autoreverses: true)) {
            idle.rightLegAngle = -3.5
        }

        startBlinkLoop()
    }

    private func startIdleAnimations() {
        guard !isDefeated else { return }

        // スリープ中は動きを極小に（呼吸だけ残す）
        let isSleeping = (idleMood == .sleepy)
        let ampK: CGFloat = isSleeping ? 0.15 : 1.0     // 振幅係数（スリープ時15%）
        let dampAmpK: Double = isSleeping ? 0.15 : 1.0
        let slowK: Double = isSleeping ? 2.5 : 1.0      // 周期係数（スリープ時2.5倍ゆっくり）

        // A. スプリング物理: バウンス
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 40, damping: isSleeping ? 10 : 6).repeatForever(autoreverses: true)) {
            idle.bounceOffset = -bounceAmplitude * ampK
        }

        // 全体のスウェイ
        idle.swayAngle = -swayAmplitude * dampAmpK
        withAnimation(.easeInOut(duration: (swayPeriod * slowK) / 2).delay(swayPeriod * 0.15).repeatForever(autoreverses: true)) {
            idle.swayAngle = swayAmplitude * dampAmpK
        }

        // B. Squash & Stretch: 呼吸感（スリープ時は残す。穏やかな胸の動き）
        let squashRange: CGFloat = isSleeping ? 0.015 : 0.03
        withAnimation(.easeInOut(duration: isSleeping ? 3.0 : 1.6).repeatForever(autoreverses: true)) {
            idle.squashY = 1.0 + squashRange
            idle.squashX = 1.0 - squashRange
        }

        // D. 頭の独立揺れ
        idle.headSwayAngle = -5.0 * dampAmpK
        withAnimation(.easeInOut(duration: (1.8 * slowK) / 2).delay(0.35).repeatForever(autoreverses: true)) {
            idle.headSwayAngle = 2.0 * dampAmpK
        }

        // 腕・足はスリープ中は停止
        if !isSleeping {
            withAnimation(.interpolatingSpring(mass: 1, stiffness: 60, damping: 7).repeatForever(autoreverses: true)) {
                idle.leftArmAngle = armSwingAmplitude
            }
            withAnimation(.interpolatingSpring(mass: 1, stiffness: 60, damping: 7).delay(armSwingPeriod * 0.35).repeatForever(autoreverses: true)) {
                idle.rightArmAngle = -armSwingAmplitude
            }
            withAnimation(.easeInOut(duration: legSwingPeriod / 2).repeatForever(autoreverses: true)) {
                idle.leftLegAngle = legSwingAmplitude
            }
            withAnimation(.easeInOut(duration: legSwingPeriod / 2).delay(legSwingPeriod * 0.4).repeatForever(autoreverses: true)) {
                idle.rightLegAngle = -legSwingAmplitude
            }
        } else {
            // スリープ中は腕足を中立位置で固定
            idle.leftArmAngle = 0
            idle.rightArmAngle = 0
            idle.leftLegAngle = 0
            idle.rightLegAngle = 0
        }

        startBlinkLoop()
    }

    private static func ts() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"; return f.string(from: Date())
    }

    private func stopIdleAnimations() {
        blinkTask?.cancel()
        blinkTask = nil
        idle.bounceOffset  = 0
        idle.swayAngle     = 0
        idle.blinkPhase    = false
        idle.eyeShiftX     = 0
        idle.leftArmAngle  = 0
        idle.rightArmAngle = 0
        idle.leftLegAngle  = 0
        idle.rightLegAngle = 0
        idle.squashX       = 1.0
        idle.squashY       = 1.0
        idle.headSwayAngle = 0
    }

    private func startBlinkLoop() {
        guard appearance.eyeAnimated else { return }
        blinkTask?.cancel()
        blinkTask = Task { @MainActor in
            while !Task.isCancelled {
                let interval = Double.random(in: 3.0...6.0)
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { return }
                guard !isDefeated else { return }
                withAnimation(.easeIn(duration: 0.06)) { idle.blinkPhase = true }
                try? await Task.sleep(for: .milliseconds(80))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.10)) { idle.blinkPhase = false }
                if Bool.random() && Bool.random() {
                    try? await Task.sleep(for: .milliseconds(200))
                    guard !Task.isCancelled else { return }
                    await doEyeShift()
                }
            }
        }
    }

    private func doEyeShift() async {
        let shiftAmount: CGFloat = Bool.random() ? 3.0 : -3.0
        withAnimation(.easeOut(duration: 0.15)) { idle.eyeShiftX = shiftAmount }
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.easeIn(duration: 0.15)) { idle.eyeShiftX = 0 }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 24) {
            Text("カズ（アイドル）").foregroundColor(.white)
            KennyCharacterView(appearance: .kazu, size: 100)
            HStack(spacing: 16) {
                ForEach([1, 5, 10, 20, 30], id: \.self) { floor in
                    VStack {
                        KennyCharacterView(appearance: .forFloor(floor), size: 70)
                        Text("\(floor)F").font(.caption2).foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
