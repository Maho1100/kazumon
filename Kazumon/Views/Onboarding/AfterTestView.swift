import SwiftUI
import Combine

/// アフターテスト — 公文Aレベル準拠の30問習熟度テスト
struct AfterTestView: View {
    let onComplete: (Int, Int) -> Void  // (score, total)

    static let totalQuestions = 30
    static let timeLimit: Double = 8.0
    static let passingScore = 24  // 80%

    static let problems: [(a: Int, op: String, b: Int, answer: Int)] = [
        // たし算基礎（5問）
        (3,"＋",4,7), (5,"＋",2,7), (6,"＋",3,9), (4,"＋",5,9), (7,"＋",2,9),
        // くり上がり（8問）
        (8,"＋",5,13), (7,"＋",6,13), (9,"＋",4,13), (8,"＋",6,14),
        (9,"＋",5,14), (7,"＋",8,15), (8,"＋",8,16), (9,"＋",9,18),
        // ひき算基礎（5問）
        (9,"－",3,6), (8,"－",4,4), (10,"－",3,7), (7,"－",5,2), (10,"－",4,6),
        // くり下がり易（6問）
        (13,"－",5,8), (12,"－",4,8), (14,"－",6,8), (11,"－",3,8), (15,"－",7,8), (13,"－",4,9),
        // くり下がり難（6問）
        (11,"－",8,3), (12,"－",9,3), (13,"－",8,5), (14,"－",9,5), (15,"－",8,7), (16,"－",9,7),
    ]

    @State private var showIntro = true
    @State private var introLine1 = false
    @State private var introLine2 = false

    @State private var questionIndex = 0
    @State private var score = 0
    @State private var selectedAnswer: Int? = nil
    @State private var problemStartTime = Date()
    @State private var currentChoices: [Int] = []
    @State private var showProblem = false
    @State private var characterBounce: CGFloat = 0
    @State private var characterShake: CGFloat = 0
    @State private var showCharacters = false

    @State private var timerRemaining: Double = 8.0
    @State private var timerTotal: Double = 8.0
    @State private var timerCancellable: AnyCancellable?

    @State private var showFinale = false

    private var current: (a: Int, op: String, b: Int, answer: Int) {
        Self.problems[questionIndex]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.8, blue: 0.3),
                    Color(red: 1.0, green: 0.65, blue: 0.2)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if showIntro {
                introView
            } else {
                testView
            }

