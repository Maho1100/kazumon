import SwiftUI

/// 4さいモード用スライム
struct SlimeView: View {
    let color: Color
    let size: CGFloat
    var isSurprised: Bool = false
    /// 外部からタップ反応を発火させるトリガー（値が変わると発火）
    var externalHitTrigger: Int = 0
    /// 内部のタップ反応を有効にするか（false なら親の onTapGesture が動く）
    var tapEnabled: Bool = true

    @State private var bounceScale: CGFloat = 1.0
    @State private var swayAngle: Double = 0
    @State private var tapped = false
    @State private var rippleScale: CGFloat = 0.3
    @State private var rippleOpacity: Double = 0
    @State private var rippleScale2: CGFloat = 0.3
    @State private var rippleOpacity2: Double = 0

    static let palette: [Color] = [
        Color(red: 0.36, green: 0.79, blue: 0.65),
        Color(red: 0.94, green: 0.60, blue: 0.48),
        Color(red: 0.52, green: 0.72, blue: 0.92),
        Color(red: 0.94, green: 0.62, blue: 0.15),
        Color(red: 0.69, green: 0.66, blue: 0.93),
        Color(red: 0.89, green: 0.29, blue: 0.29),
    ]

    static func randomColor() -> Color { palette.randomElement()! }

    private var showSurprise: Bool { isSurprised || tapped }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.4), radius: 4, y: 3)

            // ほっぺ
            Circle().fill(Color.pink.opacity(0.3))
                .frame(width: size * 0.2, height: size * 0.15)
                .offset(x: -size * 0.25, y: size * 0.08)
            Circle().fill(Color.pink.opacity(0.3))
                .frame(width: size * 0.2, height: size * 0.15)
                .offset(x: size * 0.25, y: size * 0.08)

            // 左目
            ZStack {
                Circle().fill(.white)
                    .frame(width: size * 0.22, height: size * 0.22)
                Circle().fill(Color(white: 0.15))
                    .frame(width: size * (showSurprise ? 0.08 : 0.12),
                           height: size * (showSurprise ? 0.08 : 0.12))
                Circle().fill(.white.opacity(0.85))
                    .frame(width: size * 0.04, height: size * 0.04)
                    .offset(x: -size * 0.02, y: -size * 0.02)
            }
            .offset(x: -size * 0.15, y: -size * 0.08)

            // 右目
            ZStack {
                Circle().fill(.white)
                    .frame(width: size * 0.22, height: size * 0.22)
                Circle().fill(Color(white: 0.15))
                    .frame(width: size * (showSurprise ? 0.08 : 0.12),
                           height: size * (showSurprise ? 0.08 : 0.12))
                Circle().fill(.white.opacity(0.85))
                    .frame(width: size * 0.04, height: size * 0.04)
                    .offset(x: -size * 0.02, y: -size * 0.02)
            }
            .offset(x: size * 0.15, y: -size * 0.08)

            // 口（通常:線、驚き:丸）
            if showSurprise {
                Circle().fill(Color(white: 0.2))
                    .frame(width: size * 0.12, height: size * 0.12)
                    .offset(y: size * 0.15)
            } else {
                Capsule().fill(Color(white: 0.2))
                    .frame(width: size * 0.15, height: size * 0.06)
                    .offset(y: size * 0.15)
            }
        }
        // 波紋エフェクト
        .overlay(
            ZStack {
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2.5)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .scaleEffect(rippleScale2)
                    .opacity(rippleOpacity2)
            }
            .allowsHitTesting(false)
        )
        .scaleEffect(bounceScale)
        .rotationEffect(.degrees(swayAngle))
        .contentShape(Circle())
        // tapEnabled の時のみ内部タップを設定（false なら親の onTapGesture に委ねる）
        .modifier(ConditionalTapModifier(enabled: tapEnabled, action: {
            triggerHitReaction(playSound: true)
        }))
        .onChange(of: externalHitTrigger) { _, _ in
            triggerHitReaction(playSound: false)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { bounceScale = 1.05 }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { swayAngle = 3 }
        }
    }

    private func triggerHitReaction(playSound: Bool) {
        if playSound {
            SoundManager.shared.playTap()
            HapticsManager.tap()
        }
        withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { tapped = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { tapped = false }
        }
        // 波紋
        rippleScale = 0.3; rippleOpacity = 0.8
        withAnimation(.easeOut(duration: 0.6)) { rippleScale = 2.0; rippleOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            rippleScale2 = 0.3; rippleOpacity2 = 0.6
            withAnimation(.easeOut(duration: 0.6)) { rippleScale2 = 2.0; rippleOpacity2 = 0 }
        }
    }
}

/// 登場アニメ付きラッパー
struct AnimatedSlimeView: View {
    let color: Color
    let size: CGFloat
    let delay: Double
    var isSurprised: Bool = false

    @State private var appeared = false
    @State private var landScale: CGFloat = 0.3

    var body: some View {
        SlimeView(color: color, size: size, isSurprised: isSurprised)
            .scaleEffect(landScale)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 60)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                        appeared = true; landScale = 1.0
                    }
                    SoundManager.shared.playTap()
                }
            }
    }
}

/// 条件付きで onTapGesture を追加するモディファイア
private struct ConditionalTapModifier: ViewModifier {
    let enabled: Bool
    let action: () -> Void
    func body(content: Content) -> some View {
        if enabled {
            content.onTapGesture { action() }
        } else {
            content
        }
    }
}
