import SwiftUI
import Combine

/// オンライン対戦バトル画面（ヒカキン流演出）
struct OnlineMatchView: View {
    var isFamily: Bool = false
    var additionOnly: Bool = false
    let onComplete: (Int, Int) -> Void

    @State private var mp = MultiplayerService.shared
    @State private var questionIndex = 0
    @State private var playerScore = 0
    @State private var playerCorrect = 0
    @State private var playerCombo = 0
    @State private var currentProblem = Problem.generateMastery(phase: .addition)
    @State private var currentChoices: [Int] = []
    @State private var selectedAnswer: Int? = nil
    @State private var timerRemaining: Double = 8.0
    @State private var timerCancellable: AnyCancellable?
    @State private var showProblem = false
    @State private var flashGreen = false
    @State private var flashRed = false
    @State private var characterBounce: CGFloat = 0
    @State private var characterShake: CGFloat = 0
    @State private var waitingForOpponent = false
    @State private var isAttacking = false
    @State private var myAttackCount = 0
    @State private var lastSeenOpponentAttack = 0
    @State private var timerUnderAttack = false
    @State private var showCorrectReveal = false
    @State private var opponentHit = false
    @State private var hitImageName = "hit_character_1"
    @State private var isAdvancing = false
    // 救済モード（2問連続不正解+負けてる→得意問題を出す）
    @State private var consecutiveMisses = 0
    @State private var easyModeActive = false

    // ヒカキン流演出
    @State private var countdownText = ""
    @State private var countdownScale: CGFloat = 3.0
    @State private var countdownOpacity: Double = 0
    @State private var showCountdown = true
    @State private var comboPopText = ""
    @State private var comboPopScale: CGFloat = 0
    @State private var comboPopOpacity: Double = 0
    @State private var scorePopScale: CGFloat = 1.0
    @State private var shakeOffset: CGFloat = 0
    @State private var showReversal = false
    @State private var reversalScale: CGFloat = 3.0
    @State private var reversalOpacity: Double = 0
    @State private var wasLeading = false
    @State private var flashGold = false
    @State private var isFinalStretch = false
    @State private var attackReceivedShake: CGFloat = 0

    private let baseTimeLimit: Double = 8.0
    private var totalQuestions: Int {
        if isFamily { return 35 }
        return additionOnly ? 30 : 33
    }
    private var effectiveTimeLimit: Double { isFamily ? 4.0 : baseTimeLimit }

