import CoreGraphics
import SwiftUI

// MARK: - bodyごとのパーツ位置微調整
//
// KennyCharacterView の共通配置ロジック（eyeOffsetY / mouthOffsetY / bodyY()）
// だけでは吸収しきれない、body スプライトごとの微調整値を保持する。
//
// 値は CGSize（width = X方向, height = Y方向）。
// 正の値は右/下、負の値は左/上。単位は pt。
//
// 腕・足のサイズ比率（armScale / legScale）は 1.0 が等倍。
// 腕・足の回転（armRotation / legRotation）は度単位。正=時計回り。

struct CharacterPartOffsets {
    var bodyScale:      CGFloat = 1.0     // ボディのサイズ倍率
    var eyes:           CGSize  = .zero
    var eyeScale:       CGFloat = 1.0     // 目のサイズ倍率
    var eyeSpread:      CGFloat = 0       // 目の左右間隔オフセット（pt、正=広がる）
    var mouth:          CGSize  = .zero
    var detail:         CGSize  = .zero
    var detailRotation: CGFloat = 0      // detail パーツの回転角度（度）
    var detail2:        CGSize  = .zero   // 2つ目のツノ位置
    var detail2Rotation: CGFloat = 0
    var detail3:        CGSize  = .zero   // 3つ目のツノ位置
    var detail3Rotation: CGFloat = 0
    var detailSpread:   CGFloat = 0       // ツノ間の左右距離（pt）
    var nose:           CGSize  = .zero

    // 頭
    var head:           CGSize  = .zero   // 頭パーツの位置オフセット（X/Y）
    var headScale:      CGFloat = 1.0     // 頭パーツのサイズ倍率
    var headRotation:   CGFloat = 0       // 頭パーツの回転角度（度）

    // 頭のシャイン（白い反射）
    var shineX:         CGFloat = -0.18    // 頭サイズに対する比率
    var shineY:         CGFloat = -0.05
    var shineW:         CGFloat = 0.08
    var shineH:         CGFloat = 0.18
    var shineRotation:  CGFloat = -30
    var shineOpacity:   CGFloat = 0.9

    // 腕
    var armOffset:          CGSize  = .zero  // 腕の位置オフセット（X/Y）
    var armScale:           CGFloat = 1.0    // 腕のサイズ倍率
    var armRotation:        CGFloat = 0      // 腕の静止角度オフセット（左右共通・度）
    var leftArmRotation:    CGFloat = 0      // 左腕専用の追加角度（度）
    var rightArmRotation:   CGFloat = 0      // 右腕専用の追加角度（度）
    var leftArmOffsetX:     CGFloat = 0      // 左腕専用X位置オフセット
    var rightArmOffsetX:    CGFloat = 0      // 右腕専用X位置オフセット

    // 喜びポーズ腕
    var joyLeftArmX:        CGFloat = -65
    var joyLeftArmY:        CGFloat = 0
    var joyLeftArmR:        CGFloat = -170
    var joyRightArmX:       CGFloat = 63
    var joyRightArmY:       CGFloat = 0
    var joyRightArmR:       CGFloat = 170

    // 足
    var legOffset:      CGSize  = .zero  // 足の位置オフセット（X/Y）
    var legScale:       CGFloat = 1.0    // 足のサイズ倍率
    var legRotation:    CGFloat = 0      // 足の静止角度オフセット（度）
    var legSpread:      CGFloat = 0      // 足の左右幅オフセット（pt、正=広がる）

    // 表情オーバーレイ（body別の表情パラメータ）
    var mood: MoodOverlayOffsets = MoodOverlayOffsets()

