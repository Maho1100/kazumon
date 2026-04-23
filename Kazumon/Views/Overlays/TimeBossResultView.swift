import SwiftUI

/// じかんどろぼう撃破リザルト — ヒカキン流
struct TimeBossResultView: View {
    @Bindable var gameVM: GameViewModel

    @State private var phase = 0
    @State private var bgRevealed = false
    @State private var showFlash = false
    @State private var titleScale: CGFloat = 4.0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var xpScale: CGFloat = 3.0
    @State private var xpOpacity: Double = 0
    @State private var xpPulse: CGFloat = 1.0
    @State private var praiseOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiVisible = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if bgRevealed {
                LinearGradient(
                    colors: [Color(red: 0, green: 0.4, blue: 0.6), Color(red: 0.2, green: 0.8, blue: 1.0)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea().transition(.opacity)
            }

            if confettiVisible { ResultConfettiView().allowsHitTesting(false) }

            VStack(spacing: 24) {
                Spacer()

                Text("time_boss_defeated_title")
                    .font(.zenMaru(28, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                    .scaleEffect(titleScale).opacity(titleOpacity)

                Text(TimeBossConfig.defeatLines.randomElement() ?? "")
                    .font(.zenMaru(20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(subtitleOpacity)

                Text("+\(TimeBossConfig.xpBonus) XP")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0))
                    .shadow(color: Color(red: 1.0, green: 0.85, blue: 0).opacity(0.6), radius: 16)
                    .scaleEffect(xpScale * xpPulse).opacity(xpOpacity)

                Text("time_boss_result_praise")
                    .font(.zenMaru(22, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(praiseOpacity)

                Spacer()

                Button {
                    HapticsManager.tap()
                    gameVM.isTimeBossMode = false
                    gameVM.returnToTitle()
                } label: {
                    Text("time_boss_done")
                        .font(.zenMaru(22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.2)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.4), lineWidth: 2))
                }
                .opacity(buttonOpacity)
                .padding(.horizontal, 32).padding(.bottom, 40)
            }
            .offset(x: shakeOffset)

            Color.white.ignoresSafeArea().opacity(showFlash ? 1 : 0).allowsHitTesting(false)
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        SoundManager.shared.stopBGM()

        showFlash = true
        at(0.15) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false; bgRevealed = true } }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { titleScale = 1.0; titleOpacity = 1 }
        SoundManager.shared.playBossAppear()
        HapticsManager.incorrect()
        runShake()

        at(1.0) { withAnimation(.easeOut(duration: 0.4)) { subtitleOpacity = 1 } }

        at(1.8) {
            showFlash = true
            at(0.1) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false } }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { xpScale = 1.0; xpOpacity = 1 }
            SoundManager.shared.playBossVictory()
            HapticsManager.incorrect()
            runShake()
            confettiVisible = true
            at(0.5) { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { xpPulse = 1.08 } }
        }

        at(2.8) { withAnimation(.easeOut(duration: 0.4)) { praiseOpacity = 1 } }
        at(3.5) { SoundManager.shared.playResult(); withAnimation(.easeOut(duration: 0.4)) { buttonOpacity = 1 } }
    }

    private func at(_ delay: Double, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
    }

    private func runShake() {
        let steps: [(CGFloat, Double)] = [(10,0),(-10,0.04),(8,0.08),(-6,0.12),(4,0.16),(0,0.20)]
        for (o, d) in steps { at(d) { withAnimation(.linear(duration: 0.03)) { shakeOffset = o } } }
    }
}
