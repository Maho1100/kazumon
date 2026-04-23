import SwiftUI
import Combine

/// youngモード開始前の「たすN確認テスト」
/// ラウンド1（たす1）〜ラウンド9（たす9）を順に実施
struct AdditionCheckTestView: View {
    let onComplete: (Int) -> Void  // 合流ラウンド番号を返す
    var maxRound: Int = 9  // 最大ラウンド（4歳モードは2）

    // MARK: - State

    @State private var currentRound = 1       // 1〜9
    @State private var questionIndex = 0      // 0〜4
    @State private var correctCount = 0
    @State private var allInTime = true       // 全問3秒以内か
    @State private var selectedAnswer: Int? = nil
    @State private var choices: [Int] = []
    @State private var currentA = 1
    @State private var currentAnswer = 2
    @State private var showProblem = false
    @State private var slimeColorsA: [Color] = []
    @State private var slimeColorsB: [Color] = []

    // タイマー
    @State private var timerRemaining: Double = 3.0
    @State private var timerCancellable: AnyCancellable?

    // ＋記号説明
    @State private var showPlusExplanation = false
    @State private var explanationDone = false

    // 結果表示
    @State private var showResult = false
    @State private var passed = false
    @State private var charScale: CGFloat = 0
    @State private var charFloat: CGFloat = 0
    @State private var resultTextOpacity: Double = 0
    @State private var resultButtonOpacity: Double = 0
    @State private var flashColor: Color = .clear
    @State private var flashOpacity: Double = 0
    @State private var showFormula = false

