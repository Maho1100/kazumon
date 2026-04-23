import SwiftUI

/// ビフォーテスト結果 — ヒカキン流
struct BeforeTestResultView: View {
    let score: Int
    let total: Int
    let avgTime: Double
    let onDone: () -> Void

    private var percent: Int { total > 0 ? Int(Double(score) / Double(total) * 100) : 0 }
    private var isYoung: Bool { DataStore.loadAgeGroup().isYoungMode }

    @State private var phase = 0
    @State private var bgRevealed = false
    @State private var showFlash = false
    @State private var titleScale: CGFloat = 3.0
    @State private var titleOpacity: Double = 0
    @State private var starsRevealed = 0
    @State private var scoreScale: CGFloat = 3.0
    @State private var scoreOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    @State private var speedOpacity: Double = 0
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
                    colors: [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.1)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea().transition(.opacity)
            }
            if confettiVisible { ResultConfettiView().allowsHitTesting(false) }

            VStack(spacing: 18) {
                Spacer()

                // キャラ
                if phase >= 1 {
                    KennyCharacterView(
                        appearance: CharacterAppearanceFactory.appearance(for: 1),
                        size: 80
                    )
                    .scaleEffect(charScale).opacity(charOpacity).offset(y: charFloat)
                }

                // タイトル
                Text(isYoung ? "before_test_young_title" : "before_test_older_title")
                    .font(.zenMaru(36, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                    .scaleEffect(titleScale).opacity(titleOpacity)

                // 星（youngモード）
                if isYoung && phase >= 2 {
                    HStack(spacing: 8) {
                        ForEach(0..<total, id: \.self) { i in
                            Image(systemName: i < starsRevealed ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundStyle(i < starsRevealed ? .yellow : .white.opacity(0.3))
                                .shadow(color: i < starsRevealed ? .yellow.opacity(0.5) : .clear, radius: 4)
                                .scaleEffect(i < starsRevealed ? 1.0 : 0.6)
                        }
                    }
                }

                // スコア%（olderモード）
                if !isYoung && phase >= 2 {
                    Text("\(percent)%")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .scaleEffect(scoreScale).opacity(scoreOpacity)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.2))
                            RoundedRectangle(cornerRadius: 8).fill(barColor)
                                .frame(width: geo.size.width * max(0, barAnimated / 100.0))
                        }
                    }
                    .frame(height: 18).padding(.horizontal, 40)
                }

                // メッセージ
                if phase >= 3 {
                    Text(youngMessage)
                        .font(.zenMaru(20, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(messageOpacity)

                    Text(avgTime > 0 && avgTime <= 5.0
                         ? NSLocalizedString("before_test_speed_fast", comment: "")
                         : NSLocalizedString("before_test_speed_good", comment: ""))
                        .font(.zenMaru(16, weight: .bold))
                        .foregroundStyle(.yellow)
                        .opacity(speedOpacity)
                }

                Spacer()

                // ボタン
                if phase >= 4 {
                    Button {
                        HapticsManager.tap()
                        onDone()
                    } label: {
                        Text(isYoung ? "before_test_young_done" : "before_test_older_done")
                            .font(.zenMaru(22, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 260, height: 60)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.green))
                            .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                    }
                    .opacity(buttonOpacity)
                }

                Spacer().frame(height: 50)
            }
            .offset(x: shakeOffset)

            Color.white.ignoresSafeArea().opacity(showFlash ? 1 : 0).allowsHitTesting(false)
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        // 0s: タイトル + 背景
        showFlash = true
        at(0.15) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false; bgRevealed = true } }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { titleScale = 1.0; titleOpacity = 1 }
        SoundManager.shared.playBossAppear()
        HapticsManager.incorrect()

        // 0.8s: キャラ
        at(0.8) {
            phase = 1
            withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) { charScale = 1.0; charOpacity = 1 }
            HapticsManager.tap()
            at(0.5) { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { charFloat = -8 } }
        }

        // 1.5s: スコア/星 ドーン
        at(1.5) {
            phase = 2
            showFlash = true
            at(0.1) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false } }
            if isYoung {
                for i in 0..<score {
                    at(Double(i) * 0.25) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { starsRevealed = i + 1 }
                        SoundManager.shared.playCorrect(); HapticsManager.tap()
                    }
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { scoreScale = 1.0; scoreOpacity = 1 }
                withAnimation(.easeOut(duration: 1.0).delay(0.3)) { barAnimated = Double(percent) }
            }
            SoundManager.shared.playBossVictory()
            HapticsManager.incorrect()
            runShake()
            confettiVisible = true
        }

        // 3.0s: メッセージ
        at(3.0) { phase = 3; withAnimation(.easeOut(duration: 0.4)) { messageOpacity = 1 }
            at(0.3) { withAnimation(.easeOut(duration: 0.3)) { speedOpacity = 1 } }
        }

        // 3.8s: ボタン
        at(3.8) { phase = 4; SoundManager.shared.playResult(); withAnimation(.easeOut(duration: 0.4)) { buttonOpacity = 1 } }
    }

    private func at(_ d: Double, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + d, execute: action)
    }
    private func runShake() {
        for (o, d) in [(CGFloat(8),0.0),(-8,0.04),(6,0.08),(-4,0.12),(0,0.16)] as [(CGFloat, Double)] {
            at(d) { withAnimation(.linear(duration: 0.03)) { shakeOffset = o } }
        }
    }

    private var youngMessage: String {
        switch score {
        case 0...2: return NSLocalizedString("before_test_msg_low", comment: "")
        case 3...5: return NSLocalizedString("before_test_msg_mid", comment: "")
        case 6...7: return NSLocalizedString("before_test_msg_high", comment: "")
        default:    return NSLocalizedString("before_test_msg_perfect", comment: "")
        }
    }
    private var barColor: LinearGradient {
        if percent <= 50 { return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing) }
        else if percent <= 80 { return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing) }
        else { return LinearGradient(colors: [.yellow, .green], startPoint: .leading, endPoint: .trailing) }
    }
}
