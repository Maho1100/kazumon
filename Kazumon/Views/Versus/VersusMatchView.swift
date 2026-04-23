import SwiftUI
import Combine

struct VersusMatchView: View {
    let bgmName: String
    let onComplete: (Int, Int) -> Void

    @State private var questionIndex = 0
    @State private var playerScore = 0
    @State private var currentProblem = Problem.generateMastery(phase: .addition)
    @State private var currentChoices: [Int] = []
    @State private var selectedAnswer: Int? = nil
    @State private var problemStartTime = Date()

    @State private var timerRemaining: Double = 8.0
    @State private var timerTotal: Double = 8.0
    @State private var timerCancellable: AnyCancellable?

    @State private var showProblem = false
    @State private var characterBounce: CGFloat = 0
    @State private var characterShake: CGFloat = 0
    @State private var showContent = false
    @State private var buttonShake: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.40, blue: 0.80),
                    Color(red: 0.30, green: 0.25, blue: 0.65)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer().frame(height: 50)

                // ヘッダー
                HStack {
                    Text("versus_match_title")
                        .font(.zenMaru(20, weight: .black))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(questionIndex + 1) / \(VersusConfig.questionCount)")
                        .font(.zenMaru(16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)

                // タイマー
                if showProblem {
                    TimerBarView(remaining: timerRemaining, total: timerTotal)
                        .padding(.horizontal, 20)
                }

                // キャラクター（1.3倍）
                HStack(alignment: .center, spacing: 24) {
                    VStack(spacing: 4) {
                        KennyCharacterView(
                            appearance: CharacterAppearanceFactory.appearance(for: 10),
                            size: 91
                        )
                        .offset(y: characterBounce)
                        .offset(x: characterShake)
                        Text(DataStore.loadPlayerData().playerName)
                            .font(.zenMaru(13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("VS")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.4), radius: 8)

                    VStack(spacing: 4) {
                        Image("awaken_character")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                        Text("versus_opponent_name")
                            .font(.zenMaru(13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .frame(height: 140)

                // スコア
                HStack(spacing: 40) {
                    Text("\(playerScore)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("--")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("?")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                // 問題（カード背景付き）
                if showProblem {
                    Text("\(currentProblem.a) \(currentProblem.operatorSymbol) \(currentProblem.b) = ?")
                        .font(.zenMaru(52, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                }

                Spacer()

                // 選択肢（大きめ）
                if currentChoices.count >= 4 && showProblem {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            choiceButton(currentChoices[0])
                            choiceButton(currentChoices[1])
                        }
                        HStack(spacing: 12) {
                            choiceButton(currentChoices[2])
                            choiceButton(currentChoices[3])
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(x: buttonShake)
                }

                Spacer().frame(height: 36)
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            SoundManager.shared.playBGM(bgmName)
            withAnimation(.easeOut(duration: 0.4)) { showContent = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadProblem()
                withAnimation(.easeOut(duration: 0.3)) { showProblem = true }
            }
        }
    }

    // MARK: - ロジック

    private func loadProblem() {
        let phases: [MasteryPhase] = [.addition, .carryAddition, .subtraction, .borrowSubtraction]
        currentProblem = Problem.generateMastery(phase: phases.randomElement()!)
        currentChoices = generateChoices(for: currentProblem.answer)
        selectedAnswer = nil
        problemStartTime = Date()
        startTimer()
    }

    private func generateChoices(for answer: Int) -> [Int] {
        var set = Set<Int>()
        set.insert(answer)
        var attempts = 0
        while set.count < 4 && attempts < 50 {
            let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
            let wrong = answer + offset
            if wrong >= 0 && wrong != answer { set.insert(wrong) }
            attempts += 1
        }
        var idx = 1
        while set.count < 4 {
            let c = answer + idx
            if c >= 0 && !set.contains(c) { set.insert(c) }
            idx += 1
        }
        return Array(set).shuffled()
    }

    private func startTimer() {
        timerCancellable?.cancel()
        timerTotal = VersusConfig.timeLimit
        timerRemaining = timerTotal
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                timerRemaining -= 0.05
                if timerRemaining <= 0 {
                    timerRemaining = 0
                    timerCancellable?.cancel()
                    handleTimeUp()
                }
            }
    }

    private func stopTimer() { timerCancellable?.cancel(); timerCancellable = nil }

    private func handleTimeUp() {
        guard selectedAnswer == nil else { return }
        selectedAnswer = -1
        SoundManager.shared.playIncorrect()
        HapticsManager.incorrect()
        shakeCharacter()
        shakeButtons()
        advance()
    }

    private func shakeCharacter() {
        let steps: [(CGFloat, Double)] = [(-8, 0), (8, 0.05), (-6, 0.1), (6, 0.15), (0, 0.2)]
        for (offset, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.04)) { characterShake = offset }
            }
        }
    }

    private func shakeButtons() {
        let steps: [(CGFloat, Double)] = [(-6, 0), (6, 0.04), (-4, 0.08), (4, 0.12), (0, 0.16)]
        for (offset, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.03)) { buttonShake = offset }
            }
        }
    }

    private func advance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            questionIndex += 1
            if questionIndex < VersusConfig.questionCount {
                withAnimation(.easeOut(duration: 0.12)) { showProblem = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    loadProblem()
                    withAnimation(.easeOut(duration: 0.15)) { showProblem = true }
                }
            } else {
                stopTimer()
                SoundManager.shared.fadeBGM(duration: 0.5)
                // CPU: 60〜80%の正解率
                let cpuScore = Int.random(in: (VersusConfig.questionCount * 6 / 10)...(VersusConfig.questionCount * 8 / 10))
                onComplete(playerScore, cpuScore)
            }
        }
    }

    // MARK: - 選択肢ボタン

    @ViewBuilder
    private func choiceButton(_ number: Int) -> some View {
        let isSelected = selectedAnswer == number
        let isCorrect = number == currentProblem.answer

        Button {
            guard selectedAnswer == nil else { return }
            HapticsManager.tap()
            selectedAnswer = number
            stopTimer()

            if isCorrect {
                playerScore += 1
                SoundManager.shared.playCorrect()
                HapticsManager.correct()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { characterBounce = -20 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { characterBounce = 0 }
                }
            } else {
                SoundManager.shared.playIncorrect()
                HapticsManager.incorrect()
                shakeCharacter()
                shakeButtons()
            }
            advance()
        } label: {
            Text("\(number)")
                .font(.zenMaru(32, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .background(
                    isSelected
                        ? (isCorrect ? Color.green : Color.red)
                        : (selectedAnswer != nil && isCorrect ? Color.green : Color(red: 0.5, green: 0.45, blue: 0.85))
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
        }
        .disabled(selectedAnswer != nil)
    }
}
