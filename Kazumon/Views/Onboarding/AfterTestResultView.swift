import SwiftUI

/// アフターテスト結果 — ヒカキン流
struct AfterTestResultView: View {
    let afterScore: Int
    let afterTotal: Int
    let onPass: () -> Void
    let onRetry: () -> Void
    let onHome: () -> Void

    private let beforeScore = DataStore.loadBeforeTestScore()
    private let beforeTotal = 8
    private var hasBefore: Bool { DataStore.hasCompletedBeforeTest() }
    private var afterPercent: Int { afterTotal > 0 ? Int(Double(afterScore) / Double(afterTotal) * 100) : 0 }
    private var beforePercent: Int { beforeTotal > 0 ? Int(Double(beforeScore) / Double(beforeTotal) * 100) : 0 }
    private var passed: Bool { afterScore >= AfterTestView.passingScore }

    @State private var phase = 0
    @State private var bgRevealed = false
    @State private var showFlash = false
    @State private var titleScale: CGFloat = 3.0
    @State private var titleOpacity: Double = 0
    @State private var scoreScale: CGFloat = 3.0
    @State private var scoreOpacity: Double = 0
    @State private var passScale: CGFloat = 4.0
    @State private var passOpacity: Double = 0
    @State private var comparisonOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiVisible = false
    @State private var shakeOffset: CGFloat = 0
    @State private var barAnimated: Double = 0
    @State private var charScale: CGFloat = 0.3
    @State private var charOpacity: Double = 0
    @State private var charFloat: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if bgRevealed {
                LinearGradient(
                    colors: passed
                        ? [Color(red: 0.95, green: 0.8, blue: 0.3), Color(red: 1.0, green: 0.65, blue: 0.2)]
                        : [Color(red: 0.35, green: 0.30, blue: 0.55), Color(red: 0.25, green: 0.20, blue: 0.45)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea().transition(.opacity)
            }
            if confettiVisible { ResultConfettiView().allowsHitTesting(false) }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer().frame(height: 40)

                    // タイトル
                    Text("after_test_result_title")
                        .font(.zenMaru(26, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        .scaleEffect(titleScale).opacity(titleOpacity)

                    // キャラ
                    if phase >= 1 {
                        KennyCharacterView(
                            appearance: CharacterAppearanceFactory.appearance(for: 1),
                            size: 80
                        )
                        .scaleEffect(charScale).opacity(charOpacity).offset(y: charFloat)
                    }

                    // スコア ドーン
                    if phase >= 2 {
                        Text("\(afterScore) / \(afterTotal)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .scaleEffect(scoreScale).opacity(scoreOpacity)

                        Text("\(afterPercent)%")
                            .font(.zenMaru(20, weight: .bold))
                            .foregroundStyle(.yellow)
                            .opacity(scoreOpacity)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.2))
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(passed
                                        ? LinearGradient(colors: [.yellow, .green], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * max(0, barAnimated / 100.0))
                            }
                        }
                        .frame(height: 18).padding(.horizontal, 40)
                    }

                    // 合格/不合格 ドドーン
                    if phase >= 3 {
                        Text(passed ? "after_test_pass" : "after_test_fail")
                            .font(.zenMaru(passed ? 36 : 24, weight: .black))
                            .foregroundStyle(passed ? .yellow : .white.opacity(0.9))
                            .shadow(color: passed ? .orange.opacity(0.6) : .clear, radius: 12)
                            .scaleEffect(passScale).opacity(passOpacity)
                    }

                    // ビフォー比較
                    if phase >= 4 && hasBefore {
                        VStack(spacing: 12) {
                            Text("after_test_comparison_title")
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.7))
                            HStack(spacing: 20) {
                                VStack(spacing: 4) {
                                    Text("after_test_before_label").font(.zenMaru(12, weight: .bold)).foregroundStyle(.white.opacity(0.6))
                                    Text("\(beforeScore)/\(beforeTotal)").font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(.white.opacity(0.6))
                                    Text("\(beforePercent)%").font(.zenMaru(14, weight: .bold)).foregroundStyle(.white.opacity(0.5))
                                }.frame(maxWidth: .infinity)
                                Image(systemName: "arrow.right").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                                VStack(spacing: 4) {
                                    Text("after_test_after_label").font(.zenMaru(12, weight: .bold)).foregroundStyle(.yellow)
                                    Text("\(afterScore)/\(afterTotal)").font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(.yellow)
                                    Text("\(afterPercent)%").font(.zenMaru(14, weight: .bold)).foregroundStyle(.yellow.opacity(0.8))
                                }.frame(maxWidth: .infinity)
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.15)))
                        .padding(.horizontal, 24)
                        .opacity(comparisonOpacity)
                    }

                    Spacer().frame(height: 16)

                    // ボタン
                    if phase >= 5 {
                        VStack(spacing: 12) {
                            if passed {
                                Button { HapticsManager.tap(); onPass() } label: {
                                    HStack(spacing: 8) {
                                        Text("after_test_certificate_button").font(.zenMaru(20, weight: .black))
                                    }
                                    .foregroundColor(.white).frame(width: 280, height: 60)
                                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.green))
                                    .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                                }
                            } else {
                                Button { HapticsManager.tap(); onRetry() } label: {
                                    Text("after_test_retry_button").font(.zenMaru(20, weight: .black))
                                        .foregroundColor(.white).frame(width: 280, height: 60)
                                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.orange))
                                        .shadow(color: .orange.opacity(0.4), radius: 8, y: 4)
                                }
                                Button { HapticsManager.tap(); onHome() } label: {
                                    Text("after_test_home_button").font(.zenMaru(15, weight: .bold)).foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .opacity(buttonOpacity)
                    }

                    Spacer().frame(height: 50)
                }
            }
            .offset(x: shakeOffset)

            Color.white.ignoresSafeArea().opacity(showFlash ? 1 : 0).allowsHitTesting(false)
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        // 0s: タイトル
        showFlash = true
        at(0.15) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false; bgRevealed = true } }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { titleScale = 1.0; titleOpacity = 1 }
        SoundManager.shared.playBossAppear()
        HapticsManager.incorrect()

        // 0.8s: キャラ
        at(0.8) { phase = 1
            withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) { charScale = 1.0; charOpacity = 1 }
            HapticsManager.tap()
            at(0.5) { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { charFloat = -8 } }
        }

        // 1.5s: スコア
        at(1.5) { phase = 2
            withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { scoreScale = 1.0; scoreOpacity = 1 }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) { barAnimated = Double(afterPercent) }
            SoundManager.shared.playCorrect(); HapticsManager.tap()
        }

        // 2.5s: 合格/不合格 ドドーン
        at(2.5) { phase = 3
            showFlash = true
            at(0.1) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false } }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { passScale = 1.0; passOpacity = 1 }
            if passed { SoundManager.shared.playBossVictory(); confettiVisible = true }
            else { SoundManager.shared.playDefeat() }
            HapticsManager.incorrect(); runShake()
        }

        // 3.5s: 比較
        at(3.5) { phase = 4; withAnimation(.easeOut(duration: 0.5)) { comparisonOpacity = 1 } }

        // 4.3s: ボタン
        at(4.3) { phase = 5; SoundManager.shared.playResult(); withAnimation(.easeOut(duration: 0.4)) { buttonOpacity = 1 } }
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
