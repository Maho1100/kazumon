import SwiftUI
import Combine

// MARK: - 難易度レベル

enum BeforeTestLevel: Int, CaseIterable {
    case level1 = 1, level2, level3, level4
    case level5, level6, level7, level8
}

struct BeforeTestView: View {
    let onComplete: (Int, Int, Int, Double) -> Void  // (score, total, reachedLevel, avgTime)

    static let totalQuestions = 8

    // MARK: - 問題バンク

    static let problemBank: [BeforeTestLevel: [(a: Int, op: String, b: Int, answer: Int)]] = [
        .level1: [(1,"＋",1,2), (1,"＋",2,3), (2,"＋",1,3), (1,"＋",3,4),
                  (3,"＋",1,4), (2,"＋",2,4), (1,"＋",4,5), (4,"＋",1,5),
                  (2,"＋",3,5), (3,"＋",2,5)],
        .level2: [(2,"＋",2,4), (3,"＋",1,4), (2,"＋",3,5), (3,"＋",2,5)],
        .level3: [(4,"＋",3,7), (5,"＋",2,7), (3,"＋",4,7), (4,"＋",2,6)],
        .level4: [(6,"＋",4,10), (7,"＋",3,10), (5,"＋",4,9), (6,"＋",3,9)],
        .level5: [(8,"＋",5,13), (7,"＋",6,13), (9,"＋",4,13), (8,"＋",6,14)],
        .level6: [(9,"－",1,8), (8,"－",2,6), (10,"－",3,7), (7,"－",4,3)],
        .level7: [(13,"－",5,8), (12,"－",7,5), (14,"－",6,8), (11,"－",4,7)],
        .level8: [(15,"－",8,7), (14,"－",6,8), (16,"－",9,7), (13,"－",6,7)],
    ]

    // MARK: - レベル別制限時間

    static let timeLimits: [BeforeTestLevel: Double] = [
        .level1: 10.0, .level2: 9.0, .level3: 8.0, .level4: 7.0,
        .level5: 6.0,  .level6: 9.0, .level7: 7.0, .level8: 6.0,
    ]

    /// 4さいモード: タイマーなし・レベル変更なし
    private var isYoung4: Bool { DataStore.loadAgeGroup() == .young4 }

    // MARK: - State

    @State private var currentLevel: BeforeTestLevel = .level1
    @State private var questionIndex = 0
    @State private var score = 0
    @State private var maxReachedLevel = 1
    @State private var usedKeys = Set<String>()
    @State private var answerTimes: [Double] = []

    @State private var currentProblem: (a: Int, op: String, b: Int, answer: Int) = (1,"＋",1,2)
    @State private var selectedAnswer: Int? = nil
    @State private var problemStartTime = Date()
    @State private var currentChoices: [Int] = []
    @State private var stars: [Bool] = Array(repeating: false, count: 8)
    @State private var showProblem = false
    @State private var characterBounce: CGFloat = 0
    @State private var characterShake: CGFloat = 0
    @State private var showCharacters = false

    // タイマー
    @State private var timerRemaining: Double = 10.0
    @State private var timerTotal: Double = 10.0
    @State private var timerCancellable: AnyCancellable?

    // 完了演出
    @State private var showFinale = false

    // MARK: - 適応ロジック

