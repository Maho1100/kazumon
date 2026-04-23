import SwiftUI

struct BossOverlay: View {
    let monster: Monster

    @State private var phase = 0
    @State private var bgOpacity: Double = 0
    @State private var flash1: Double = 0
    @State private var flash2: Double = 0
    @State private var flash3: Double = 0
    @State private var textScale: CGFloat = 4.0
    @State private var textOpacity: Double = 0
    @State private var subTextOpacity: Double = 0
    @State private var shakeX: CGFloat = 0
    @State private var wholeOpacity: Double = 1.0
    @State private var warningPulse: CGFloat = 1.0
    @State private var lineOffset: CGFloat = -400

    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity * 0.7)
                .ignoresSafeArea()

            // 赤フラッシュ（3連続）
            Color.red.opacity(flash1 * 0.5).ignoresSafeArea()
            Color.white.opacity(flash2 * 0.8).ignoresSafeArea()
            Color.red.opacity(flash3 * 0.4).ignoresSafeArea()

            // 横ライン演出
            Rectangle()
                .fill(LinearGradient(colors: [.clear, .red.opacity(0.6), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 4)
                .offset(y: lineOffset)

            Rectangle()
                .fill(LinearGradient(colors: [.clear, .red.opacity(0.6), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 4)
                .offset(y: -lineOffset)

            // WARNING パルス
            if phase >= 1 {
                Text("WARNING!")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.red)
                    .tracking(8)
                    .scaleEffect(warningPulse)
                    .opacity(phase < 3 ? 0.6 : 0)
                    .offset(y: -100)
            }

            // メインテキスト
            VStack(spacing: 10) {
                Text(NSLocalizedString("view_overlay_boss_appears", comment: ""))
                    .font(.zenMaru(40, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .red, radius: 16)
                    .shadow(color: .red.opacity(0.8), radius: 32)
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 3)

                Text(monster.name)
                    .font(.zenMaru(22, weight: .bold))
                    .foregroundColor(.yellow)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    .opacity(subTextOpacity)
            }
            .scaleEffect(textScale)
            .opacity(textOpacity)
        }
        .offset(x: shakeX)
        .opacity(wholeOpacity)
        .onAppear { runSequence() }
    }

    private func runSequence() {
        // 0.0s: 暗転
        withAnimation(.easeOut(duration: 0.1)) { bgOpacity = 1.0 }

        // 0.0s: フラッシュ1（赤）
        withAnimation(.easeOut(duration: 0.08)) { flash1 = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.08)) { flash1 = 0 }
        }
        HapticsManager.bossAppear()

        // 0.2s: フラッシュ2（白） + シェイク
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            phase = 1
            withAnimation(.easeOut(duration: 0.06)) { flash2 = 1 }
            HapticsManager.incorrect()
            runHeavyShake()
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                warningPulse = 1.2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.1)) { flash2 = 0 }
        }

        // 0.4s: フラッシュ3（赤）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.06)) { flash3 = 1 }
            HapticsManager.tap()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.1)) { flash3 = 0 }
        }

        // 0.3s: ライン演出
        withAnimation(.easeOut(duration: 0.6)) { lineOffset = 400 }

        // 0.7s: テキスト ドーン！
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            phase = 3
            SoundManager.shared.playTap()
            HapticsManager.correct()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                textScale = 1.0
                textOpacity = 1.0
            }
        }

        // 0.9s: サブテキスト
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.2)) { subTextOpacity = 1.0 }
        }

        // 1.8s: フェードアウト
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.5)) { wholeOpacity = 0 }
        }
    }

    private func runHeavyShake() {
        let steps: [(CGFloat, Double)] = [
            (12, 0), (-12, 0.04), (10, 0.08), (-10, 0.12),
            (8, 0.16), (-8, 0.20), (6, 0.24), (-5, 0.28),
            (4, 0.32), (-3, 0.36), (2, 0.40), (0, 0.45)
        ]
        for (offset, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.03)) { shakeX = offset }
            }
        }
    }
}
