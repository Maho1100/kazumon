import SwiftUI

/// ヒカキン流リザルト: 段階的ドラマチック演出
struct VersusResultView: View {
    let playerScore: Int
    let cpuScore: Int
    let onRematch: () -> Void
    let onHome: () -> Void
    var opponentName: String = NSLocalizedString("versus_opponent_name", comment: "")
    var isFamily: Bool = false

    private var isWin: Bool { playerScore > cpuScore }
    private var isDraw: Bool { playerScore == cpuScore }

    private var loseEncouragement: String {
        [
            NSLocalizedString("lose_encourage_1", comment: ""),
            NSLocalizedString("lose_encourage_2", comment: ""),
        ].randomElement()!
    }

    private var familyMessage: String {
        let messages = [
            NSLocalizedString("family_praise_1", comment: ""),
            NSLocalizedString("family_praise_2", comment: ""),
            NSLocalizedString("family_praise_3", comment: ""),
        ]
        return messages.randomElement()!
    }
    private var bpDelta: Int { isFamily ? 0 : (isWin ? VersusConfig.winBP : (isDraw ? 0 : VersusConfig.loseBP)) }

    // ── 段階演出State ──
    @State private var phase = 0
    // 0: 暗転+VS
    // 1: スコア登場
    // 2: 勝敗ドーン
    // 3: キャラ登場
    // 4: BP+ランク
    // 5: ボタン

    @State private var vsScale: CGFloat = 3.0
    @State private var vsOpacity: Double = 0
    @State private var playerScoreDisplay: Int = 0
    @State private var cpuScoreDisplay: Int = 0
    @State private var showPlayerScore = false
    @State private var showCpuScore = false
    @State private var resultScale: CGFloat = 4.0
    @State private var resultOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var charScale: CGFloat = 0.3
    @State private var charOpacity: Double = 0
    @State private var charFloat: CGFloat = 0
    @State private var bpOpacity: Double = 0
    @State private var bpOffset: CGFloat = 30
    @State private var rankScale: CGFloat = 0.5
    @State private var rankOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var showFlash = false
    @State private var confettiVisible = false
    @State private var bgRevealed = false
    @State private var rewardItem: Item?
    @State private var rewardOpacity: Double = 0
    @State private var dailyBonusBP: Int = 0

