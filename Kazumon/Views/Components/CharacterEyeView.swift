import SwiftUI

// MARK: - 目のスタイル定義
enum EyeStyle: Equatable {
    case friendly           // カズ用: 丸い白目＋大きめ黒目
    case angry              // 敵ボス用: つり目＋怒りまゆ
    case neutral            // 一般敵用: 普通の白目＋黒目＋まゆ
    case cute               // スライム用: 大きい丸目
    case psycho             // サイコ: 小さい瞳＋赤い瞳
    case dead               // やられ: ×目
    case closed             // 閉じ目: 線だけ
    case red                // 赤目: つり目＋赤い瞳
}

// MARK: - まゆの表情
enum BrowMood: Equatable {
    case normal             // 水平
    case angry              // 内側が下がる（ハの字逆）
    case sad                // 外側が下がる（ハの字）
    case surprised          // 上に上がる
    case determined         // カズ攻撃時: きりっと
}

// MARK: - SwiftUIで描画する目View
struct CharacterEyeView: View {
    let style: EyeStyle
    let size: CGFloat               // 片目のサイズ
    let spread: CGFloat             // 左右の間隔
    var browMood: BrowMood = .normal
    var animated: Bool = true       // キョロキョロアニメ有効

    // ゲーム状態に連動
    var isAttacking: Bool = false
    var isHurt: Bool = false
    var isDefeated: Bool = false

    // ── アイドル追加パラメータ（KennyCharacterViewから受け取る）──
    var idleBlinking: Bool     = false  // ★ まばたき中フラグ
    var idleEyeShiftX: CGFloat = 0     // ★ キョロキョロ横移動(px)
    var leftEyeScale: CGFloat  = 1.0   // 左目の大きさ倍率
    var rightEyeScale: CGFloat = 1.0   // 右目の大きさ倍率

    // MARK: - 状態に応じた実効まゆ
    private var effectiveBrowMood: BrowMood {
        if isDefeated { return .sad }
        if isHurt { return .surprised }
        if isAttacking {
            switch style {
            case .friendly: return .determined
            case .angry, .neutral, .red, .psycho: return .angry
            case .cute, .dead, .closed: return .normal
            }
        }
        return browMood
    }

    // MARK: - 白目の縦つぶし（まばたき統合）
    // isHurt/isDefeated/idleBlinking をすべてここで解決
    private var eyeSquash: CGFloat {
        if isDefeated    { return 0.5  }  // 目を細める
        if isHurt        { return 0.65 }  // 少しつぶれる
        if idleBlinking  { return 0.05 }  // ★ アイドルまばたき（ほぼ閉じる）
        return 1.0
    }

    // MARK: - 状態に応じてまゆを表示するか
    private var effectiveShowsBrow: Bool {
        if style == .friendly { return isAttacking }
        switch style {
        case .angry, .neutral, .red, .psycho: return true
        case .cute, .dead, .closed: return false
        default: return false
        }
    }

    var body: some View {
        HStack(spacing: spread) {
            singleEye(isLeft: true)
            singleEye(isLeft: false)
        }
        // ★ アニメーションは親（KennyCharacterView）の withAnimation に完全委譲。
        //   ここに .animation(value:) を置くと、親のコンテナ変形（バウンス・スウェイ）を
        //   別カーブで補間してしまい、目と体がズレる原因になる。
    }

    // MARK: - 片目
    //
    // ★ まゆ・白目・黒目は常に3つともビューツリーに存在させる。
    //   `if effectiveShowsBrow` で条件挿入すると、SwiftUI が
    //   .transition(.opacity) をアクティブなアニメーション（バウンス等）に
    //   乗せてしまい、まゆだけ別タイミングで動く原因になる。
    //   表示/非表示は .opacity() のみで制御し、ビュー階層は固定する。
    /// isHurt 時に×目を表示するか（dead/closed スタイルは常にそのまま）
    private var showHurtDeadEye: Bool {
        isHurt && style != .dead && style != .closed
    }