    var body: some View {
        ZStack {
            // 背景（ラスト5問で赤みがかる）
            LinearGradient(
                colors: isFinalStretch
                    ? [Color(red: 0.65, green: 0.25, blue: 0.30), Color(red: 0.45, green: 0.15, blue: 0.25)]
                    : [Color(red: 0.45, green: 0.40, blue: 0.80), Color(red: 0.30, green: 0.25, blue: 0.65)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            .animation(.easeInOut(duration: 1.0), value: isFinalStretch)

            VStack(spacing: 12) {
                Spacer().frame(height: 50)

                // ヘッダー
                HStack {
                    Text("versus_match_title")
                        .font(.zenMaru(20, weight: .black))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(questionIndex + 1) / \(totalQuestions)")
                        .font(.zenMaru(16, weight: .bold))
                        .foregroundStyle(isFinalStretch ? .red : .white.opacity(0.7))
                }
                .padding(.horizontal, 24)

                // タイマーバー
                if showProblem && !showCountdown {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(timerUnderAttack ? Color.purple : (timerRemaining <= 2.0 ? Color.red : Color.green))
                                .frame(width: geo.size.width * max(0, timerRemaining / effectiveTimeLimit), height: 8)
                                .animation(.linear(duration: 0.05), value: timerRemaining)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 20)
                }

                // キャラクター VS
                HStack(alignment: .center, spacing: 24) {
                    VStack(spacing: 4) {
                        KennyCharacterView(
                            appearance: CharacterAppearanceFactory.appearance(for: 10),
                            size: 91,
                            isAttacking: isAttacking
                        )
                        .allowsHitTesting(false)
                        .offset(y: characterBounce)
                        .offset(x: characterShake + attackReceivedShake)
                        Text(DataStore.loadPlayerData().playerName)
                            .font(.zenMaru(13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("VS")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.4), radius: 8)

                    VStack(spacing: 4) {
                        Image(opponentHit ? hitImageName : "awaken_character")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                        Text("versus_opponent_name")
                            .font(.zenMaru(13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .frame(height: 140)

                // スコア + コンボ
                HStack(spacing: 32) {
                    VStack(spacing: 2) {
                        Text("\(playerScore)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .scaleEffect(scorePopScale)
                            .contentTransition(.numericText())
                        if playerCombo >= 2 {
                            Text("\(playerCombo) combo")
                                .font(.zenMaru(12, weight: .black))
                                .foregroundStyle(playerCombo >= 20 ? .yellow : (playerCombo >= 10 ? Color(red: 1.0, green: 0.5, blue: 0.2) : .orange))
                        }
                    }
                    Text("--")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                    VStack(spacing: 2) {
                        Text("\(mp.opponentScore)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        if mp.opponentCombo >= 2 {
                            Text("\(mp.opponentCombo) combo")
                                .font(.zenMaru(12, weight: .black))
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer()

                if waitingForOpponent {
                    VStack(spacing: 16) {
                        Text("online_waiting_friend")
                            .font(.zenMaru(22, weight: .black))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                } else if !showCountdown {
                    if showProblem {
                        Text("\(currentProblem.a) \(currentProblem.operatorSymbol) \(currentProblem.b) = ?")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24).padding(.vertical, 16)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                    }
                }

                Spacer()

                if showProblem && !waitingForOpponent && !showCountdown {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(currentChoices, id: \.self) { num in
                            choiceButton(num)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer().frame(height: 40)
            }
            .offset(x: shakeOffset)

            // フラッシュ
            Color.green.ignoresSafeArea().opacity(flashGreen ? 0.3 : 0).allowsHitTesting(false)
            Color.red.ignoresSafeArea().opacity(flashRed ? 0.3 : 0).allowsHitTesting(false)
            Color.yellow.ignoresSafeArea().opacity(flashGold ? 0.5 : 0).allowsHitTesting(false)

            // カウントダウン
            if showCountdown {
                Text(countdownText)
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 4)
                    .scaleEffect(countdownScale)
                    .opacity(countdownOpacity)
            }

            // コンボポップ
            if comboPopOpacity > 0 {
                Text(comboPopText)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        comboPopText == "LEGENDARY!" ? .yellow :
                        comboPopText == "AMAZING!" ? Color(red: 1.0, green: 0.5, blue: 0.2) :
                        comboPopText == "SUPER!" ? Color(red: 0.3, green: 0.8, blue: 1.0) : .green
                    )
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 2)
                    .scaleEffect(comboPopScale)
                    .opacity(comboPopOpacity)
                    .allowsHitTesting(false)
            }

            // 逆転テキスト
            if showReversal {
                Text("online_reversal")
                    .font(.zenMaru(42, weight: .black))
                    .foregroundStyle(.yellow)
                    .shadow(color: .orange.opacity(0.8), radius: 16, y: 2)
                    .scaleEffect(reversalScale)
                    .opacity(reversalOpacity)
                    .allowsHitTesting(false)
            }
        }
        .onAppear { runCountdown() }
        .onDisappear { timerCancellable?.cancel() }
        .onChange(of: mp.opponentDisconnected) { _, disc in
            if disc {
                timerCancellable?.cancel()
                finishMatch()
            }
        }
        .onChange(of: mp.opponentAttackCount) { _, newCount in
            if newCount > lastSeenOpponentAttack && !waitingForOpponent {
                lastSeenOpponentAttack = newCount
                let penalty = isFamily ? timerRemaining * 0.4 : baseTimeLimit * 0.1
                timerRemaining = max(0.5, timerRemaining - penalty)
                timerUnderAttack = true
                HapticsManager.incorrect()
                // 画面シェイク
                runAttackReceivedShake()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    timerUnderAttack = false
                }
            }
        }
    }

    // MARK: - カウントダウン

    private func runCountdown() {
        loadProblem()
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            characterBounce = -6
        }

        let steps: [(String, Double)] = [("3", 0.0), ("2", 0.8), ("1", 1.6), ("GO!", 2.4)]
        for (text, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                countdownText = text
                countdownScale = 3.0
                countdownOpacity = 0
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    countdownScale = 1.0
                    countdownOpacity = 1
                }
                HapticsManager.tap()
                if text == "GO!" {
                    SoundManager.shared.playBossAppear()
                    runShake()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.2)) { countdownOpacity = 0 }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showCountdown = false
            withAnimation { showProblem = true }
            startTimer()
        }
    }

    // MARK: - シェイク

    private func runShake() {
        let steps: [(CGFloat, Double)] = [(8,0),(-8,0.03),(6,0.06),(-6,0.09),(4,0.12),(-3,0.15),(0,0.18)]
        for (o, d) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.linear(duration: 0.02)) { shakeOffset = o }
            }
        }
    }

    private func runAttackReceivedShake() {
        let steps: [(CGFloat, Double)] = [(-6,0),(6,0.04),(-4,0.08),(4,0.12),(0,0.16)]
        for (o, d) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.linear(duration: 0.03)) { attackReceivedShake = o }
            }
        }
    }

    // MARK: - コンボ演出

    private func checkComboMilestone() {
        let text: String?
        switch playerCombo {
        case 5:  text = "NICE!"
        case 10: text = "SUPER!"
        case 15: text = "AMAZING!"
        case 20: text = "LEGENDARY!"
        default: text = nil
        }
        guard let t = text else { return }

        comboPopText = t
        comboPopScale = 3.0
        comboPopOpacity = 0
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            comboPopScale = 1.0
            comboPopOpacity = 1
        }
        HapticsManager.tap()

        if playerCombo == 10 {
            flashGreen = true
            withAnimation(.easeOut(duration: 0.3)) { flashGreen = false }
        } else if playerCombo >= 15 {
            runShake()
        }
        if playerCombo >= 20 {
            flashGold = true
            withAnimation(.easeOut(duration: 0.3)) { flashGold = false }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) { comboPopOpacity = 0 }
        }
    }

    // MARK: - 逆転チェック

    private func checkReversal() {
        let nowLeading = playerScore > mp.opponentScore
        if nowLeading && !wasLeading && mp.opponentScore > 0 {
            showReversal = true
            reversalScale = 3.0
            reversalOpacity = 0
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                reversalScale = 1.0
                reversalOpacity = 1
            }
            HapticsManager.tap()
            runShake()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) { reversalOpacity = 0 }
                showReversal = false
            }
        }
        wasLeading = nowLeading
    }

    // MARK: - ボタン

    @ViewBuilder
    private func choiceButton(_ num: Int) -> some View {
        let isCorrect = num == currentProblem.answer
        let isSelected = selectedAnswer == num
        let bg: Color = {
            if showCorrectReveal && isCorrect { return .green }
            if isSelected { return isCorrect ? .green : .red }
            return Color.white.opacity(0.9)
        }()
        let fg: Color = {
            if showCorrectReveal && isCorrect { return .white }
            if isSelected { return .white }
            return .black
        }()
        let buttonOpacity: Double = showCorrectReveal && !isCorrect ? 0 : 1

        Button {
            guard selectedAnswer == nil else { return }
            handleAnswer(num)
        } label: {
            Text("\(num)")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(fg)
                .frame(maxWidth: .infinity).frame(height: 64)
                .background(RoundedRectangle(cornerRadius: 16).fill(bg))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 3)
        }
        .opacity(buttonOpacity)
        .animation(.easeOut(duration: 0.2), value: showCorrectReveal)
        .disabled(selectedAnswer != nil)
    }

    // MARK: - ロジック

    private func startTimer() {
        timerRemaining = effectiveTimeLimit
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                timerRemaining -= 0.05
                if timerRemaining <= 0 {
                    timerCancellable?.cancel()
                    handleTimeUp()
                }
            }
    }

    private func loadProblem() {
        if easyModeActive {
            // 救済モード: 得意なカテゴリから出題
            currentProblem = generateEasyProblem()
        } else {
            // コンボ難易度スケーリング
            let phases = comboDifficultyPhases()
            currentProblem = Problem.generateMastery(phase: phases.randomElement()!)
        }
        currentChoices = generateChoices(for: currentProblem.answer)
        selectedAnswer = nil
        showCorrectReveal = false
    }

    /// コンボ数に応じた出題フェーズを返す
    private func comboDifficultyPhases() -> [MasteryPhase] {
        if additionOnly {
            // 足し算だけモード
            switch playerCombo {
            case 0...4:
                // Easy: 繰り上がりなしのみ
                return [.addition]
            case 5...9:
                // Normal: 現状と同じ
                return [.addition, .carryAddition]
            default:
                // Hard: 繰り上がり優先（70%）
                return [.carryAddition, .carryAddition, .carryAddition, .carryAddition,
                        .carryAddition, .carryAddition, .carryAddition, .addition, .addition, .addition]
            }
        } else {
            // 通常モード（足し算＋引き算）
            switch playerCombo {
            case 0...4:
                // Easy: 繰り上がり/繰り下がりなし
                return [.addition, .subtraction]
            case 5...9:
                // Normal: 全フェーズ均等
                return [.addition, .carryAddition, .subtraction, .borrowSubtraction]
            case 10...14:
                // Hard: 繰り上がり/繰り下がり優先（70%）
                return [.carryAddition, .carryAddition, .borrowSubtraction, .borrowSubtraction,
                        .carryAddition, .borrowSubtraction, .borrowSubtraction,
                        .addition, .subtraction, .addition]
            default:
                // Very Hard: 繰り上がり/繰り下がりのみ
                return [.carryAddition, .borrowSubtraction]
            }
        }
    }

    private func generateChoices(for answer: Int) -> [Int] {
        var set = Set([answer])
        while set.count < 4 {
            let offset = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
            let w = answer + offset
            if w > 0 { set.insert(w) }
        }
        return Array(set).shuffled()
    }

    private func handleAnswer(_ answer: Int) {
        timerCancellable?.cancel()
        selectedAnswer = answer
        let correct = answer == currentProblem.answer

        if correct {
            playerCorrect += 1
            playerCombo += 1
            let comboBonus = isFamily ? playerCombo / 10 : playerCombo / 5
            let speedBonus = timerRemaining > (effectiveTimeLimit - 3.0) ? 1 : 0  // 3秒以内で+1
            playerScore += 1 + comboBonus + speedBonus
            myAttackCount += 1
            consecutiveMisses = 0
            // 救済モード中: 逆転したら解除
            if easyModeActive && playerScore > mp.opponentScore {
                easyModeActive = false
            }
            // コンボ10ごとにおうえんボイス再生
            if playerCombo > 0 && playerCombo % 10 == 0 && DataStore.hasParentVoiceRecording() {
                SoundManager.shared.playParentVoice()
            }
            SoundManager.shared.playCorrect()
            HapticsManager.correct()
            flashGreen = true
            withAnimation(.easeOut(duration: 0.2)) { flashGreen = false }
            // スコアポップ
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { scorePopScale = 1.3 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { scorePopScale = 1.0 }
            }
            // 攻撃表情 + 相手ダメージ
            isAttacking = true
            hitImageName = Bool.random() ? "hit_character_1" : "hit_character_2"
            opponentHit = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { isAttacking = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { opponentHit = false }
            // コンボ演出
            checkComboMilestone()
            // 逆転チェック
            checkReversal()
        } else {
            playerCombo = 0
            consecutiveMisses += 1
            // 2問連続不正解 + 負けてる → 救済モード発動
            if consecutiveMisses >= 2 && playerScore < mp.opponentScore && !easyModeActive {
                easyModeActive = true
            }
            SoundManager.shared.playIncorrect()
            HapticsManager.incorrect()
            flashRed = true
            withAnimation(.easeOut(duration: 0.2)) { flashRed = false }
            showCorrectReveal = true
        }

        mp.updateScore(score: playerScore, correctCount: playerCorrect, combo: playerCombo, attackCount: myAttackCount)
        if correct {
            advance()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCorrectReveal = false
                advance()
            }
        }
    }

    private func handleTimeUp() {
        selectedAnswer = -1
        playerCombo = 0
        SoundManager.shared.playIncorrect()
        HapticsManager.incorrect()
        flashRed = true
        withAnimation(.easeOut(duration: 0.2)) { flashRed = false }
        showCorrectReveal = true
        mp.updateScore(score: playerScore, correctCount: playerCorrect, combo: playerCombo, attackCount: myAttackCount)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCorrectReveal = false
            advance()
        }
    }

    private func advance() {
        guard !isAdvancing else { return }
        isAdvancing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAdvancing = false
            questionIndex += 1
            if questionIndex >= totalQuestions {
                finishMatch()
                return
            }
            // ラスト5問チェック
            if questionIndex >= totalQuestions - 5 && !isFinalStretch {
                isFinalStretch = true
                HapticsManager.incorrect()
            }
            withAnimation(.easeOut(duration: 0.1)) { showProblem = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                loadProblem()
                withAnimation(.easeOut(duration: 0.15)) { showProblem = true }
                startTimer()
            }
        }
    }

    private func finishMatch() {
        timerCancellable?.cancel()
        mp.reportFinished(score: playerScore, correctCount: playerCorrect, combo: playerCombo)
        if mp.opponentFinished || mp.opponentDisconnected {
            goToResult()
        } else {
            withAnimation { waitingForOpponent = true }
            waitForOpponent()
        }
    }

    private func waitForOpponent() {
        var waitCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            waitCount += 1
            if mp.opponentFinished || mp.opponentDisconnected || waitCount >= 600 {
                timer.invalidate()
                goToResult()
            }
        }
    }

    private func goToResult() {
        if mp.isHost {
            mp.determineWinner(
                hostScore: playerScore, hostCorrect: playerCorrect, hostCombo: playerCombo,
                guestScore: mp.opponentScore, guestCorrect: mp.opponentCorrect, guestCombo: mp.opponentCombo
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onComplete(playerScore, mp.opponentScore)
            }
        } else {
            waitForWinner()
        }
    }

    private func waitForWinner() {
        var waitCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            waitCount += 1
            if !mp.winner.isEmpty || waitCount >= 30 {
                timer.invalidate()
                onComplete(playerScore, mp.opponentScore)
            }
        }
    }

    // MARK: - 救済モード: 得意問題生成

    private func generateEasyProblem() -> Problem {
        // マスター度が高いカテゴリを優先
        let mastered = DataStore.loadMasteredProblems()

        // 正解数が多いカテゴリを見つける
        var bestIsAddition = true
        let addCount = (mastered["addition_under10"]?.count ?? 0) + (mastered["addition_under5"]?.count ?? 0)
        let subCount = (mastered["subtraction_no_borrow"]?.count ?? 0)
        if subCount > addCount { bestIsAddition = false }

        if bestIsAddition {
            // 答え10以下の簡単な足し算
            let a = Int.random(in: 1...5)
            let b = Int.random(in: 1...min(5, 10 - a))
            let answer = a + b
            let choices = generateChoices(for: answer)
            return Problem(a: a, b: b, answer: answer, operatorSymbol: "+",
                           choices: choices, isReview: false)
        } else {
            // 簡単な引き算
            let a = Int.random(in: 3...8)
            let b = Int.random(in: 1...(a - 1))
            let answer = a - b
            let choices = generateChoices(for: answer)
            return Problem(a: a, b: b, answer: answer, operatorSymbol: "-",
                           choices: choices, isReview: false)
        }
    }
}