    private func pickProblem() -> (a: Int, op: String, b: Int, answer: Int) {
        let bank = Self.problemBank[currentLevel] ?? Self.problemBank[.level1]!
        let unused = bank.filter { !usedKeys.contains("\($0.a)\($0.op)\($0.b)") }
        let problem = unused.randomElement() ?? bank.randomElement()!
        usedKeys.insert("\(problem.a)\(problem.op)\(problem.b)")
        return problem
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

    private func loadNextProblem() {
        currentProblem = pickProblem()
        currentChoices = generateChoices(for: currentProblem.answer)
        selectedAnswer = nil
        problemStartTime = Date()
        if !isYoung4 { startTimer() }
    }

    // MARK: - タイマー

    private func startTimer() {
        timerCancellable?.cancel()
        timerTotal = Self.timeLimits[currentLevel] ?? 8.0
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

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func handleTimeUp() {
        guard selectedAnswer == nil else { return }
        // タイムアップ = 不正解扱い（罰なし）
        selectedAnswer = -1  // 何も選ばなかった
        SoundManager.shared.playIncorrect()
        HapticsManager.incorrect()
        answerTimes.append(timerTotal)
        // レベルダウン（young4以外）
        if !isYoung4, let prev = BeforeTestLevel(rawValue: currentLevel.rawValue - 1) {
            currentLevel = prev
        }
        // キャラ揺れ
        let steps: [(CGFloat, Double)] = [(-6, 0), (6, 0.05), (-4, 0.1), (4, 0.15), (0, 0.2)]
        for (offset, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.04)) { characterShake = offset }
            }
        }
        advanceOrFinish()
    }

    private func advanceOrFinish() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            questionIndex += 1
            if questionIndex < Self.totalQuestions {
                withAnimation(.easeOut(duration: 0.15)) { showProblem = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    loadNextProblem()
                    withAnimation(.easeOut(duration: 0.2)) { showProblem = true }
                }
            } else {
                finishTest()
            }
        }
    }

    private func finishTest() {
        stopTimer()
        // 完了演出
        showFinale = true
        SoundManager.shared.stopBGM()
        SoundManager.shared.playBossVictory()

        let avg = answerTimes.isEmpty ? 0 : answerTimes.reduce(0, +) / Double(answerTimes.count)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onComplete(score, Self.totalQuestions, maxReachedLevel, avg)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.93, blue: 1.0),
                    Color(red: 0.78, green: 0.96, blue: 0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer().frame(height: 50)

                // 星
                HStack(spacing: 6) {
                    ForEach(0..<Self.totalQuestions, id: \.self) { i in
                        Image(systemName: stars[i] ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundStyle(stars[i] ? .yellow : .white.opacity(0.4))
                            .shadow(color: stars[i] ? .yellow.opacity(0.5) : .clear, radius: 4)
                    }
                }

                // タイマーバー
                if showProblem && !showFinale {
                    TimerBarView(remaining: timerRemaining, total: timerTotal)
                        .padding(.horizontal, 20)
                }

                // キャラクター
                HStack(alignment: .center, spacing: 32) {
                    KennyCharacterView(
                        appearance: CharacterAppearanceFactory.appearance(for: 1),
                        size: 80
                    )
                    .offset(y: characterBounce)
                    .offset(x: characterShake)

                    KennyCharacterView(appearance: .slime, size: 80)
                }
                .frame(height: 140)
                .opacity(showCharacters ? 1 : 0)
                .offset(y: showCharacters ? 0 : 40)

                Spacer()

                // 問題文
                if showProblem && !showFinale {
                    Text("\(currentProblem.a) \(currentProblem.op) \(currentProblem.b) ＝ ?")
                        .font(.zenMaru(44, weight: .black))
                        .foregroundStyle(.primary)
                        .transition(.opacity)
                }

                Spacer()

                // 選択肢
                if currentChoices.count >= 4 && showProblem && !showFinale {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            testChoiceButton(number: currentChoices[0])
                            testChoiceButton(number: currentChoices[1])
                        }
                        HStack(spacing: 12) {
                            testChoiceButton(number: currentChoices[2])
                            testChoiceButton(number: currentChoices[3])
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer().frame(height: 50)
            }

            // 完了演出：紙吹雪
            if showFinale {
                TestConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCharacters = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadNextProblem()
                withAnimation(.easeOut(duration: 0.3)) { showProblem = true }
            }
        }
    }

    // MARK: - 選択肢ボタン

    @ViewBuilder
    private func testChoiceButton(number: Int) -> some View {
        let isSelected = selectedAnswer == number
        let isCorrect = number == currentProblem.answer

        Button {
            guard selectedAnswer == nil else { return }
            HapticsManager.tap()
            selectedAnswer = number
            stopTimer()

            let elapsed = Date().timeIntervalSince(problemStartTime)
            answerTimes.append(elapsed)

            SupabaseService.shared.logAnswer(
                operatorSymbol: currentProblem.op,
                a: currentProblem.a,
                b: currentProblem.b,
                correctAnswer: currentProblem.answer,
                userAnswer: number,
                isCorrect: isCorrect,
                responseTimeMs: Int(elapsed * 1000),
                attemptCount: questionIndex + 1
            )

            if isCorrect {
                score += 1
                stars[questionIndex] = true
                SoundManager.shared.playCorrect()
                HapticsManager.correct()
                if !isYoung4 {
                    if let next = BeforeTestLevel(rawValue: currentLevel.rawValue + 1) {
                        currentLevel = next
                    }
                }
                maxReachedLevel = max(maxReachedLevel, currentLevel.rawValue)
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                    characterBounce = -20
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        characterBounce = 0
                    }
                }
            } else {
                SoundManager.shared.playIncorrect()
                HapticsManager.incorrect()
                if !isYoung4 {
                    if let prev = BeforeTestLevel(rawValue: currentLevel.rawValue - 1) {
                        currentLevel = prev
                    }
                }
                let steps: [(CGFloat, Double)] = [(-6, 0), (6, 0.05), (-4, 0.1), (4, 0.15), (0, 0.2)]
                for (offset, delay) in steps {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.linear(duration: 0.04)) { characterShake = offset }
                    }
                }
            }

            advanceOrFinish()
        } label: {
            Text("\(number)")
                .font(.zenMaru(28, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    isSelected
                        ? (isCorrect ? Color.green : Color.red)
                        : (selectedAnswer != nil && isCorrect ? Color.green : Color.blue.opacity(0.85))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
        }
        .disabled(selectedAnswer != nil)
    }
}

// MARK: - 紙吹雪

private struct TestConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, color: Color)] = []
    private let colors: [Color] = [.yellow, .orange, .red, .pink, .green, .blue, .purple, .cyan]

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { p in
                TestConfettiParticle(color: p.color).offset(x: p.x)
            }
        }
        .onAppear {
            particles = (0..<25).map { i in
                (id: i, x: CGFloat.random(in: -200...200), color: colors.randomElement()!)
            }
        }
    }
}

private struct TestConfettiParticle: View {
    let color: Color
    @State private var yOffset: CGFloat = -100
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(y: yOffset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: Double.random(in: 2...4))) {
                    yOffset = CGFloat.random(in: 400...800)
                    rotation = Double.random(in: 180...720)
                    opacity = 0
                }
            }
    }
}
