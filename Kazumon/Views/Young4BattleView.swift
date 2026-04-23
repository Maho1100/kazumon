import SwiftUI

/// 4さいモード専用バトル — レベル選択 + スライムで視覚的に学ぶ
struct Young4BattleView: View {
    @Bindable var vm: GameViewModel

    @State private var selectedLevel: Int? = nil  // nil=選択中, 1/2/3=バトル中
    @State private var questionIndex = 0
    @State private var correctCount = 0
    @State private var showProblem = false
    @State private var selectedAnswer: Int? = nil
    @State private var showFlashGreen = false
    @State private var showFlashRed = false
    @State private var problemStartTime = Date()
    @State private var slimeColors: [Color] = []
    @State private var problemNumber = 0
    @State private var problemNumber2 = 0
    @State private var choices: [Int] = []
    @State private var jumpAll = false
    @State private var levelSelectPhase = 0
    // レベル3バトルアニメ用
    @State private var l3Phase = 0  // 0=選択待ち, 1=バトル中, 2=勝利演出
    @State private var l3Eliminated = 0  // 何体消えたか
    @State private var l3WinnerJump = false
    @State private var l3BoomScale: CGFloat = 1.0
    @State private var leftGroupColor: Color = .blue
    @State private var rightGroupColor: Color = .pink
    // レベル3.5用
    @State private var l35Step = 0  // 0=未開始, 1=初期表示, 2=歩いてくる, 3=回答待ち
    @State private var l35WalkerX: CGFloat = 300
    @State private var l35WalkerColor: Color = .green
    @State private var l35AnswerPopScale: CGFloat = 0
    @State private var l35CountingIndex: Int = -1
    @State private var showPromotion = false
    @State private var showAdditionTest = false
    // レベル5 (3.5b): 数の分解
    @State private var l5Step = 0  // 0=全員表示, 1=分かれる, 2=回答待ち
    @State private var l5LeftCount = 0
    @State private var l5SplitOffset: CGFloat = 0
    @State private var l5ShowLeftNum = false
    @State private var l5ShowQuestion = false
    @State private var l5ShakeAmount: CGFloat = 0
    // レベル2: 正解タップ待ち
    @State private var showCorrectHighlight = false
    @State private var waitingConfirm = false
    // レベル3: 選択マーカー
    @State private var l3SelectedSide: Bool? = nil  // true=左, false=右
    // ヒント
    @State private var hintAnswer: Int? = nil
    @State private var hintPulse: Bool = false