    private let questionsPerRound = 5
    private let timeLimit: Double = 6.0

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.5, green: 0.85, blue: 0.95)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            if showResult {
                resultView
            } else {
                testView
            }

            // フラッシュ
            flashColor.ignoresSafeArea()
                .opacity(flashOpacity)
                .allowsHitTesting(false)
        }
        .onAppear {
            // 合格済みラウンドの次から開始
            let passed = DataStore.additionCheckLastPassedRound()
            if passed > 0 { currentRound = passed + 1 }
            startRound()
        }
    }

    // MARK: - テスト画面

    private var testView: some View {
        VStack(spacing: 16) {
            // やめるボタン
            HStack {
                Spacer()
                Button {
                    timerCancellable?.cancel()
                    HapticsManager.tap()
                    onComplete(0)
                } label: {
                    Text("battle_quit_button")
                        .font(.zenMaru(16, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.6)))
                        .shadow(color: .red.opacity(0.3), radius: 4, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Text(String(format: NSLocalizedString("addition_check_round_title", comment: ""), currentRound))
                .font(.zenMaru(18, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))

            // 進捗ドット
            HStack(spacing: 6) {
                ForEach(0..<questionsPerRound, id: \.self) { i in
                    Circle()
                        .fill(i < correctCount ? Color.yellow : Color.white.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }

            // タイマーバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(timerRemaining <= 1.0 ? Color.red : Color.green)
                        .frame(width: geo.size.width * max(0, timerRemaining / timeLimit), height: 8)
                        .animation(.linear(duration: 0.1), value: timerRemaining)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 32)

            Spacer()

            // ＋記号説明吹き出し
            if showPlusExplanation {
                Text("addition_check_plus_explain")
                    .font(.zenMaru(16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2))
                    .transition(.scale.combined(with: .opacity))
            }

            // 問題：スライム + 数字 + ＋記号
            if showProblem {
                VStack(spacing: 12) {
                    // スライムグループ（左 + 右）
                    HStack(spacing: 12) {
                        // 左グループ（currentA匹）
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                ForEach(0..<currentA, id: \.self) { i in
                                    VStack(spacing: 2) {
                                        Text("\(i + 1)")
                                            .font(.system(size: 12, weight: .black, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.8))
                                        SlimeView(
                                            color: i < slimeColorsA.count ? slimeColorsA[i] : SlimeView.randomColor(),
                                            size: 30
                                        )
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                            Text("\(currentA)")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        // ＋記号
                        Text("+")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow.opacity(0.4), radius: 6)

                        // 右グループ（currentRound匹）
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                ForEach(0..<currentRound, id: \.self) { i in
                                    VStack(spacing: 2) {
                                        Text("\(currentA + i + 1)")
                                            .font(.system(size: 12, weight: .black, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.8))
                                        SlimeView(
                                            color: i < slimeColorsB.count ? slimeColorsB[i] : SlimeView.randomColor(),
                                            size: 30
                                        )
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                            Text("\(currentRound)")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        // ＝ ？ or 答え
                        Text(showFormula ? "= \(currentAnswer)" : "= ?")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(showFormula ? .green : .white)
                    }

                    // 回答後に式をテキストで表示
                    if showFormula {
                        Text("\(currentA) + \(currentRound) = \(currentAnswer)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                            .padding(.top, 8)
                    }
                }
            }

            Spacer()

            // 回答ボタン（2x2グリッド）
            if showProblem && !showPlusExplanation {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(choices, id: \.self) { num in
                        answerButton(num)
                    }
                }
                .padding(.horizontal, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 40)
        }
    }

    @ViewBuilder
    private func answerButton(_ num: Int) -> some View {
        let isCorrect = num == currentAnswer
        let isSelected = selectedAnswer == num

        let bgColor: Color = {
            if isSelected { return isCorrect ? Color.green : Color.red }
            return Color.white.opacity(0.9)
        }()

        let textColor: Color = {
            if isSelected { return .white }
            return .black
        }()

        Button {
            guard selectedAnswer == nil else { return }
            handleAnswer(num)
        } label: {
            Text("\(num)")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity).frame(height: 72)
                .background(RoundedRectangle(cornerRadius: 16).fill(bgColor))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 3)
        }
        .disabled(selectedAnswer != nil)
    }

    // MARK: - 結果画面

    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()

            KennyCharacterView(
                appearance: CharacterAppearanceFactory.appearance(for: 1),
                size: 120
            )
            .allowsHitTesting(false)
            .scaleEffect(charScale)
            .offset(y: charFloat)

            if passed {
                if currentRound >= maxRound {
                    // 全ラウンドクリア
                    Text("addition_check_all_clear")
                        .font(.zenMaru(28, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(resultTextOpacity)
                } else {
                    Text(String(format: NSLocalizedString("addition_check_pass", comment: ""), currentRound))
                        .font(.zenMaru(28, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(resultTextOpacity)
                }
            } else {
                Text(String(format: NSLocalizedString("addition_check_fail", comment: ""), currentRound))
                    .font(.zenMaru(22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(resultTextOpacity)
            }

            Spacer()

            if resultButtonOpacity > 0 {
                Button {
                    HapticsManager.tap()
                    if passed {
                        DataStore.saveAdditionCheckRound(currentRound)
                        if currentRound >= maxRound {
                            onComplete(currentRound)
                        } else {
                            currentRound += 1
                            showResult = false
                            startRound()
                        }
                    } else {
                        showResult = false
                        startRound()
                    }
                } label: {
                    Text(resultButtonText)
                        .font(.zenMaru(22, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 16).fill(passed ? Color.green : Color.orange))
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 4)
                }
                .padding(.horizontal, 32)
                .opacity(resultButtonOpacity)
            }

            // 不合格時: スキップボタン（常に表示）
            if resultButtonOpacity > 0 && !passed {
                Button {
                    HapticsManager.tap()
                    if currentRound <= 1 {
                        onComplete(0)
                    } else {
                        onComplete(currentRound - 1)
                    }
                } label: {
                    Text(NSLocalizedString(currentRound <= 1 ? "addition_check_skip_test" : "addition_check_skip", comment: ""))
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 4)
                .opacity(resultButtonOpacity)
            }

            Spacer().frame(height: 50)
        }
    }

    private var resultButtonText: String {
        if passed {
            if currentRound >= maxRound {
                return NSLocalizedString("addition_check_start_battle", comment: "")
            } else {
                return String(format: NSLocalizedString("addition_check_next", comment: ""), currentRound + 1)
            }
        } else {
            return NSLocalizedString("addition_check_retry", comment: "")
        }
    }

    // MARK: - ロジック

    private func startRound() {
        questionIndex = 0
        correctCount = 0
        allInTime = true
        selectedAnswer = nil
        showProblem = false
        showResult = false
        explanationDone = DataStore.hasSeenPlusExplanation()
        generateProblem()

        // ＋記号の初回説明
        if currentRound == 1 && !explanationDone {
            showProblem = true
            showPlusExplanation = true
            DataStore.markPlusExplanationSeen()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) { showPlusExplanation = false }
                explanationDone = true
                startTimer()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) { showProblem = true }
                startTimer()
            }
        }
    }

    private func generateProblem() {
        currentA = Int.random(in: 1...5)
        currentAnswer = currentA + currentRound
        slimeColorsA = (0..<currentA).map { _ in SlimeView.randomColor() }
        slimeColorsB = (0..<currentRound).map { _ in SlimeView.randomColor() }
        var set = Set([currentAnswer])
        while set.count < 4 {
            let w = Int.random(in: max(1, currentAnswer - 3)...min(18, currentAnswer + 3))
            if w != currentAnswer { set.insert(w) }
        }
        choices = Array(set).shuffled()
    }

    private func startTimer() {
        timerRemaining = timeLimit
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                timerRemaining -= 0.1
                if timerRemaining <= 0 {
                    timerCancellable?.cancel()
                    // 時間切れ → 不正解扱い
                    allInTime = false
                    selectedAnswer = -1  // ダミー
                    SoundManager.shared.playIncorrect()
                    HapticsManager.incorrect()
                    flashColor = .red; flashOpacity = 0.3
                    withAnimation(.easeOut(duration: 0.2)) { flashOpacity = 0 }
                    showFormula = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showFormula = false
                        advanceQuestion()
                    }
                }
            }
    }

    private func handleAnswer(_ answer: Int) {
        timerCancellable?.cancel()
        selectedAnswer = answer
        let isCorrect = answer == currentAnswer

        if isCorrect {
            correctCount += 1
            SoundManager.shared.playCorrect()
            HapticsManager.correct()
            flashColor = .green; flashOpacity = 0.3
            withAnimation(.easeOut(duration: 0.2)) { flashOpacity = 0 }
        } else {
            allInTime = false
            SoundManager.shared.playIncorrect()
            HapticsManager.incorrect()
            flashColor = .red; flashOpacity = 0.3
            withAnimation(.easeOut(duration: 0.2)) { flashOpacity = 0 }
        }

        // 式を1秒表示してから次へ
        showFormula = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showFormula = false
            advanceQuestion()
        }
    }

    private func advanceQuestion() {
        questionIndex += 1
        if questionIndex >= questionsPerRound {
            // ラウンド終了 → 結果表示
            passed = correctCount == questionsPerRound && allInTime
            showResultSequence()
            return
        }
        selectedAnswer = nil
        withAnimation(.easeOut(duration: 0.1)) { showProblem = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generateProblem()
            withAnimation(.easeOut(duration: 0.15)) { showProblem = true }
            startTimer()
        }
    }

    private func showResultSequence() {
        showResult = true
        charScale = 0
        charFloat = 0
        resultTextOpacity = 0
        resultButtonOpacity = 0

        if passed {
            SoundManager.shared.playBossVictory()
            flashColor = Color(red: 1.0, green: 0.85, blue: 0.2); flashOpacity = 0.5
            withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }
        }

        HapticsManager.tap()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { charScale = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { charFloat = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) { resultTextOpacity = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) { resultButtonOpacity = 1 }
        }
    }
}