    var body: some View {
        ZStack {
            // 背景: 最初は黒 → 結果で切り替え
            Color.black.ignoresSafeArea()

            if bgRevealed {
                LinearGradient(
                    colors: isWin
                        ? [Color(red: 0.95, green: 0.8, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.1)]
                        : [Color(red: 0.22, green: 0.18, blue: 0.42), Color(red: 0.15, green: 0.12, blue: 0.32)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }

            // 紙吹雪
            if confettiVisible {
                VersusConfettiView().allowsHitTesting(false)
            }

            // メインコンテンツ
            VStack(spacing: 0) {
                Spacer()

                // Phase 0: VS
                if phase >= 0 {
                    Text("VS")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.6), radius: 16)
                        .scaleEffect(vsScale)
                        .opacity(vsOpacity)
                        .opacity(phase >= 1 ? 0 : 1) // スコア出たら消す
                }

                // Phase 1: スコア
                if phase >= 1 {
                    HStack(spacing: 24) {
                        // プレイヤー
                        VStack(spacing: 4) {
                            Text(DataStore.loadPlayerData().playerName)
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                            Text("\(playerScoreDisplay)")
                                .font(.system(size: 56, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                        }
                        .opacity(showPlayerScore ? 1 : 0)
                        .scaleEffect(showPlayerScore ? 1.0 : 0.5)

                        Text("--")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white.opacity(0.3))
                            .opacity(showPlayerScore ? 1 : 0)

                        // ゆきや
                        VStack(spacing: 4) {
                            Text(opponentName)
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                            Text("\(cpuScoreDisplay)")
                                .font(.system(size: 56, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                        }
                        .opacity(showCpuScore ? 1 : 0)
                        .scaleEffect(showCpuScore ? 1.0 : 0.5)
                    }
                }

                Spacer().frame(height: 20)

                // Phase 2: 勝敗ドーン
                if phase >= 2 {
                    Text(isWin ? "versus_result_win" : (isDraw ? "versus_result_draw" : "versus_result_lose"))
                        .font(.zenMaru(60, weight: .black))
                        .foregroundStyle(isWin ? .yellow : .white)
                        .shadow(color: isWin ? .orange.opacity(0.8) : .black.opacity(0.5), radius: 20, y: 4)
                        .scaleEffect(resultScale)
                        .opacity(resultOpacity)

                    // 親子バトル: 励ましメッセージ
                    if isFamily {
                        Text(familyMessage)
                            .font(.zenMaru(16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .opacity(resultOpacity)
                    }
                }

                Spacer().frame(height: 16)

                // Phase 3: キャラ
                if phase >= 3 {
                    VStack(spacing: 8) {
                        Group {
                            if isWin {
                                Image("win_character").resizable().scaledToFit()
                            } else {
                                Image("lose_character").resizable().scaledToFit()
                            }
                        }
                        .frame(width: 200)

                        // 負け時の吹き出し
                        if !isWin && !isDraw {
                            Text(loseEncouragement)
                                .font(.zenMaru(16, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
                                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2))
                        }
                    }
                    .scaleEffect(charScale)
                    .opacity(charOpacity)
                    .offset(y: charFloat)
                }

                Spacer().frame(height: 16)

                // Phase 4: BP + ランク
                if phase >= 4 {
                    let bp = DataStore.loadVersusBP()
                    let rank = VersusConfig.rank(for: bp)
                    VStack(spacing: 8) {
                        if bpDelta != 0 {
                            Text(bpDelta > 0 ? "+\(bpDelta) BP" : "\(bpDelta) BP")
                                .font(.zenMaru(28, weight: .black))
                                .foregroundStyle(bpDelta > 0 ? .yellow : Color(red: 1.0, green: 0.4, blue: 0.4))
                        }
                        if dailyBonusBP > 0 {
                            Text(String(format: NSLocalizedString("versus_daily_bonus", comment: ""), dailyBonusBP))
                                .font(.zenMaru(13, weight: .bold))
                                .foregroundStyle(.cyan)
                        }

                        HStack(spacing: 8) {
                            Text(rank.rawValue)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.25)))
                            Text(rank.title)
                                .font(.zenMaru(15, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .scaleEffect(rankScale)
                        .opacity(rankOpacity)
                    }
                    .opacity(bpOpacity)
                    .offset(y: bpOffset)
                }

                // アイテム報酬（勝利時）
                if let item = rewardItem {
                    HStack(spacing: 8) {
                        Text(item.emoji).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.localizedName)
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundStyle(.white)
                            Text(item.rarity.star)
                                .font(.system(size: 10))
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)))
                    .opacity(rewardOpacity)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                // Phase 5: ボタン
                if phase >= 5 {
                    VStack(spacing: 12) {
                        Button {
                            HapticsManager.tap()
                            onRematch()
                        } label: {
                            Text("versus_result_rematch")
                                .font(.zenMaru(20, weight: .black))
                                .foregroundColor(.white)
                                .frame(width: 260, height: 56)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.50, green: 0.47, blue: 0.87)))
                                .shadow(color: Color(red: 0.50, green: 0.47, blue: 0.87).opacity(0.5), radius: 8, y: 4)
                        }

                        Button {
                            HapticsManager.tap()
                            onHome()
                        } label: {
                            Text("versus_result_home")
                                .font(.zenMaru(15, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .opacity(buttonOpacity)
                }

                Spacer().frame(height: 40)
            }
            .offset(x: shakeOffset)

            // 白フラッシュ
            Color.white.ignoresSafeArea()
                .opacity(showFlash ? 1 : 0)
                .allowsHitTesting(false)
        }
        .onAppear {
            DataStore.addVersusBP(bpDelta)
            dailyBonusBP = DataStore.claimDailyVersusBonus()
            SupabaseService.shared.logVersusResult(
                playerScore: playerScore,
                opponentScore: cpuScore,
                isWin: isWin,
                bpDelta: bpDelta + dailyBonusBP,
                bpAfter: DataStore.loadVersusBP(),
                isFamily: isFamily
            )
            if isWin, let drop = Item.randomDrop() {
                var items = DataStore.loadItems()
                if let idx = items.firstIndex(where: { $0.id == drop.id }) {
                    items[idx].count += 1
                } else {
                    items.append(drop)
                }
                DataStore.saveItems(items)
                rewardItem = drop
            }
            runSequence()
        }
    }

    // MARK: - ヒカキン流シーケンス

    private func runSequence() {
        // 0.0s: VS ドーン
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            vsScale = 1.0
            vsOpacity = 1
        }
        SoundManager.shared.playBossAppear()
        HapticsManager.incorrect()

        // 1.0s: プレイヤースコア バーン
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            phase = 1
            SoundManager.shared.playCorrect()
            HapticsManager.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                showPlayerScore = true
                playerScoreDisplay = playerScore
            }
        }

        // 1.8s: 相手スコア バーン
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            SoundManager.shared.playCorrect()
            HapticsManager.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                showCpuScore = true
                cpuScoreDisplay = cpuScore
            }
        }