    private let totalQuestions = 10
    private let requiredCorrect = 10
    private let slimeSize: CGFloat = 50
    private let l5SlimeSize: CGFloat = 42

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.72, green: 0.93, blue: 1.0), Color(red: 0.78, green: 0.96, blue: 0.72)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            if selectedLevel == nil {
                levelSelectView
            } else {
                battleView
            }

            Color.green.ignoresSafeArea().opacity(showFlashGreen ? 0.3 : 0).allowsHitTesting(false)
            Color.red.ignoresSafeArea().opacity(showFlashRed ? 0.3 : 0).allowsHitTesting(false)
        }
        .fullScreenCover(isPresented: $showPromotion) {
            Young4PromotionView {
                showPromotion = false
                vm.screen = .island
            }
        }
        .fullScreenCover(isPresented: $showAdditionTest) {
            AdditionCheckTestView(maxRound: 2) { lastPassedRound in
                showAdditionTest = false
                DataStore.saveAdditionCheckRound(lastPassedRound)
                // たす2合格（ラウンド2以上）→ 昇格
                if lastPassedRound >= 2 {
                    showPromotion = true
                }
            }
        }
    }

    // MARK: - レベル選択

    private var levelSelectView: some View {
        VStack(spacing: 20) {
            Spacer()

            // レベル選択ボタン（ヒカキン流登場アニメ）
            VStack(spacing: 14) {
                if levelSelectPhase >= 1 {
                    let unlocked = DataStore.young4UnlockedLevel()
                    young4LevelButton(level: 1, icon: "123", delay: 0)
                    if unlocked >= 2 {
                        young4LevelButton(level: 2, icon: "eye", delay: 0.12)
                    }
                    if unlocked >= 3 {
                        young4LevelButton(level: 3, icon: "greaterthan", delay: 0.24)
                    }
                    if unlocked >= 4 {
                        young4LevelButton(level: 4, icon: "plus", delay: 0.36)
                    }
                    if unlocked >= 5 {
                        young4LevelButton(level: 5, icon: "arrow.left.arrow.right", delay: 0.48)
                    }
                    // たすテスト（Lv5クリア後に表示）
                    if unlocked >= 6 {
                        let passedRound = DataStore.additionCheckLastPassedRound()
                        Button {
                            HapticsManager.tap()
                            SoundManager.shared.playTap()
                            showAdditionTest = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(passedRound >= 1
                                         ? NSLocalizedString("young4_addition_test_2", comment: "")
                                         : NSLocalizedString("young4_addition_test_1", comment: ""))
                                        .font(.zenMaru(22, weight: .black))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity).frame(height: 72)
                            .padding(.horizontal, 20)
                            .background(RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.9, green: 0.45, blue: 0.2)))
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
            }
            .padding(.horizontal, 32)

            // 戻るボタン
            Button {
                HapticsManager.tap()
                vm.quitGame()
            } label: {
                Text("older_back_button")
                    .font(.zenMaru(20, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.25))
                    )
            }
            .padding(.top, 8)

            Spacer()
        }
        .onAppear {
            AnalyticsManager.trackScreenEnter("young4_battle")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { levelSelectPhase = 1 }
            }
        }
    }

    @ViewBuilder
    private func young4LevelButton(level: Int, icon: String, delay: Double) -> some View {
        Button {
            HapticsManager.tap()
            SoundManager.shared.playTap()
            selectedLevel = level
            questionIndex = 0
            correctCount = 0
            generateProblem()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.3)) { showProblem = true }
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: NSLocalizedString("young4_level_title", comment: ""), level))
                        .font(.zenMaru(22, weight: .black))
                        .foregroundColor(.white)
                    Text(String(format: NSLocalizedString("young4_level_progress", comment: ""), 0, requiredCorrect))
                        .font(.zenMaru(16, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity).frame(height: 72)
            .padding(.horizontal, 20)
            .background(RoundedRectangle(cornerRadius: 20)
                .fill(level == 1 ? Color.green : (level == 2 ? Color.blue : (level == 5 ? Color.purple : Color.orange))))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - バトル画面

    private var battleView: some View {
        VStack(spacing: 12) {
            // 進捗 + 問題番号
            VStack(spacing: 4) {
                Text("\(questionIndex + 1) / \(totalQuestions)")
                    .font(.zenMaru(18, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                HStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { i in
                        Circle()
                            .fill(i < min(correctCount, 10) ? Color.yellow : Color.white.opacity(0.3))
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(.top, 50)

            HStack {
                Spacer()
                Button { HapticsManager.tap(); SoundManager.shared.playTap(); vm.quitGame() } label: {
                    Text("battle_quit_button")
                        .font(.zenMaru(16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)

            // 問題エリア（固定位置）
            Spacer()

            if showProblem {
                switch selectedLevel {
                case 1: level1View
                case 2: level2View
                case 3: level3View
                case 4: level35View
                case 5: level35bView
                default: EmptyView()
                }
            }

            Spacer()

            // ボタンエリア（常にスペース確保）
            VStack {
                if showProblem && !choices.isEmpty
                    && (selectedLevel != 4 || l35Step == 3)
                && (selectedLevel != 5 || l5Step == 2) {
                    HStack(spacing: 16) {
                        ForEach(choices, id: \.self) { num in
                            numberButton(num)
                        }
                    }
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(height: 120)
            .padding(.bottom, 20)
        }
    }

    // MARK: - レベル1: 数字を読む

    private var level1View: some View {
        VStack(spacing: 16) {
            Text("\(problemNumber)")
                .font(.system(size: 100, weight: .black, design: .rounded))
                .foregroundStyle(.primary)

            slimeGrid(count: problemNumber)
        }
    }

    // MARK: - レベル2: 数を数える

    private var level2View: some View {
        VStack(spacing: 16) {
            slimeGrid(count: problemNumber)
        }
    }

    // MARK: - レベル3: どっちが多い（左右チーム + 1対1バトル）

    private var level3View: some View {
        VStack(spacing: 16) {
            // バトルフィールド（左右配置）
            HStack(spacing: 0) {
                // 左チーム
                VStack(spacing: 4) {
                    if l3SelectedSide == true {
                        Text("\u{25BC}")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(leftGroupColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                    ForEach(0..<problemNumber, id: \.self) { i in
                        if i < problemNumber - l3Eliminated {
                            SlimeView(color: leftGroupColor, size: 44)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // 中央
                ZStack {
                    if l3Phase == 1 {
                        Text("VS")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.orange)
                            .shadow(color: .orange.opacity(0.6), radius: 8)
                            .scaleEffect(l3BoomScale)
                    } else if l3Phase == 0 {
                        Text("VS")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.orange)
                            .shadow(color: .orange.opacity(0.5), radius: 6)
                    }

                    // 正解時の赤丸
                    if l3WinnerJump {
                        Circle()
                            .stroke(Color.red, lineWidth: 8)
                            .frame(width: 80, height: 80)
                            .shadow(color: .red.opacity(0.5), radius: 10)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 90)

                // 右チーム
                VStack(spacing: 4) {
                    if l3SelectedSide == false {
                        Text("\u{25BC}")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(rightGroupColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                    ForEach(0..<problemNumber2, id: \.self) { i in
                        if i < problemNumber2 - l3Eliminated {
                            SlimeView(color: rightGroupColor, size: 44)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 220)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: l3Eliminated)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: l3WinnerJump)

            // タップボタン（左右対応）
            if l3Phase == 0 && selectedAnswer == nil {
                HStack(spacing: 20) {
                    Button {
                        handleLevel3Tap(tappedLeft: true)
                    } label: {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(leftGroupColor.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(leftGroupColor, lineWidth: 3))
                            .frame(height: 70)
                            .overlay(
                                HStack(spacing: 4) {
                                    ForEach(0..<min(problemNumber, 5), id: \.self) { _ in
                                        Circle().fill(leftGroupColor).frame(width: 14, height: 14)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        handleLevel3Tap(tappedLeft: false)
                    } label: {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(rightGroupColor.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(rightGroupColor, lineWidth: 3))
                            .frame(height: 70)
                            .overlay(
                                HStack(spacing: 4) {
                                    ForEach(0..<min(problemNumber2, 5), id: \.self) { _ in
                                        Circle().fill(rightGroupColor).frame(width: 14, height: 14)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // レベル3: タップ処理
    private func handleLevel3Tap(tappedLeft: Bool) {
        HapticsManager.tap(); SoundManager.shared.playTap()
        guard l3Phase == 0, selectedAnswer == nil else { return }
        let leftIsMore = problemNumber > problemNumber2
        let isCorrect = (tappedLeft && leftIsMore) || (!tappedLeft && !leftIsMore)
        selectedAnswer = tappedLeft ? problemNumber : problemNumber2
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            l3SelectedSide = tappedLeft
        }

        let elapsed = Date().timeIntervalSince(problemStartTime)
        let correctAnswer = max(problemNumber, problemNumber2)

        SupabaseService.shared.logAnswer(
            operatorSymbol: "＞", a: problemNumber, b: problemNumber2,
            correctAnswer: correctAnswer,
            userAnswer: tappedLeft ? problemNumber : problemNumber2,
            isCorrect: isCorrect,
            responseTimeMs: Int(elapsed * 1000),
            attemptCount: questionIndex + 1
        )

        if isCorrect { correctCount += 1 }

        // 正解でも不正解でもバトルアニメを再生
        let minCount = min(problemNumber, problemNumber2)
        l3Phase = 1
        l3BoomScale = 1.0
        HapticsManager.tap()

        for i in 1...minCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    l3Eliminated = i
                }
                // VS拡大アニメ（回数に応じて大きく）
                withAnimation(.spring(response: 0.12, dampingFraction: 0.3)) {
                    l3BoomScale = 1.5 + CGFloat(i) * 0.25
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                        l3BoomScale = 1.0
                    }
                }
                // 音量: 回数に応じて大きくなる（0.3→0.5→0.7→0.9→1.0）
                let vol = min(1.0, 0.3 + Float(i) * 0.2)
                SoundManager.shared.play("Boom", volume: vol)
                HapticsManager.incorrect()
            }
        }

        // バトル終了後
        let battleEndTime = Double(minCount) * 0.25 + 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + battleEndTime) {
            l3Phase = 2
            if isCorrect {
                // 正解: 赤丸 + 緑フラッシュ
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    l3WinnerJump = true
                }
                showFlashGreen = true
                SoundManager.shared.playCorrect()
                HapticsManager.correct()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.15)) { showFlashGreen = false }
                }
            } else {
                // 不正解: 赤フラッシュのみ（赤丸なし）
                showFlashRed = true
                SoundManager.shared.playIncorrect()
                HapticsManager.incorrect()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.15)) { showFlashRed = false }
                }
            }
        }

        // 次の問題
        DispatchQueue.main.asyncAfter(deadline: .now() + battleEndTime + 1.0) {
            l3Phase = 0; l3Eliminated = 0; l3WinnerJump = false
            advanceAfterAnswer()
        }
    }

    // MARK: - レベル3.5: 増えたら何匹？

    private var level35View: some View {
        let totalSlimes = problemNumber + (l35Step >= 2 ? 1 : 0)

        return VStack(spacing: 16) {
            // スライムエリア（カウント時は数字付き）
            HStack(spacing: 8) {
                ForEach(0..<problemNumber, id: \.self) { i in
                    VStack(spacing: 2) {
                        // カウント中の数字
                        if l35CountingIndex >= i {
                            Text("\(i + 1)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.green)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text(" ").font(.system(size: 20)).opacity(0)
                        }
                        SlimeView(
                            color: i < slimeColors.count ? slimeColors[i] : SlimeView.randomColor(),
                            size: slimeSize,
                            isSurprised: jumpAll
                        )
                        .scaleEffect(l35CountingIndex == i ? 1.2 : 1.0)
                    }
                }
                // 歩いてくるスライム
                if l35Step >= 2 {
                    VStack(spacing: 2) {
                        if l35CountingIndex >= problemNumber {
                            Text("\(problemNumber + 1)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.green)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text(" ").font(.system(size: 20)).opacity(0)
                        }
                        SlimeView(color: l35WalkerColor, size: slimeSize, isSurprised: jumpAll)
                            .offset(x: l35WalkerX)
                            .scaleEffect(l35CountingIndex == problemNumber ? 1.2 : 1.0)
                    }
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: l35CountingIndex)
            .frame(minHeight: 90)

            // STEP 1: 数字表示
            if l35Step == 1 {
                Text("\(problemNumber)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
            }

            // 正解数字ポップ
            if l35AnswerPopScale > 0 {
                Text("\(problemNumber + 1)")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(.green)
                    .scaleEffect(l35AnswerPopScale)
            }
        }
    }

    // MARK: - レベル3.5b: 数の分解（わけると なんにん？）

    private var level35bView: some View {
        let total = problemNumber  // 全体の数
        let leftCount = l5LeftCount
        let rightCount = total - leftCount
        let s = l5SlimeSize

        return ZStack {
            // STEP 0: 全員まとまって表示（中央配置）
            if l5Step == 0 {
                VStack(spacing: 8) {
                    Text("\(total)こ")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                    HStack(spacing: 5) {
                        ForEach(0..<total, id: \.self) { i in
                            SlimeView(
                                color: i < slimeColors.count ? slimeColors[i] : SlimeView.randomColor(),
                                size: s,
                                isSurprised: false
                            )
                        }
                    }
                }
                .transition(.opacity)
            }

            // STEP 1 & 2: 分かれた左右グループ
            if l5Step >= 1 {
                VStack(spacing: 0) {
                    // スライムエリア（固定位置）
                    HStack(spacing: 0) {
                        // 左グループ（既知：数字を表示）
                        VStack(spacing: 4) {
                            Text("\(leftCount)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(.blue)
                                .opacity(l5ShowLeftNum ? 1 : 0)
                            HStack(spacing: 5) {
                                ForEach(0..<leftCount, id: \.self) { i in
                                    SlimeView(
                                        color: i < slimeColors.count ? slimeColors[i] : SlimeView.randomColor(),
                                        size: s,
                                        isSurprised: false
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // 境界線
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 1, height: s + 30)

                        // 右グループ（未知：？→正解で数字に変わる）
                        VStack(spacing: 4) {
                            if l35AnswerPopScale > 0 {
                                Text("\(rightCount)")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(.green)
                                    .scaleEffect(l35AnswerPopScale)
                            } else {
                                Text("?")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(.orange)
                                    .opacity(l5ShowQuestion ? 1 : 0)
                                    .modifier(ShakeModifier(shakes: l5ShakeAmount))
                            }
                            HStack(spacing: 5) {
                                ForEach(0..<rightCount, id: \.self) { i in
                                    let ci = leftCount + i
                                    SlimeView(
                                        color: ci < slimeColors.count ? slimeColors[ci] : SlimeView.randomColor(),
                                        size: s,
                                        isSurprised: jumpAll
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 110)

                    // 「みぎは なんこ？」（右寄せ・スライムの下に固定）
                    if l5ShowQuestion {
                        HStack {
                            Spacer()
                            Text("young4_l5_question")
                                .font(.zenMaru(22, weight: .black))
                                .foregroundStyle(.primary)
                            Spacer().frame(width: 32)
                        }
                        .padding(.top, 16)
                        .transition(.opacity)
                    }
                }
            }
        }
        .frame(height: 200)
    }

    private func startLevel35bSequence() {
        l5Step = 0
        l5SplitOffset = 0
        l5ShowLeftNum = false
        l5ShowQuestion = false
        l35AnswerPopScale = 0

        // STEP 0 → STEP 1: 1.5秒後にじわじわ分かれる
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard selectedLevel == 5 else { return }
            withAnimation(.easeInOut(duration: 1.5)) {
                l5Step = 1
            }
            SoundManager.shared.playTap()
            HapticsManager.tap()

            // 分裂完了後: 左グループの数字を表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                guard selectedLevel == 5 else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    l5ShowLeftNum = true
                }
                SoundManager.shared.playTap()
            }

            // ？ & 質問テキスト表示 → 回答待ち
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                guard selectedLevel == 5 else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    l5ShowQuestion = true
                    l5Step = 2
                }
                SoundManager.shared.playCorrect()
                HapticsManager.tap()
            }
        }
    }

    private func startLevel35Sequence() {
        l35Step = 1
        l35WalkerColor = SlimeView.randomColor()
        l35WalkerX = 300
        l35AnswerPopScale = 0

        // STEP 1 → STEP 2（2秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard selectedLevel == 4 else { return }
            l35Step = 2
            SoundManager.shared.playTap()
            withAnimation(.easeInOut(duration: 1.2)) {
                l35WalkerX = 0
            }
            // STEP 2 → STEP 3（1.5秒後）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                guard selectedLevel == 4 else { return }
                l35Step = 3
                SoundManager.shared.playCorrect()
                HapticsManager.tap()
            }
        }
    }

    // MARK: - スライムグリッド（5つずつ整列）

    @ViewBuilder
    private func slimeGrid(count: Int, startIndex: Int = 0, small: Bool = false) -> some View {
        let s: CGFloat = small ? 38 : slimeSize
        let rows = stride(from: 0, to: count, by: 5).map { i in
            Array(i..<min(i + 5, count))
        }
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { i in
                        let ci = startIndex + i
                        AnimatedSlimeView(
                            color: ci < slimeColors.count ? slimeColors[ci] : SlimeView.randomColor(),
                            size: s,
                            delay: Double(i) * 0.1,
                            isSurprised: jumpAll
                        )
                    }
                }
            }
        }
    }

    // MARK: - 数字ボタン

    @ViewBuilder
    private func numberButton(_ num: Int) -> some View {
        let correctAnswer: Int = {
            switch selectedLevel {
            case 3: return max(problemNumber, problemNumber2)
            case 4: return problemNumber + 1
            case 5: return problemNumber - l5LeftCount
            default: return problemNumber
            }
        }()
        let isCorrect = num == correctAnswer
        let isSelected = selectedAnswer == num

        let bgColor: Color = {
            if showCorrectHighlight && isCorrect { return Color.green }
            if showCorrectHighlight && !isCorrect { return Color.gray.opacity(0.3) }
            if isSelected { return isCorrect ? Color.green : Color.red }
            return Color.blue.opacity(0.85)
        }()

        Button {
            if waitingConfirm {
                // 正解タップ待ち → 正解ボタンのみ受付
                guard isCorrect else { return }
                waitingConfirm = false
                showCorrectHighlight = false
                SoundManager.shared.playCorrect()
                HapticsManager.correct()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { advanceAfterAnswer() }
            } else {
                guard selectedAnswer == nil else { return }
                handleAnswer(num)
            }
        } label: {
            Text("\(num)")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 80)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow, lineWidth: 4)
                        .opacity(hintAnswer == num && hintPulse ? 0.8 : 0)
                        .scaleEffect(hintAnswer == num && hintPulse ? 1.05 : 1.0)
                )
        }
        .disabled(selectedAnswer != nil && !waitingConfirm)
    }

    // MARK: - ロジック

    private func scheduleHint() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            guard selectedAnswer == nil else { return }
            let correct: Int = {
                let level = selectedLevel ?? 1
                switch level {
                case 1: return problemNumber
                case 2: return choices.contains(problemNumber) ? problemNumber : choices.first ?? 0
                default: return problemNumber + problemNumber2
                }
            }()
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                hintAnswer = correct
                hintPulse = true
            }
        }
    }

    private func generateProblem() {
        selectedAnswer = nil
        showCorrectHighlight = false
        waitingConfirm = false
        l3SelectedSide = nil
        l35CountingIndex = -1
        l35AnswerPopScale = 0
        l5Step = 0
        l5SplitOffset = 0
        l5ShowLeftNum = false
        l5ShowQuestion = false
        l5ShakeAmount = 0
        jumpAll = false
        hintAnswer = nil
        hintPulse = false
        problemStartTime = Date()
        scheduleHint()
        let level = selectedLevel ?? 1

        switch level {
        case 1, 2:
            problemNumber = Int.random(in: 1...9)
            slimeColors = (0..<problemNumber).map { _ in SlimeView.randomColor() }
            var c = Set([problemNumber])
            while c.count < 3 {
                let w = Int.random(in: max(1, problemNumber - 3)...min(9, problemNumber + 3))
                if w != problemNumber { c.insert(w) }
            }
            choices = Array(c).shuffled()

        case 3:
            // 差は1〜2、最大5体
            problemNumber = Int.random(in: 2...5)
            let diff = Int.random(in: 1...2)
            problemNumber2 = max(1, problemNumber - diff)
            if Bool.random() { swap(&problemNumber, &problemNumber2) }
            leftGroupColor = SlimeView.palette.randomElement()!
            rightGroupColor = SlimeView.palette.filter { $0 != leftGroupColor }.randomElement()!
            slimeColors = []
            choices = []
            l3Phase = 0; l3Eliminated = 0; l3WinnerJump = false

        case 4:
            // 増えたら何匹？ (N + 1)
            problemNumber = Int.random(in: 1...4)
            slimeColors = (0..<problemNumber).map { _ in SlimeView.randomColor() }
            let correct = problemNumber + 1
            var c = Set([correct])
            while c.count < 3 {
                let w = Int.random(in: max(1, correct - 2)...min(9, correct + 2))
                if w != correct { c.insert(w) }
            }
            choices = Array(c).shuffled()
            // ステップアニメ開始
            startLevel35Sequence()

        case 5:
            // 数の分解: 全体N(3〜5)→ 左M, 右(N-M)
            problemNumber = Int.random(in: 3...5)  // total
            l5LeftCount = Int.random(in: 1...(problemNumber - 1))
            slimeColors = (0..<problemNumber).map { _ in SlimeView.randomColor() }
            let rightCount = problemNumber - l5LeftCount
            var c = Set([rightCount])
            while c.count < 3 {
                let w = Int.random(in: max(1, rightCount - 2)...min(problemNumber, rightCount + 2))
                if w != rightCount { c.insert(w) }
            }
            choices = Array(c).shuffled()
            startLevel35bSequence()

        default: break
        }
    }

    private func handleAnswer(_ answer: Int) {
        selectedAnswer = answer
        let correctAnswer: Int = {
            switch selectedLevel {
            case 3: return max(problemNumber, problemNumber2)
            case 4: return problemNumber + 1
            case 5: return problemNumber - l5LeftCount
            default: return problemNumber
            }
        }()
        let isCorrect = answer == correctAnswer
        let elapsed = Date().timeIntervalSince(problemStartTime)

        SupabaseService.shared.logAnswer(
            operatorSymbol: selectedLevel == 3 ? "＞" : (selectedLevel == 4 ? "＋" : (selectedLevel == 5 ? "分" : "＃")),
            a: problemNumber, b: selectedLevel == 4 ? 1 : (selectedLevel == 5 ? l5LeftCount : (selectedLevel == 3 ? problemNumber2 : 0)),
            correctAnswer: correctAnswer, userAnswer: answer,
            isCorrect: isCorrect,
            responseTimeMs: Int(elapsed * 1000),
            attemptCount: questionIndex + 1
        )

        if isCorrect {
            correctCount += 1
            SoundManager.shared.playCorrect()
            HapticsManager.correct()
            showFlashGreen = true
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { jumpAll = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { jumpAll = false }
                withAnimation(.easeOut(duration: 0.15)) { showFlashGreen = false }
            }
            // レベル3.5: 正解数字ポップ
            if selectedLevel == 4 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    l35AnswerPopScale = 1.0
                }
            }
            // レベル5: ？→数字、スライムがジャンプ
            if selectedLevel == 5 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    l35AnswerPopScale = 1.0
                    l5ShowQuestion = false
                    l5ShowLeftNum = false
                }
            }
        } else {
            SoundManager.shared.playIncorrect()
            HapticsManager.incorrect()
            showFlashRed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.15)) { showFlashRed = false }
            }

            // レベル2: 正解ハイライト → 正解タップ待ち
            if selectedLevel == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCorrectHighlight = true
                    waitingConfirm = true
                }
                return
            }

            // レベル5: ❓シェイク → 正解ハイライト → 正解タップ待ち
            if selectedLevel == 5 {
                withAnimation(.default) { l5ShakeAmount = 3 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    l5ShakeAmount = 0
                    showCorrectHighlight = true
                    waitingConfirm = true
                }
                return
            }

            // レベル4: カウントアニメ → 正解タップ待ち
            if selectedLevel == 4 {
                let total = problemNumber + 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 1体ずつカウント
                    for i in 0..<total {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                            withAnimation { l35CountingIndex = i }
                            SoundManager.shared.playTap()
                            HapticsManager.tap()
                        }
                    }
                    // カウント完了後 → 正解ハイライト
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(total) * 0.4 + 0.3) {
                        showCorrectHighlight = true
                        waitingConfirm = true
                    }
                }
                return
            }
        }

        // 次の問題へ（レベル1,3用）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            advanceAfterAnswer()
        }
    }

    /// 共通: 次の問題 or クリア判定
    private func advanceAfterAnswer() {
        let done = questionIndex + 1 >= totalQuestions
        if done || correctCount >= requiredCorrect {
            vm.correctInSession = correctCount
            vm.totalInSession = done ? totalQuestions : questionIndex + 1
            // 80%以上（8/10）で次レベルアンロック
            if let lv = selectedLevel, correctCount >= 8 {
                DataStore.young4UnlockLevel(lv + 1)

                // レベル5クリア（80%+）→ レベル6アンロック（たすテストボタン表示）
                // 昇格はたす2テスト合格後
            }
            vm.screen = .result
            SoundManager.shared.fadeBGM(duration: 0.5)
            return
        }
        questionIndex += 1
        if questionIndex < totalQuestions {
            withAnimation(.easeOut(duration: 0.15)) { showProblem = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generateProblem()
                withAnimation(.easeOut(duration: 0.2)) { showProblem = true }
            }
        } else {
            vm.correctInSession = correctCount
            vm.totalInSession = totalQuestions
            vm.screen = .result
            SoundManager.shared.fadeBGM(duration: 0.5)
        }
    }
}

// MARK: - シェイクアニメ

private struct ShakeModifier: ViewModifier, Animatable {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func body(content: Content) -> some View {
        content.offset(x: sin(shakes * .pi * 2) * 6)
    }
}