    @ViewBuilder
    private func singleEye(isLeft: Bool) -> some View {
        ZStack {
            // まゆ（常にビューツリーに存在、表示は opacity で制御）
            browShape(isLeft: isLeft)
                .offset(y: browYOffset)
                .opacity(effectiveShowsBrow ? 1 : 0)

            if style == .dead {
                // ×目
                deadEye
                    .scaleEffect(x: 1.0, y: eyeSquash)
            } else if style == .closed {
                // 閉じ目（線）
                closedEye
                    .scaleEffect(x: 1.0, y: eyeSquash)
            } else {
                // 白目（eyeSquash にまばたきを統合済み）
                eyeWhite
                    .scaleEffect(x: 1.0, y: eyeSquash)
                    .opacity(showHurtDeadEye ? 0 : 1)

                // 黒目（瞳）
                pupil
                    .offset(x: idleEyeShiftX, y: 0)
                    .scaleEffect(x: 1.0, y: eyeSquash)
                    .opacity(showHurtDeadEye ? 0 : 1)

                // ダメージ時の×目（常にツリーに存在、opacity で切り替え）
                deadEye
                    .opacity(showHurtDeadEye ? 1 : 0)
            }
        }
        .frame(width: size, height: size * eyeHeightRatio)
        .scaleEffect(isLeft ? leftEyeScale : rightEyeScale)
    }

    // MARK: - 白目
    //
    // ★ switch/case で分岐しない。
    //   @ViewBuilder の switch は case ごとに別ビューIDを持ち、
    //   スタイル切り替え時にビュー挿入/削除が発生する。
    //   これにより親の repeatForever アニメーションとの関連が切れ、
    //   白目だけバウンスしなくなる。
    //   全スタイルを単一の Ellipse + パラメータ差分で描画することで
    //   ビューツリー構造を固定する。
    private var eyeWhite: some View {
        Ellipse()
            .fill(.white)
            .frame(width: size, height: size * eyeHeightRatio)
            .overlay(
                Ellipse()
                    .stroke(
                        Color.black.opacity(style == .angry || style == .red ? 0.15 : 0.1),
                        lineWidth: 1
                    )
            )
    }

    // MARK: - 黒目（瞳）
    @ViewBuilder
    private var pupil: some View {
        let pupilSize = size * pupilRatio
        ZStack {
            Circle()
                .fill(pupilColor)
                .frame(width: pupilSize, height: pupilSize)

            if style == .psycho {
                // サイコ目: 小さい白点を中央に
                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: pupilSize * 0.2, height: pupilSize * 0.2)
            } else {
                Circle()
                    .fill(.white.opacity(0.85))
                    .frame(width: pupilSize * 0.3, height: pupilSize * 0.3)
                    .offset(x: -pupilSize * 0.15, y: -pupilSize * 0.15)
            }
        }
    }

    private var pupilColor: Color {
        switch style {
        case .psycho: return Color(red: 0.7, green: 0.1, blue: 0.1)
        case .red:    return Color(red: 0.6, green: 0.05, blue: 0.05)
        default:      return Color(red: 0.15, green: 0.12, blue: 0.1)
        }
    }

    // MARK: - ×目（dead）
    @ViewBuilder
    private var deadEye: some View {
        let lineSize = size * 0.6
        ZStack {
            Rectangle()
                .fill(Color(red: 0.2, green: 0.15, blue: 0.12))
                .frame(width: lineSize, height: size * 0.12)
                .rotationEffect(.degrees(45))
            Rectangle()
                .fill(Color(red: 0.2, green: 0.15, blue: 0.12))
                .frame(width: lineSize, height: size * 0.12)
                .rotationEffect(.degrees(-45))
        }
    }

    // MARK: - 閉じ目（closed）
    private var closedEye: some View {
        Capsule()
            .fill(Color(red: 0.2, green: 0.15, blue: 0.12))
            .frame(width: size * 0.7, height: size * 0.1)
    }

    // MARK: - まゆ
    @ViewBuilder
    private func browShape(isLeft: Bool) -> some View {
        let browWidth  = size * browWidthRatio
        let browHeight = size * browThickness
        let rotation   = browAngle(isLeft: isLeft)

        RoundedRectangle(cornerRadius: browHeight / 2)
            .fill(browColor)
            .frame(width: browWidth, height: browHeight)
            .rotationEffect(
                .degrees(rotation),
                anchor: isLeft ? .trailing : .leading
            )
    }

    // MARK: - まゆの角度
    private func browAngle(isLeft: Bool) -> Double {
        let base: Double
        switch effectiveBrowMood {
        case .normal:      base = 0
        case .angry:       base = 18
        case .sad:         base = -15
        case .surprised:   base = -8
        case .determined:  base = 10
        }
        return isLeft ? base : -base
    }

    // MARK: - まゆのY位置
    private var browYOffset: CGFloat {
        switch effectiveBrowMood {
        case .surprised:  return -size * 0.58
        case .determined: return -size * 0.52
        default:          return -size * 0.48
        }
    }

    // MARK: - まゆの太さ
    private var browThickness: CGFloat {
        switch effectiveBrowMood {
        case .angry:      return 0.15
        case .determined: return 0.13
        default:          return 0.12
        }
    }

    // MARK: - まゆの幅
    private var browWidthRatio: CGFloat {
        switch effectiveBrowMood {
        case .angry:      return 0.75
        case .determined: return 0.65
        default:          return 0.70
        }
    }

    // MARK: - まゆの色
    private var browColor: Color {
        switch style {
        case .friendly:       return Color(red: 0.2, green: 0.35, blue: 0.6)
        case .angry:          return Color(red: 0.3, green: 0.15, blue: 0.12)
        case .neutral:        return Color(red: 0.25, green: 0.2, blue: 0.18)
        case .cute:           return Color(red: 0.2, green: 0.3, blue: 0.2)
        case .psycho:         return Color(red: 0.35, green: 0.1, blue: 0.1)
        case .red:            return Color(red: 0.4, green: 0.1, blue: 0.08)
        case .dead, .closed:  return Color(red: 0.25, green: 0.2, blue: 0.18)
        }
    }

    // MARK: - スタイル別パラメータ
    private var pupilRatio: CGFloat {
        switch style {
        case .friendly:       return 0.55
        case .angry:          return 0.45
        case .neutral:        return 0.50
        case .cute:           return 0.60
        case .psycho:         return 0.35
        case .red:            return 0.45
        case .dead, .closed:  return 0.40
        }
    }

    private var eyeHeightRatio: CGFloat {
        switch style {
        case .friendly:       return 1.1
        case .angry, .red:    return 0.75
        case .neutral:        return 0.95
        case .cute:           return 1.0
        case .psycho:         return 0.90
        case .dead, .closed:  return 0.80
        }
    }

}

