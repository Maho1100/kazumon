import SwiftUI

/// young4 → young 昇格画面（扉が開くアニメーション付き）
struct Young4PromotionView: View {
    let onStart: () -> Void

    // 演出フェーズ
    @State private var phase = 0  // 0=暗転, 1=白フラッシュ→お祝い
    @State private var whiteOut: Double = 0

    // お祝い画面
    @State private var charScale: CGFloat = 0
    @State private var charFloat: CGFloat = 0
    @State private var showTitle = false
    @State private var showSub = false
    @State private var showHint = false
    @State private var showButton = false
    @State private var confetti = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            if phase >= 1 {
                // お祝い背景
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.1)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                if confetti { ResultConfettiView().allowsHitTesting(false) }

                celebrationContent
            }

            // 白フラッシュ
            Color.white.ignoresSafeArea()
                .opacity(whiteOut)
                .allowsHitTesting(false)
        }
        .onAppear { runSequence() }
    }

    // MARK: - 演出シーケンス

    private func runSequence() {
        // 0.5s: 効果音
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SoundManager.shared.playBossAppear()
            HapticsManager.tap()
        }

        // 1.0s: 白フラッシュ → お祝い画面へ
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.3)) { whiteOut = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            phase = 1
            withAnimation(.easeOut(duration: 0.3)) { whiteOut = 0 }
            runCelebration()
        }
    }

    // MARK: - お祝い演出

    private var celebrationContent: some View {
        VStack(spacing: 20) {
            Spacer()

            KennyCharacterView(
                appearance: CharacterAppearanceFactory.appearance(for: 1),
                size: 150
            )
            .allowsHitTesting(false)
            .scaleEffect(charScale)
            .offset(y: charFloat)

            Text("young4_promotion_title")
                .font(.zenMaru(52, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                .opacity(showTitle ? 1 : 0)

            Text("young4_promotion_sub")
                .font(.zenMaru(22, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(showSub ? 1 : 0)

            Text("young4_promotion_hint")
                .font(.zenMaru(16, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .opacity(showHint ? 1 : 0)

            Spacer()

            if showButton {
                Button {
                    HapticsManager.tap()
                    performPromotion()
                    onStart()
                } label: {
                    Text("young4_promotion_button")
                        .font(.zenMaru(24, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 240, height: 64)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.green))
                        .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                        .scaleEffect(pulseScale)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 50)
        }
    }

    private func runCelebration() {
        SoundManager.shared.playBossVictory()
        HapticsManager.incorrect()
        confetti = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) { charScale = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { charFloat = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) { showTitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) { showSub = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.4)) { showHint = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { showButton = true }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.3)) {
                pulseScale = 1.05
            }
        }
    }

    // MARK: - 昇格処理

    private func performPromotion() {
        DataStore.saveAgeGroup(.young)
        // ビフォーテストをスキップ済みとしてマーク（young4卒業生はBeforeTest不要）
        DataStore.saveBeforeTestResult(score: 0, total: 0, level: 1)
        // チャレンジリセット
        DataStore.resetChallenge()
        // プロフィール更新
        var profiles = DataStore.loadProfiles()
        if let idx = profiles.firstIndex(where: { $0.id.uuidString == DataStore.activeProfileId() }) {
            profiles[idx].ageGroup = .young
            DataStore.saveProfiles(profiles)
        }
    }
}