            // やめるボタン（ZStack最上層）
            if !showIntro && !showFinale {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            stopTimer()
                            onComplete(score, Self.totalQuestions)
                        } label: {
                            Text("battle_quit_button")
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 12)
                    Spacer()
                }
                .zIndex(100)
            }

            if showFinale {
                AfterTestConfettiView().allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) { introLine1 = true }
            withAnimation(.easeIn(duration: 0.5).delay(1.0)) { introLine2 = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showIntro = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showCharacters = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        loadProblem()
                        withAnimation(.easeOut(duration: 0.3)) { showProblem = true }
                    }
                }
            }
        }
    }

    // MARK: - イントロ

    private var introView: some View {
        VStack(spacing: 20) {
            Spacer()
            KennyCharacterView(
                appearance: CharacterAppearanceFactory.appearance(for: 1),
                size: 100, playEntrance: true
            )
            Text("after_test_intro_1")
                .font(.zenMaru(24, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .opacity(introLine1 ? 1 : 0)
            Text("after_test_intro_2")
                .font(.zenMaru(18, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .opacity(introLine2 ? 1 : 0)
            Spacer()
        }
    }

    // MARK: - テスト画面

    private var testView: some View {
        VStack(spacing: 12) {
            // 進捗バー + カウント
            Spacer().frame(height: 50)
            VStack(spacing: 4) {
                ProgressView(value: Double(questionIndex), total: Double(Self.totalQuestions))
                    .tint(.orange)
                    .scaleEffect(y: 1.5)
                    .padding(.horizontal, 32)
                Text("\(questionIndex + 1) / \(Self.totalQuestions)")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // タイマー
            if showProblem && !showFinale {
                TimerBarView(remaining: timerRemaining, total: timerTotal)
                    .padding(.horizontal, 20)
            }

            // キャラクター
            HStack(alignment: .center, spacing: 32) {
                KennyCharacterView(
                    appearance: CharacterAppearanceFactory.appearance(for: 1),
                    size: 70
                )
                .offset(y: characterBounce)
                .offset(x: characterShake)

                KennyCharacterView(appearance: .slime, size: 70)
            }
            .frame(height: 120)
            .opacity(showCharacters ? 1 : 0)
            .offset(y: showCharacters ? 0 : 40)

            Spacer()

            // 問題
            if showProblem && !showFinale {
                Text("\(current.a) \(current.op) \(current.b) ＝ ?")
                    .font(.zenMaru(42, weight: .black))
                    .foregroundStyle(.primary)
            }

            Spacer()

            // 選択肢
            if currentChoices.count >= 4 && showProblem && !showFinale {
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        choiceButton(currentChoices[0])
                        choiceButton(currentChoices[1])
                    }
                    HStack(spacing: 12) {
                        choiceButton(currentChoices[2])
                        choiceButton(currentChoices[3])
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer().frame(height: 40)
        }
    }

    // MARK: - ロジック

    private func loadProblem() {
        currentChoices = generateChoices(for: current.answer)
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
        timerTotal = Self.timeLimit
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
        advanceOrFinish()
    }

    private func shakeCharacter() {
        let steps: [(CGFloat, Double)] = [(-6, 0), (6, 0.05), (-4, 0.1), (4, 0.15), (0, 0.2)]
        for (offset, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.04)) { characterShake = offset }
            }
        }
    }

    private func advanceOrFinish() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            questionIndex += 1
            if questionIndex < Self.totalQuestions {
                withAnimation(.easeOut(duration: 0.12)) { showProblem = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    loadProblem()
                    withAnimation(.easeOut(duration: 0.15)) { showProblem = true }
                }
            } else { finishTest() }
        }
    }

    private func finishTest() {
        stopTimer()
        showFinale = true
        SoundManager.shared.stopBGM()
        SoundManager.shared.playBossVictory()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onComplete(score, Self.totalQuestions)
        }
    }

    // MARK: - 選択肢ボタン

    @ViewBuilder
    private func choiceButton(_ number: Int) -> some View {
        let isSelected = selectedAnswer == number
        let isCorrect = number == current.answer

        Button {
            guard selectedAnswer == nil else { return }
            HapticsManager.tap()
            selectedAnswer = number
            stopTimer()
            let elapsed = Date().timeIntervalSince(problemStartTime)

            SupabaseService.shared.logAnswer(
                operatorSymbol: current.op,
                a: current.a, b: current.b,
                correctAnswer: current.answer, userAnswer: number,
                isCorrect: isCorrect,
                responseTimeMs: Int(elapsed * 1000),
                attemptCount: questionIndex + 1
            )

            if isCorrect {
                score += 1
                SoundManager.shared.playCorrect()
                HapticsManager.correct()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { characterBounce = -16 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { characterBounce = 0 }
                }
            } else {
                SoundManager.shared.playIncorrect()
                HapticsManager.incorrect()
                shakeCharacter()
            }
            advanceOrFinish()
        } label: {
            Text("\(number)")
                .font(.zenMaru(28, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    isSelected ? (isCorrect ? Color.green : Color.red)
                    : (selectedAnswer != nil && isCorrect ? Color.green : Color.blue.opacity(0.85))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
        }
        .disabled(selectedAnswer != nil)
    }
}

// MARK: - 紙吹雪

private struct AfterTestConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, color: Color)] = []
    private let colors: [Color] = [.yellow, Color(red: 1, green: 0.85, blue: 0), .orange, .white, .green, .cyan]

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { p in
                AfterTestConfettiParticle(color: p.color).offset(x: p.x)
            }
        }
        .onAppear {
            particles = (0..<30).map { i in (id: i, x: CGFloat.random(in: -200...200), color: colors.randomElement()!) }
        }
    }
}

private struct AfterTestConfettiParticle: View {
    let color: Color
    @State private var yOffset: CGFloat = -120
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: CGFloat.random(in: 6...10), height: CGFloat.random(in: 6...10))
            .offset(y: yOffset).rotationEffect(.degrees(rotation)).opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: Double.random(in: 2.5...5))) {
                    yOffset = CGFloat.random(in: 500...900); rotation = Double.random(in: 360...1080); opacity = 0
                }
            }
    }
}