// MARK: - プレビュー
#Preview {
    VStack(spacing: 40) {
        Text("カズ（friendly）").font(.caption)
        HStack(spacing: 24) {
            VStack {
                CharacterEyeView(style: .friendly, size: 28, spread: 8)
                Text("通常").font(.caption2)
            }
            VStack {
                CharacterEyeView(style: .friendly, size: 28, spread: 8,
                                 isAttacking: true)
                Text("攻撃").font(.caption2)
            }
            VStack {
                CharacterEyeView(style: .friendly, size: 28, spread: 8,
                                 isHurt: true)
                Text("ダメージ").font(.caption2)
            }
            VStack {
                CharacterEyeView(style: .friendly, size: 28, spread: 8,
                                 isDefeated: true)
                Text("やられた").font(.caption2)
            }
            // ★ まばたきプレビュー
            VStack {
                CharacterEyeView(style: .friendly, size: 28, spread: 8,
                                 idleBlinking: true)
                Text("まばたき").font(.caption2)
            }
        }

        Text("敵（angry）").font(.caption)
        HStack(spacing: 24) {
            VStack {
                CharacterEyeView(style: .angry, size: 28, spread: 6, browMood: .angry)
                Text("通常").font(.caption2)
            }
            VStack {
                CharacterEyeView(style: .angry, size: 28, spread: 6,
                                 browMood: .angry, isHurt: true)
                Text("ダメージ").font(.caption2)
            }
            VStack {
                CharacterEyeView(style: .angry, size: 28, spread: 6,
                                 browMood: .angry, isDefeated: true)
                Text("やられた").font(.caption2)
            }
        }

        Text("一般敵（neutral）").font(.caption)
        HStack(spacing: 24) {
            VStack {
                CharacterEyeView(style: .neutral, size: 28, spread: 8, browMood: .normal)
                Text("通常").font(.caption2)
            }
            VStack {
                CharacterEyeView(style: .neutral, size: 28, spread: 8,
                                 browMood: .normal, isAttacking: true)
                Text("攻撃").font(.caption2)
            }
            VStack {
                CharacterEyeView(style: .neutral, size: 28, spread: 8,
                                 browMood: .normal, isDefeated: true)
                Text("やられた").font(.caption2)
            }
        }
    }
    .padding()
}