        // 2.8s: 溜め… → 勝敗ドドドーン + 画面シェイク + フラッシュ + 背景変更
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            phase = 2
            showFlash = true
            withAnimation(.easeOut(duration: 0.15)) { bgRevealed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) { showFlash = false }
            }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                resultScale = 1.0
                resultOpacity = 1
            }
            if isWin {
                SoundManager.shared.playBossVictory()
            } else {
                SoundManager.shared.playDefeat()
            }
            HapticsManager.incorrect()
            runShake()
        }

        // 3.5s: キャラ ボヨーン
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            phase = 3
            withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                charScale = 1.0
                charOpacity = 1
            }
            HapticsManager.tap()
            // ふわふわ開始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    charFloat = -10
                }
            }
            if isWin { confettiVisible = true }
        }

        // 4.2s: BP スライドイン
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            phase = 4
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                bpOpacity = 1
                bpOffset = 0
            }
            // ランクバッジ ドロップ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    rankScale = 1.0
                    rankOpacity = 1
                }
                HapticsManager.tap()
            }
        }

        // 4.5s: アイテム報酬
        if rewardItem != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                SoundManager.shared.playCorrect()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    rewardOpacity = 1
                }
            }
        }

        // 5.5s: ボタン
        DispatchQueue.main.asyncAfter(deadline: .now() + (rewardItem != nil ? 5.5 : 5.0)) {
            phase = 5
            withAnimation(.easeOut(duration: 0.4)) {
                buttonOpacity = 1
            }
        }
    }

    // 画面シェイク
    private func runShake() {
        let steps: [(CGFloat, Double)] = [
            (10, 0), (-10, 0.04), (8, 0.08), (-8, 0.12),
            (6, 0.16), (-6, 0.20), (4, 0.24), (-3, 0.28), (0, 0.32)
        ]
        for (offset, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.03)) { shakeOffset = offset }
            }
        }
    }
}

// MARK: - 紙吹雪（丸い図形・大量）

private struct VersusConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, color: Color, size: CGFloat)] = []
    private let colors: [Color] = [
        .yellow, Color(red: 1, green: 0.85, blue: 0), .orange,
        .white, .purple, .cyan, .pink, .red, .green
    ]

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { p in
                VersusConfettiParticle(color: p.color, size: p.size).offset(x: p.x)
            }
        }
        .onAppear {
            particles = (0..<40).map { i in
                (id: i,
                 x: CGFloat.random(in: -200...200),
                 color: colors.randomElement()!,
                 size: CGFloat.random(in: 6...16))
            }
        }
    }
}

private struct VersusConfettiParticle: View {
    let color: Color
    let size: CGFloat
    @State private var yOffset: CGFloat = -150
    @State private var xDrift: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: xDrift, y: yOffset)
            .opacity(opacity)
            .onAppear {
                xDrift = CGFloat.random(in: -30...30)
                withAnimation(.easeIn(duration: Double.random(in: 2...5))) {
                    yOffset = CGFloat.random(in: 500...950)
                    xDrift += CGFloat.random(in: -60...60)
                    opacity = 0
                }
            }
    }
}