    // プログラミック口（スプライト口の代わりにCapsuleで描画）
    var useProgrammaticMouth: Bool = false
    var pmouthW: CGFloat = 0.15      // 口の幅（bodyサイズ比）
    var pmouthH: CGFloat = 0.06      // 口の高さ（bodyサイズ比）
    var pmouthOffsetX: CGFloat = 0   // 口の追加X位置オフセット（pt）
    var pmouthOffsetY: CGFloat = 0   // 口の追加Y位置オフセット（pt）
    var pmouthCurve:   CGFloat = 0   // 口のカーブ(にっこり度): 0=直線、+で笑顔カーブ

    // 左向き時のオフセット（nilなら正面値を使用）
    var leftEyeOffsetX:     CGFloat? = nil
    var leftEyeOffsetY:     CGFloat? = nil
    var leftEyeSpread:      CGFloat? = nil
    var leftEyeScaleL:      CGFloat? = nil
    var leftEyeScaleR:      CGFloat? = nil
    var leftMouthOffsetX:   CGFloat? = nil
    var leftMouthOffsetY:   CGFloat? = nil

    // 登場アニメ用（デバッグで調整）
    var legSkew: CGFloat = 0           // 足のシアー変形量（左は負、右は正で外向き）
    var entranceLegSpread: CGFloat = 0 // 登場時の足の追加開き
    var entranceBodyScaleX: CGFloat = 1.0
    var entranceBodyScaleY: CGFloat = 1.0
    var entranceArmRotation: CGFloat = 0

    // MARK: - bodyごとの固定値

    static func forBody(_ bodyName: String) -> CharacterPartOffsets {
        if let direct = registry[bodyName] { return direct }
        let base = bodyName.replacingOccurrences(of: "body_base_", with: "body_blue")
        if let fallback = registry[base] { return fallback }
        return CharacterPartOffsets()
    }

    static func isRegistered(_ bodyName: String) -> Bool {
        registry[bodyName] != nil
    }

