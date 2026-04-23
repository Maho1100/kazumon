import SwiftUI

/// ART_DIRECTION.md 準拠のデザインシステム
/// 全画面で共通のカラー・ボタン・影・角丸・フォント規格
enum KazumonTheme {

    // MARK: - カラーパレット

    /// プライマリカラー
    static let sky    = Color(red: 0.53, green: 0.81, blue: 0.98)  // 背景ベース
    static let grass  = Color(red: 0.30, green: 0.72, blue: 0.49)  // 成功/GO系
    static let coral  = Color(red: 0.91, green: 0.35, blue: 0.35)  // 警告/ダメージ
    static let purple = Color(red: 0.48, green: 0.44, blue: 0.86)  // バトル/対戦系

    /// ニュートラル
    static let dark   = Color(red: 0.16, green: 0.16, blue: 0.23)  // テキスト
    static let muted  = Color(red: 0.43, green: 0.43, blue: 0.49)  // サブテキスト
    static let light  = Color(red: 0.96, green: 0.94, blue: 0.92)  // 背景サブ
    static let white  = Color.white

    // MARK: - 角丸（12 / 16 / 20 のみ）

    static let radiusSmall:  CGFloat = 12
    static let radiusMedium: CGFloat = 16
    static let radiusLarge:  CGFloat = 20

    // MARK: - ボタンサイズ

    static let buttonHeightSmall:  CGFloat = 40
    static let buttonHeightMedium: CGFloat = 56
    static let buttonHeightLarge:  CGFloat = 72

    // MARK: - 影（1レイヤーのみ）

    static let shadowColor   = Color.black.opacity(0.18)
    static let shadowRadius: CGFloat = 6
    static let shadowY:      CGFloat = 3

    // MARK: - フォントサイズ階層

    static let fontHero:     CGFloat = 48  // タイトル演出
    static let fontHeadline: CGFloat = 30  // 画面タイトル
    static let fontTitle:    CGFloat = 22  // セクション見出し
    static let fontBody:     CGFloat = 17  // 本文・ボタンラベル
    static let fontCaption:  CGFloat = 13  // 補足情報
    static let fontSmall:    CGFloat = 11  // バッジ・タイムスタンプ

    // MARK: - アニメーション

    static let transitionStandard = Animation.easeInOut(duration: 0.3)
    static let springButton       = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springEntrance     = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

// MARK: - ボタンスタイル

/// ART_DIRECTION 準拠のフラットボタン（btn_wood_plank の代替）
struct KazumonButtonStyle: ViewModifier {
    let color: Color
    let height: CGFloat
    let radius: CGFloat

    init(
        color: Color = KazumonTheme.grass,
        height: CGFloat = KazumonTheme.buttonHeightLarge,
        radius: CGFloat = KazumonTheme.radiusLarge
    ) {
        self.color = color
        self.height = height
        self.radius = radius
    }

    func body(content: Content) -> some View {
        content
            .font(.zenMaru(KazumonTheme.fontTitle, weight: .black))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(color)
            )
            .shadow(color: KazumonTheme.shadowColor, radius: KazumonTheme.shadowRadius, y: KazumonTheme.shadowY)
    }
}

/// 幅指定ありのフラットボタン（固定幅用途）
struct KazumonFixedButtonStyle: ViewModifier {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let radius: CGFloat

    init(
        color: Color = KazumonTheme.grass,
        width: CGFloat = 220,
        height: CGFloat = KazumonTheme.buttonHeightLarge,
        radius: CGFloat = KazumonTheme.radiusLarge
    ) {
        self.color = color
        self.width = width
        self.height = height
        self.radius = radius
    }

    func body(content: Content) -> some View {
        content
            .font(.zenMaru(KazumonTheme.fontTitle, weight: .black))
            .foregroundColor(.white)
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(color)
            )
            .shadow(color: KazumonTheme.shadowColor, radius: KazumonTheme.shadowRadius, y: KazumonTheme.shadowY)
    }
}

extension View {
    func kazumonButton(
        color: Color = KazumonTheme.grass,
        height: CGFloat = KazumonTheme.buttonHeightLarge,
        radius: CGFloat = KazumonTheme.radiusLarge
    ) -> some View {
        modifier(KazumonButtonStyle(color: color, height: height, radius: radius))
    }

    func kazumonFixedButton(
        color: Color = KazumonTheme.grass,
        width: CGFloat = 220,
        height: CGFloat = KazumonTheme.buttonHeightLarge,
        radius: CGFloat = KazumonTheme.radiusLarge
    ) -> some View {
        modifier(KazumonFixedButtonStyle(color: color, width: width, height: height, radius: radius))
    }

    /// ART_DIRECTION 準拠の標準シャドウ（1レイヤー）
    func kazumonShadow() -> some View {
        shadow(color: KazumonTheme.shadowColor, radius: KazumonTheme.shadowRadius, y: KazumonTheme.shadowY)
    }
}
