import SwiftUI

// MARK: - 降ってくる数字

struct FallingNumber: Identifiable {
    let id = UUID()
    let value: Int
    let x: CGFloat       // 0〜1 相対X
    var startTime: Date = Date()
}

// MARK: - ランダムイベント種別

enum RandomEventType: CaseIterable {
    case shootingStar
    case enemyRun
    case questionBubble
}

// MARK: - AmbientEventsView

struct AmbientEventsView: View {
    let screenSize: CGSize

    // 数字
    @State private var fallingNumbers: [FallingNumber] = []
    @State private var numberTimer: Timer?

    // ランダムイベント
    @State private var randomEventTimer: Timer?
    @State private var showShootingStar = false
    @State private var starOffset: CGFloat = -100
    @State private var starY: CGFloat = 80
    @State private var showEnemyRun = false
    @State private var enemyX: CGFloat = -60
    @State private var showQuestionBubble = false

    var body: some View {
        ZStack {
            // ── 降る数字 ──
            ForEach(fallingNumbers) { num in
                FallingNumberView(number: num, screenWidth: screenSize.width, screenHeight: screenSize.height)
            }

            // ── 流れ星 ──
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(.yellow)
                .opacity(showShootingStar ? 1 : 0)
                .offset(x: starOffset, y: starY)

            // ── 逃げる敵 ──
            Text("👾")
                .font(.system(size: 28))
                .opacity(showEnemyRun ? 1 : 0)
                .offset(x: enemyX, y: screenSize.height * 0.55)

            // ── ？吹き出し（キャラ頭上に表示、親ビューで位置調整） ──
            Text("?")
                .font(.zenMaru(24, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                )
                .opacity(showQuestionBubble ? 1 : 0)
                .offset(y: screenSize.height * 0.38)
        }
        .allowsHitTesting(false)
        .onAppear { startTimers() }
        .onDisappear { stopTimers() }
    }

    // MARK: - タイマー制御

    private func startTimers() {
        // 数字: 10〜20秒ごと
        numberTimer = Timer.scheduledTimer(withTimeInterval: 14, repeats: true) { _ in
            // 10%確率でスキップ
            guard Int.random(in: 0..<10) > 0 else { return }
            spawnNumbers()
        }

        // ランダムイベント: 30秒ごと、10%確率
        randomEventTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            guard Int.random(in: 0..<10) == 0 else { return }
            triggerRandomEvent()
        }
    }

    private func stopTimers() {
        numberTimer?.invalidate()
        numberTimer = nil
        randomEventTimer?.invalidate()
        randomEventTimer = nil
    }

    // MARK: - 数字を降らせる

    private func spawnNumbers() {
        let count = Int.random(in: 2...3)
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                let num = FallingNumber(
                    value: Int.random(in: 1...9),
                    x: CGFloat.random(in: 0.1...0.9)
                )
                fallingNumbers.append(num)
                // 4秒後に削除
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    fallingNumbers.removeAll { $0.id == num.id }
                }
            }
        }
    }

    // MARK: - ランダムイベント

    private func triggerRandomEvent() {
        let event = RandomEventType.allCases.randomElement() ?? .shootingStar
        switch event {
        case .shootingStar:
            starY = CGFloat.random(in: 40...120)
            starOffset = -100
            showShootingStar = true
            withAnimation(.easeIn(duration: 1.2)) {
                starOffset = screenSize.width + 100
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                showShootingStar = false
                starOffset = -100
            }

        case .enemyRun:
            enemyX = -60
            showEnemyRun = true
            withAnimation(.easeIn(duration: 1.5)) {
                enemyX = screenSize.width + 60
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                showEnemyRun = false
                enemyX = -60
            }

        case .questionBubble:
            showQuestionBubble = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showQuestionBubble = false
                }
            }
        }
    }
}

// MARK: - 個別の降る数字ビュー

private struct FallingNumberView: View {
    let number: FallingNumber
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    @State private var offsetY: CGFloat = -40
    @State private var opacity: Double = 1.0

    var body: some View {
        Text("\(number.value)")
            .font(.zenMaru(28, weight: .bold))
            .foregroundStyle(
                [Color.red, .orange, .green, .blue, .purple, .pink].randomElement()!
                    .opacity(0.7)
            )
            .position(x: number.x * screenWidth, y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 3.5)) {
                    offsetY = screenHeight + 40
                    opacity = 0
                }
            }
    }
}
