import SwiftUI

struct BattleShopView: View {
    let gameVM: GameViewModel
    let onDismiss: () -> Void

    @State private var fadeIn: Double = 0
    @State private var selectedDifficulty: Difficulty = .normal
    @State private var phase: Int = 0  // 0=メイン, 1=難易度, 2=問題タイプ
    @State private var showLeftButton = false
    @State private var showRightButton = false
    @State private var breathPhase = false
    @State private var tokkunPressed = false
    @State private var versusPressed = false

    var body: some View {
        ZStack {
            // 背景（2色グラデーション）
            LinearGradient(
                colors: [KazumonTheme.sky, KazumonTheme.sky.opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // 店タイトル
                Text(NSLocalizedString("battle_shop_welcome", comment: ""))
                    .font(.zenMaru(32, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 2)

                // ステップインジケーター
                stepIndicator
                    .padding(.top, 8).padding(.bottom, 16)

                if phase == 0 {
                    // メイン: とっくん / バトル（左右横並び・道に沿って配置）
                    HStack(spacing: 16) {
                        // とっくん（左の道寄り）
                        Button {
                            HapticsManager.tap(); SoundManager.shared.playTap()
                            AnalyticsManager.trackScreenAction("battle_shop", action: "select_tokkun")
                            AnalyticsManager.trackFunnelStep(funnel: "battle_start", step: "mode_tokkun", stepIndex: 1)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { phase = 1 }
                        } label: {
                            ZStack {
                                Image("btn_tokkun")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 155, height: 103)
                                Text(NSLocalizedString("older_mode_challenge", comment: ""))
                                    .font(.zenMaru(18, weight: .black))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                    .offset(y: 4)
                            }
                        }
                        .scaleEffect(tokkunPressed ? 0.92 : 1.0)
                        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                            withAnimation(.easeInOut(duration: 0.1)) { tokkunPressed = pressing }
                        }, perform: {})
                        .offset(x: -10, y: 10)
                        .offset(y: showLeftButton ? 0 : 40)
                        .opacity(showLeftButton ? 1 : 0)
                        .scaleEffect(showLeftButton ? 1.0 : 0.6)
                        .offset(y: breathPhase ? -3 : 3)

                        // バトル（右の道寄り）
                        Button {
                            HapticsManager.tap(); SoundManager.shared.playTap()
                            AnalyticsManager.trackScreenAction("battle_shop", action: "select_versus")
                            AnalyticsManager.trackFunnelStep(funnel: "battle_start", step: "mode_versus", stepIndex: 1)
                            gameVM.versusIsFamily = false
                            gameVM.isFamilyNPCMode = false
                            gameVM.currentFamilyMember = nil
                            gameVM.showVersus = true
                            onDismiss()
                        } label: {
                            ZStack {
                                Image("btn_versus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 155, height: 103)
                                Text(NSLocalizedString("older_mode_versus", comment: ""))
                                    .font(.zenMaru(18, weight: .black))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                    .offset(y: 4)
                            }
                        }
                        .scaleEffect(versusPressed ? 0.92 : 1.0)
                        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                            withAnimation(.easeInOut(duration: 0.1)) { versusPressed = pressing }
                        }, perform: {})
                        .offset(x: 10, y: -10)
                        .offset(y: showRightButton ? 0 : 40)
                        .opacity(showRightButton ? 1 : 0)
                        .scaleEffect(showRightButton ? 1.0 : 0.6)
                        .offset(y: breathPhase ? 3 : -3)
                    }
                } else if phase == 1 {
                    // 難易度選択
                    VStack(spacing: 16) {
                        ForEach(Difficulty.allCases, id: \.self) { diff in
                            difficultyButton(diff: diff) {
                                HapticsManager.tap(); SoundManager.shared.playTap()
                                selectedDifficulty = diff
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { phase = 2 }
                            }
                        }
                    }
                } else if phase == 2 {
                    // 問題タイプ選択
                    VStack(spacing: 16) {
                        ForEach(ProblemType.allCases, id: \.self) { pt in
                            shopButton(
                                text: pt.label,
                                color: .blue
                            ) {
                                HapticsManager.tap(); SoundManager.shared.playTap()
                                gameVM.problemType = pt
                                onDismiss()
                                gameVM.startGame(difficulty: selectedDifficulty)
                            }
                        }
                    }
                }

                Spacer()

                // もどるボタン
                Button {
                    HapticsManager.tap(); SoundManager.shared.playTap()
                    if phase > 1 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { phase -= 1 }
                    } else {
                        onDismiss()
                    }
                } label: {
                    Text(NSLocalizedString("battle_shop_back", comment: ""))
                        .font(.zenMaru(20, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.25))
                        )
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 40)
        }
        .opacity(fadeIn)
        .onAppear {
            AnalyticsManager.logViewBattleShop()
            AnalyticsManager.trackScreenEnter("battle_shop")
            phase = 1
            showLeftButton = false
            showRightButton = false
            withAnimation(.easeOut(duration: 0.3)) { fadeIn = 1.0 }
            // 左ボタン: 0.3秒後にバウンス登場
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                showLeftButton = true
            }
            // 右ボタン: 0.45秒後にバウンス登場（時間差）
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.45)) {
                showRightButton = true
            }
            // 呼吸アニメーション
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.8)) {
                breathPhase = true
            }
        }
    }

    // MARK: - ステップインジケーター

    private var stepIndicator: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i <= phase ? Color.white : Color.white.opacity(0.3))
                    .frame(width: i == phase ? 14 : 10, height: i == phase ? 14 : 10)
                    .shadow(color: i == phase ? .white.opacity(0.6) : .clear, radius: 4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: phase)
    }

    @ViewBuilder
    private func shopButton(text: String, icon: String? = nil, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28)
                }
                Text(text)
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(RoundedRectangle(cornerRadius: 20).fill(color))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func difficultyButton(diff: Difficulty, action: @escaping () -> Void) -> some View {
        let buttonColor = Color(red: 0.30, green: 0.69, blue: 0.49)
        Button(action: action) {
            HStack(spacing: 8) {
                Text(diff.labelWithTime)
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(.white)
                ForEach(0..<diff.starCount, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(RoundedRectangle(cornerRadius: 20).fill(buttonColor))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }
}
