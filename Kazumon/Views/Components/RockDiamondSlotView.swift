import SwiftUI

struct RockDiamondSlotView: View {
    let isDone: Bool
    var breakDelay: Double? = nil  // nil = アニメなし、値あり = 遅延後に破壊演出

    @State private var sparkle: Bool = false
    @State private var rockWiggle: Bool = false

    // 破壊アニメーション用
    @State private var showRock: Bool = true
    @State private var rockShake: CGFloat = 0
    @State private var rockScale: CGFloat = 1.0
    @State private var rockOpacity: Double = 1.0
    @State private var diamondScale: CGFloat = 0
    @State private var crackParticles: Bool = false

    var body: some View {
        ZStack {
            if isDone && !showRock {
                // ダイヤ状態
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.161, green: 0.671, blue: 0.886), Color(red: 0.118, green: 0.533, blue: 0.898)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.576, green: 0.773, blue: 0.992), lineWidth: 2.5)
                    )
                Text("💎")
                    .font(.system(size: 26))
                    .scaleEffect(diamondScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            diamondScale = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                            ) { sparkle = true }
                        }
                    }

                // 破片パーティクル
                if crackParticles {
                    ForEach(0..<6, id: \.self) { i in
                        Text("✦")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                            .offset(
                                x: CGFloat.random(in: -20...20),
                                y: CGFloat.random(in: -20...20)
                            )
                            .opacity(crackParticles ? 0 : 1)
                    }
                }
            } else if isDone && showRock {
                // 破壊中の岩
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.533, green: 0.533, blue: 0.533).opacity(0.5))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.333, green: 0.333, blue: 0.333), lineWidth: 2)
                    )
                    .scaleEffect(rockScale)
                    .opacity(rockOpacity)
                Text("🪨")
                    .font(.system(size: 26))
                    .offset(x: rockShake)
                    .scaleEffect(rockScale)
                    .opacity(rockOpacity)
            } else {
                // 未達成の岩
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.533, green: 0.533, blue: 0.533).opacity(0.5))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.333, green: 0.333, blue: 0.333), lineWidth: 2)
                    )
                Text("🪨")
                    .font(.system(size: 26))
                    .rotationEffect(.degrees(rockWiggle ? -8 : 0))
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true)
                        ) { rockWiggle = true }
                    }
                    .opacity(0.7)
            }
        }
        .onAppear {
            if isDone {
                if let delay = breakDelay {
                    // 破壊演出あり
                    showRock = true
                    diamondScale = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        startBreakAnimation()
                    }
                } else {
                    // 即ダイヤ表示
                    showRock = false
                    diamondScale = 1.0
                }
            }
        }
    }

    private func startBreakAnimation() {
        // フェーズ1: 激しく揺れる（0.5秒）
        let shakeCount = 8
        let shakeDuration = 0.06
        for i in 0..<shakeCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * shakeDuration) {
                withAnimation(.linear(duration: shakeDuration)) {
                    rockShake = i % 2 == 0 ? 6 : -6
                }
            }
        }

        // フェーズ2: 膨張して消える（0.5秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SoundManager.shared.playRockBreak()
            HapticsManager.correct()
            withAnimation(.easeOut(duration: 0.2)) {
                rockScale = 1.3
                rockOpacity = 0
            }

            // フェーズ3: ダイヤ登場
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showRock = false
                SoundManager.shared.playDiamond()
                crackParticles = true
                withAnimation(.easeOut(duration: 0.3)) {
                    crackParticles = false
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        RockDiamondSlotView(isDone: true)
        RockDiamondSlotView(isDone: true, breakDelay: 0.5)
        RockDiamondSlotView(isDone: false)
    }
    .padding()
}
