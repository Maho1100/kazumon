import SwiftUI

/// 競技場リザルト — ヒカキン流
struct ExtraResultView: View {
    @Bindable var extraVM: ExtraViewModel
    @Bindable var gameVM: GameViewModel

    @State private var phase = 0
    @State private var bgRevealed = false
    @State private var showFlash = false
    @State private var scoreScale: CGFloat = 4.0
    @State private var scoreOpacity: Double = 0
    @State private var starsRevealed = 0
    @State private var recordScale: CGFloat = 0.5
    @State private var recordOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiVisible = false
    @State private var shakeOffset: CGFloat = 0
    @State private var monsterOpacity: Double = 0

    private let accentGold = Color(red: 0.93, green: 0.79, blue: 0.30)

    private var starCount: Int {
        FloorRank.stars(correctCount: extraVM.correctCount, totalCount: extraVM.totalAnswered)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if bgRevealed {
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.12, blue: 0.30), Color(red: 0.10, green: 0.08, blue: 0.22)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea().transition(.opacity)
            }

            if confettiVisible { ResultConfettiView().allowsHitTesting(false) }

            VStack(spacing: 18) {
                Spacer()

                // モンスター
                if let stage = extraVM.selectedStage {
                    KennyCharacterView(
                        appearance: .forFloor(stage.floor),
                        size: 70, isDefeated: true
                    )
                    .opacity(monsterOpacity)
                    Text(Monster.forFloor(stage.floor).name)
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(monsterOpacity)
                }

                // Phase 1: 正解数 ドーン
                if phase >= 1 {
                    VStack(spacing: 4) {
                        Text("\(extraVM.correctCount)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                            .scaleEffect(scoreScale).opacity(scoreOpacity)
                        Text("extra_correct_count")
                            .font(.zenMaru(20, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(scoreOpacity)
                    }
                }

                // Phase 2: 星
                if phase >= 2 && extraVM.totalAnswered > 0 {
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < starsRevealed ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundStyle(i < starsRevealed ? .yellow : .white.opacity(0.3))
                                .shadow(color: i < starsRevealed ? .yellow.opacity(0.5) : .clear, radius: 4)
                                .scaleEffect(i < starsRevealed ? 1.0 : 0.6)
                        }
                    }
                }

                // Phase 3: ベスト記録
                if phase >= 3 && extraVM.isBestScore {
                    Text("extra_best_record")
                        .font(.zenMaru(22, weight: .black))
                        .foregroundColor(accentGold)
                        .shadow(color: accentGold.opacity(0.6), radius: 12)
                        .scaleEffect(recordScale).opacity(recordOpacity)
                }

                Spacer()

                // Phase 4: ボタン
                if phase >= 4 {
                    VStack(spacing: 10) {
                        Button {
                            HapticsManager.tap()
                            extraVM.startBattle()
                            gameVM.screen = .extraBattle
                        } label: {
                            Text("extra_retry").font(.zenMaru(20, weight: .bold))
                                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                                .background(Color.red).clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .red.opacity(0.4), radius: 10, y: 4)
                        }
                        Button {
                            HapticsManager.tap()
                            gameVM.screen = .extraSelect
                        } label: {
                            Text("extra_reselect").font(.zenMaru(16, weight: .bold))
                                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 48)
                                .background(Color.white.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1))
                        }
                        Button {
                            HapticsManager.tap()
                            gameVM.screen = .island
                        } label: {
                            Text("extra_to_title").font(.zenMaru(14, weight: .bold)).foregroundColor(.white.opacity(0.5))
                        }.padding(.top, 4)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 32)
                    .opacity(buttonOpacity)
                }
            }
            .offset(x: shakeOffset)

            Color.white.ignoresSafeArea().opacity(showFlash ? 1 : 0).allowsHitTesting(false)
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        // 0s: 背景 + モンスター
        showFlash = true
        at(0.15) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false; bgRevealed = true } }
        withAnimation(.easeOut(duration: 0.5)) { monsterOpacity = 1 }
        SoundManager.shared.playBossAppear()
        HapticsManager.incorrect()

        // 1.0s: 正解数 ドドーン
        at(1.0) { phase = 1
            showFlash = true
            at(0.1) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false } }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { scoreScale = 1.0; scoreOpacity = 1 }
            SoundManager.shared.playBossVictory()
            HapticsManager.incorrect()
            runShake()
            if extraVM.isBestScore { confettiVisible = true }
        }

        // 2.0s: 星
        at(2.0) { phase = 2
            for i in 0..<starCount {
                at(Double(i) * 0.25) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { starsRevealed = i + 1 }
                    SoundManager.shared.playCorrect(); HapticsManager.tap()
                }
            }
        }

        // 3.0s: ベスト記録
        at(3.0) { phase = 3
            if extraVM.isBestScore {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { recordScale = 1.0; recordOpacity = 1 }
                HapticsManager.tap()
            }
        }

        // 3.8s: ボタン
        at(3.8) { phase = 4; SoundManager.shared.playResult(); withAnimation(.easeOut(duration: 0.4)) { buttonOpacity = 1 } }
    }

    private func at(_ d: Double, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + d, execute: action)
    }
    private func runShake() {
        for (o, d) in [(CGFloat(10),0.0),(-10,0.04),(8,0.08),(-6,0.12),(4,0.16),(0,0.20)] as [(CGFloat, Double)] {
            at(d) { withAnimation(.linear(duration: 0.03)) { shakeOffset = o } }
        }
    }
}
