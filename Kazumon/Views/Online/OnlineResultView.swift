import SwiftUI

/// オンライン対戦結果画面
struct OnlineResultView: View {
    let myScore: Int
    let myCorrect: Int
    let myCombo: Int
    let onRematch: () -> Void
    let onHome: () -> Void

    @State private var mp = MultiplayerService.shared
    @State private var phase = 0
    @State private var resultScale: CGFloat = 3.0
    @State private var resultOpacity: Double = 0
    @State private var scoreOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var showFlash = false
    @State private var confettiVisible = false
    @State private var bgRevealed = false

    private var myName: String { mp.isHost ? mp.hostName : mp.guestName }
    private var opName: String { mp.isHost ? mp.guestName : mp.hostName }

    private var result: String {
        if mp.opponentDisconnected { return "win" }
        if mp.winner == "draw" { return "draw" }
        if (mp.isHost && mp.winner == "host") || (!mp.isHost && mp.winner == "guest") {
            return "win"
        }
        return "lose"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if bgRevealed {
                LinearGradient(
                    colors: result == "win"
                        ? [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.1)]
                        : [Color(red: 0.4, green: 0.3, blue: 0.7), Color(red: 0.3, green: 0.2, blue: 0.5)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
            }

            if confettiVisible { ResultConfettiView().allowsHitTesting(false) }

            VStack(spacing: 16) {
                Spacer()

                // Phase 0: 勝敗テキスト
                if phase >= 0 {
                    Text(NSLocalizedString(
                        result == "win" ? "versus_result_win" :
                        result == "draw" ? "versus_result_draw" : "versus_result_lose",
                        comment: ""
                    ))
                    .font(.zenMaru(42, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 2)
                    .scaleEffect(resultScale)
                    .opacity(resultOpacity)
                }

                Spacer().frame(height: 10)

                // Phase 1: スコア比較
                if phase >= 1 {
                    VStack(spacing: 12) {
                        scoreRow(name: myName, score: myScore, correct: myCorrect, combo: myCombo, highlight: true)
                        Text("VS")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        scoreRow(name: opName, score: mp.opponentScore, correct: mp.opponentCorrect, combo: mp.opponentCombo, highlight: false)
                    }
                    .opacity(scoreOpacity)
                }

                Spacer()

                // Phase 2: ボタン
                if phase >= 2 {
                    VStack(spacing: 12) {
                        Button {
                            HapticsManager.tap()
                            onRematch()
                        } label: {
                            Text("versus_result_rematch")
                                .font(.zenMaru(20, weight: .black))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 56)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.green))
                                .shadow(color: .green.opacity(0.4), radius: 6, y: 4)
                        }

                        Button {
                            HapticsManager.tap()
                            onHome()
                        } label: {
                            Text("versus_result_home")
                                .font(.zenMaru(16, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 32)
                    .opacity(buttonOpacity)
                }

                Spacer().frame(height: 40)
            }

            Color.white.ignoresSafeArea()
                .opacity(showFlash ? 1 : 0)
                .allowsHitTesting(false)
        }
        .onAppear { runSequence() }
    }

    // MARK: - スコア行

    @ViewBuilder
    private func scoreRow(name: String, score: Int, correct: Int, combo: Int, highlight: Bool) -> some View {
        HStack(spacing: 16) {
            Text(name)
                .font(.zenMaru(18, weight: .black))
                .foregroundStyle(highlight ? .yellow : .white)
                .frame(width: 80, alignment: .leading)
                .lineLimit(1)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Text("\(correct)") + Text("ok").font(.zenMaru(10, weight: .bold))
                    Text("\(combo)") + Text("combo").font(.zenMaru(10, weight: .bold))
                }
                .font(.zenMaru(12, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - 演出

    private func runSequence() {
        // 0.0s: 背景 + 勝敗テキスト
        SoundManager.shared.playBossAppear()
        HapticsManager.incorrect()
        withAnimation(.easeOut(duration: 0.2)) { bgRevealed = true }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            resultScale = 1.0; resultOpacity = 1
        }

        // 1.0s: フラッシュ + スコア
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            phase = 1
            showFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) { showFlash = false }
            }
            withAnimation(.easeOut(duration: 0.4)) { scoreOpacity = 1 }
            if result == "win" {
                SoundManager.shared.playBossVictory()
                confettiVisible = true
            } else {
                SoundManager.shared.playDefeat()
            }
            HapticsManager.tap()
        }

        // 2.5s: ボタン
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            phase = 2
            withAnimation(.easeOut(duration: 0.3)) { buttonOpacity = 1 }
        }
    }
}