    private static let registry: [String: CharacterPartOffsets] = [
        // ── 主人公（進化別）──
        "body_blueB": CharacterPartOffsets(
            eyes:            CGSize(width: 10, height: 26),
            eyeScale:        1.20,
            eyeSpread:       -1,
            mouth:           CGSize(width: 7, height: 14),
            detail:          CGSize(width: -2, height: 20),
            detailRotation:  -50,
            detail2:         CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:         CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:            CGSize(width: 0, height: 0),
            head:            CGSize(width: -67, height: 1),
            headScale:       2.10,
            headRotation:    0,
            shineX:          -0.13,
            shineY:          -0.17,
            shineW:          0.08,
            shineH:          0.20,
            shineRotation:   35,
            shineOpacity:    0,
            armOffset:       CGSize(width: 0, height: 34),
            armScale:        1.30,
            armRotation:     20,
            leftArmRotation:  0,
            rightArmRotation: 0,
            leftArmOffsetX:   0,
            rightArmOffsetX:  0,
            joyLeftArmX: -60, joyLeftArmY: 5, joyLeftArmR: -255,
            joyRightArmX: 63, joyRightArmY: 5, joyRightArmR: 210,
            legOffset:       CGSize(width: -2, height: -13),
            legScale:        2.60,
            legRotation:     0,
            legSpread:       -5,
            mood: MoodOverlayOffsets(
                blushX: 0.371, blushY: 0.300,
                blushSize: 0.189, blushOpacity: 0.330,
                smirkX: 0.019, smirkY: 0.013,
                smirkW: 0.126, smirkH: 0.040,
                squintW: 0.83, squintH: 0.05, squintSpread: 2.64,
                surprisedX: 0.25, surprisedY: 0.10, surprisedScale: 0.25,
                leftEyeScale: 1.0, rightEyeScale: 1.0
            ),
            useProgrammaticMouth: true,
            pmouthW:         0.19,
            pmouthH:         0.05,
            pmouthOffsetX:   2,
            pmouthOffsetY:   -7,
            pmouthCurve:     1.70,
            leftEyeOffsetX:  18, leftEyeOffsetY: 12, leftEyeSpread: 1,
            leftEyeScaleL: 1.15, leftEyeScaleR: 0.95,
            leftMouthOffsetX: 16, leftMouthOffsetY: 14
        ),
        "body_blueC": CharacterPartOffsets(
            bodyScale:       1.20,
            eyes:            CGSize(width: 0, height: 0),
            mouth:           CGSize(width: 0, height: 0),
            detail:          CGSize(width: -2, height: 20),
            detailRotation:  -50,
            detail2:         CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:         CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:            CGSize(width: 0, height: 0),
            shineX:          -0.18,
            shineY:          -0.05,
            shineW:          0.08,
            shineH:          0.18,
            shineRotation:   -30,
            shineOpacity:    0.90,
            armOffset:       CGSize(width: 0, height: 0),
            armScale:        1,
            armRotation:     0,
            leftArmRotation:  5,
            rightArmRotation: -5,
            leftArmOffsetX:   -10,
            rightArmOffsetX:  12,
            joyLeftArmX: -70, joyLeftArmR: -185,
            joyRightArmX: 68, joyRightArmR: 185,
            legOffset:       CGSize(width: 0, height: 32),
            legScale:        1.20,
            legRotation:     0,
            mood: MoodOverlayOffsets(
                blushX: 0.32, blushY: 0.144,
                blushSize: 0.14, blushOpacity: 0.33,
                squintW: 0.83, squintH: 0.04, squintSpread: 2.747
            )
        ),
        "body_base_C": CharacterPartOffsets(
            bodyScale:       1.35,
            eyes:            CGSize(width: 0, height: -3),
            eyeScale:        0.90,
            eyeSpread:       7,
            mouth:           CGSize(width: 0, height: 0),
            detail:          CGSize(width: -2, height: 20),
            detailRotation:  -50,
            detail2:         CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:         CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:            CGSize(width: 0, height: 0),
            shineX:          -0.18,
            shineY:          -0.05,
            shineW:          0.08,
            shineH:          0.18,
            shineRotation:   -30,
            shineOpacity:    0.90,
            armOffset:       CGSize(width: 0, height: 0),
            armScale:        1,
            armRotation:     0,
            leftArmRotation:  5,
            rightArmRotation: -5,
            leftArmOffsetX:   -10,
            rightArmOffsetX:  12,
            legOffset:       CGSize(width: 0, height: 43),
            legScale:        1.30,
            legRotation:     0,
            mood: MoodOverlayOffsets(
                blushX: 0.32, blushY: 0.144,
                blushSize: 0.14, blushOpacity: 0.33,
                squintW: 0.83, squintH: 0.04, squintSpread: 2.133,
                leftEyeScale: 1.30, rightEyeScale: 1.05
            )
        ),

        // ── モンスター ──
        "body_greenC": CharacterPartOffsets(
            eyes:            CGSize(width: 0, height: 0),
            mouth:           CGSize(width: 0, height: 0),
            detail:          CGSize(width: -2, height: 20),
            detailRotation:  -50,
            detail2:         CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:         CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:            CGSize(width: 0, height: 0),
            armOffset:       CGSize(width: 0, height: 0),
            armScale:        1,
            armRotation:     0,
            leftArmRotation:  5,
            rightArmRotation: -5,
            leftArmOffsetX:   -8,
            rightArmOffsetX:  10,
            legOffset:       CGSize(width: 0, height: -10),
            legScale:        1,
            legRotation:     0
        ),
        "body_darkC": CharacterPartOffsets(
            eyes:           .zero,
            mouth:          .zero,
            detail:         CGSize(width: -32, height: 25),
            detailRotation: -70,
            detail2:        CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:        CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:           .zero,
            legOffset:      CGSize(width: 0, height: -10)
        ),
        "body_darkA": CharacterPartOffsets(
            eyes:           .zero,
            mouth:          .zero,
            detail:         CGSize(width: -32, height: 25),
            detailRotation: -70,
            detail2:        CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:        CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:           .zero,
            legOffset:      CGSize(width: 0, height: -10)
        ),
        "body_darkB": CharacterPartOffsets(
            eyes:           .zero,
            mouth:          CGSize(width: 0, height: 18),
            detail:         CGSize(width: -32, height: 25),
            detailRotation: -70,
            detail2:        CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:        CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:           CGSize(width: 0, height: 14),
            legOffset:      CGSize(width: 0, height: -10)
        ),
        
        "body_redB": CharacterPartOffsets(
            eyes:           .zero,
            mouth:          CGSize(width: 0, height: 18),
            detail:         CGSize(width: -32, height: 25),
            detailRotation: -70,
            detail2:        CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:        CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:           CGSize(width: 0, height: 14),
            legOffset:      CGSize(width: 0, height: -10)
        ),
        "body_redC": CharacterPartOffsets(
            eyes:            CGSize(width: 0, height: 0),
            mouth:           CGSize(width: 0, height: 0),
            detail:          CGSize(width: -2, height: 20),
            detailRotation:  -50,
            detail2:         CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:         CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:            CGSize(width: 0, height: 0),
            armOffset:       CGSize(width: 0, height: 0),
            armScale:        1,
            armRotation:     0,
            leftArmRotation:  0,
            rightArmRotation: 0,
            leftArmOffsetX:   -5,
            rightArmOffsetX:  9,
            legOffset:       CGSize(width: 0, height: -10),
            legScale:        1,
            legRotation:     0
        ),
        "body_yellowB": CharacterPartOffsets(
            eyes:           .zero,
            mouth:          .zero,
            detail:         CGSize(width: -32, height: 25),
            detailRotation: -70,
            detail2:        CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:        CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:           .zero,
            legOffset:      CGSize(width: 0, height: -10),
            mood: MoodOverlayOffsets(
                squintW: 0.83, squintH: 0.04, squintSpread: 2.785
            )
        ),
        "body_blueA": CharacterPartOffsets(
            eyes:           CGSize(width: 0, height: 5),
            mouth:          CGSize(width: 0, height: 13),
            detail:         CGSize(width: -32, height: 25),
            detailRotation: -70,
            detail2:        CGSize(width: 35, height: 24),
            detail2Rotation: -20,
            detail3:        CGSize(width: 0, height: 19),
            detail3Rotation: -45,
            nose:           .zero,
            legOffset:      CGSize(width: 0, height: -10)
        ),

        // ── じかんどろぼう ──
        "body_blueE": CharacterPartOffsets(
            eyes:             CGSize(width: 0, height: 0),
            mouth:            CGSize(width: 0, height: 0),
            detail:           CGSize(width: 0, height: 8),
            detailRotation:   0,
            nose:             CGSize(width: 0, height: 0),
            armOffset:        CGSize(width: 0, height: 10),
            armScale:         1,
            armRotation:      0,
            leftArmRotation:  0,
            rightArmRotation: 0,
            leftArmOffsetX:   0,
            rightArmOffsetX:  0,
            legOffset:        CGSize(width: 0, height: -10),
            legScale:         1.2,
            legRotation:      0
        ),

        // ── まちがいおに ──
        "body_whiteF": CharacterPartOffsets(
            eyes:             CGSize(width: 0, height: 0),
            mouth:            CGSize(width: 0, height: 0),
            detail:           CGSize(width: 0, height: 10),
            detailRotation:   0,
            nose:             CGSize(width: 0, height: 0),
            armOffset:        CGSize(width: 0, height: 0),
            armScale:         1,
            armRotation:      0,
            leftArmRotation:  0,
            rightArmRotation: 0,
            leftArmOffsetX:   0,
            rightArmOffsetX:  0,
            legOffset:        CGSize(width: 0, height: -14),
            legScale:         1.60,
            legRotation:      0
        ),
    ]
}
