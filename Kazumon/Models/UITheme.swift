import SwiftUI

/// 年齢モード別UIテーマ定数
enum UITheme {

    // MARK: - 5歳モード（やさしい・安心・楽しい）

    enum Young {
        // 背景
        static let bgTop = Color(red: 1.0, green: 0.96, blue: 0.9)     // クリーム
        static let bgBottom = Color(red: 1.0, green: 0.72, blue: 0.3)  // やわらかオレンジ

        // ボタン
        static let trainColor = Color(red: 0.30, green: 0.69, blue: 0.49)  // やわらか緑
        static let battleColor = Color(red: 0.48, green: 0.44, blue: 0.75) // やわらか紫
        static let buttonRadius: CGFloat = KazumonTheme.radiusLarge
        static let buttonHeight: CGFloat = 80
        static let buttonFontSize: CGFloat = 24
        static let buttonShadowY: CGFloat = 4

        // キャラ
        static let characterSize: CGFloat = 48

        // アニメーション
        static let pulseMin: CGFloat = 1.0
        static let pulseMax: CGFloat = 1.03
        static let pulseDuration: Double = 1.0
        static let tapScale: CGFloat = 0.95

        // アイコン
        static let trainIcon = "book.fill"
        static let battleIcon = "person.2.fill"
    }

    // MARK: - 8歳モード（ゲームっぽい・挑戦・カッコいい）

    enum Older {
        // 背景
        static let bgTop = Color(red: 0.10, green: 0.10, blue: 0.24)    // 濃紺
        static let bgBottom = Color(red: 0.18, green: 0.11, blue: 0.31) // ダークパープル

        // ボタン
        static let trainColor = Color(red: 0.18, green: 0.49, blue: 0.61)  // ダークシアン
        static let battleGradient1 = Color(red: 0.42, green: 0.31, blue: 0.85) // 紫
        static let battleGradient2 = Color(red: 0.55, green: 0.36, blue: 0.96) // 明るい紫
        static let battleGlow = Color(red: 0.65, green: 0.55, blue: 0.98)      // 光縁
        static let buttonRadius: CGFloat = KazumonTheme.radiusMedium
        static let buttonHeight: CGFloat = 64
        static let buttonFontSize: CGFloat = 22
        static let buttonShadowY: CGFloat = 3

        // キャラ
        static let characterSize: CGFloat = 130

        // アニメーション
        static let shimmerDuration: Double = 3.0
        static let tapScale: CGFloat = 0.97

        // アイコン
        static let trainIcon = "bolt.fill"
        static let battleIcon = "figure.fencing"

        // テキスト
        static let subTextOpacity: Double = 0.6
    }

    // MARK: - 共通

    static let titleFont: CGFloat = 36
    static let profileRadius: CGFloat = 12
    static let profileBg = Color.white.opacity(0.15)
}
