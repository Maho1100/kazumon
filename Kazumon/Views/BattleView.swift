import SwiftUI

struct BattleView: View {
    @Bindable var vm: GameViewModel

    // シェイク用
    @State private var shakeOffset: CGFloat = 0
    @State private var scoreScale: CGFloat = 1.0
    @State private var lastScore: Int = 0
    @State private var playerFacing: KennyCharacterView.Facing = .left
    @State private var playerRunning = false
    @State private var playerRunOffsetX: CGFloat = -200
    @State private var playerPlayEntrance = false
    @State private var monsterOffsetX: CGFloat = 250
    // フロア連動背景色
    @State private var bgTop = Color(red: 0.72, green: 0.93, blue: 1.0)
    @State private var bgBottom = Color(red: 0.78, green: 0.96, blue: 0.72)

    #if DEBUG
    @State private var pxDistantY: CGFloat = 0
    @State private var pxMiddleY: CGFloat = 0
    @State private var pxForegroundY: CGFloat = 0
    @State private var pxGroundY: CGFloat = 0
    @State private var pxDistantS: CGFloat = 0
    @State private var pxMiddleS: CGFloat = 0
    @State private var pxForegroundS: CGFloat = 0
    @State private var pxGroundS: CGFloat = 0
    @State private var showPxDebug = false
    #endif

    /// じかんどろぼうチュートリアル中に暗くする要素のopacity
    private var tutorialDim: Double { vm.timeBossTutorialActive ? 0.3 : 1.0 }

    /// フロア11以上でダークテーマ（テキスト白）、ボスモードも常にダーク
    private var isDarkTheme: Bool { vm.isMistakeBossMode || vm.isTimeBossMode || vm.floor >= 11 }
    private var textColor: Color { isDarkTheme ? .white : .primary }

    var body: some View {
        ZStack {
            // パララックス背景
            #if DEBUG
            BattleParallaxBackground(
                floor: vm.floor,
                isMistakeBossMode: vm.isMistakeBossMode,
                isTimeBossMode: vm.isTimeBossMode,
                bgTop: bgTop,
                bgBottom: bgBottom,
                speedMultiplier: playerRunning ? 1.0 : 0.15,
                debugDistantY: pxDistantY,
                debugMiddleY: pxMiddleY,
                debugForegroundY: pxForegroundY,
                debugGroundY: pxGroundY,
                debugDistantScale: pxDistantS,
                debugMiddleScale: pxMiddleS,
                debugForegroundScale: pxForegroundS,
                debugGroundScale: pxGroundS
            )
            #else
            BattleParallaxBackground(
                floor: vm.floor,
                isMistakeBossMode: vm.isMistakeBossMode,
                isTimeBossMode: vm.isTimeBossMode,
                bgTop: bgTop,
                bgBottom: bgBottom,
                speedMultiplier: playerRunning ? 1.0 : 0.15
            )
            #endif

            VStack(spacing: 12) {
                // Status bar はZStack最上層に移動済み
                Spacer().frame(height: 70)

                // HP bars
                HPBarView(
                    label: vm.playerData.playerName,
                    emoji: "",
                    current: vm.playerHP,
                    max: vm.playerMaxHP,
                    tint: .red
                )
                .opacity(tutorialDim)

                HPBarView(
                    label: vm.isMistakeBossMode
                        ? NSLocalizedString("mistake_boss_enemy_name", comment: "")
                        : vm.isTimeBossMode
                            ? NSLocalizedString("time_boss_enemy_name", comment: "")
                            : vm.currentMonster.name,
                    emoji: "",
                    current: vm.monsterHP,
                    max: vm.isMistakeBossMode ? MistakeBossConfig.bossHP : vm.currentMonster.maxHP,
                    tint: vm.isMistakeBossMode
                        ? Color(red: 0.8, green: 0, blue: 0)
                        : vm.isTimeBossMode
                            ? Color(red: 0, green: 0.3, blue: 0.8)
                            : .purple
                )
                .opacity(tutorialDim)

                // Characters
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 32) {
                        ZStack {
                            PlayerView(
                                appearance: vm.battleAppearance,
                                isAttacking: vm.isAttacking,
                                isHurt: vm.phase == .incorrect,
                                level: vm.floor,
                                playEntrance: playerPlayEntrance,
                                isRunning: playerRunning,
                                isJoyPose: vm.isJoyPose,
                                facing: playerFacing
                            )
                            .offset(x: playerRunOffsetX, y: 50)
                            .opacity(vm.timeBossTutorialActive ? 0 : 1)
                            .overlay {
                                if vm.showSparkle {
                                    SparkleOverlay()
                                }
                            }

                            if vm.isNearEvolution && vm.phase == .answering {
                                ZStack(alignment: .bottom) {
                                    Text("battle_near_evolution")
                                        .font(.zenMaru(13, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                                        )
                                    Triangle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 7)
                                        .offset(y: 7)
                                }
                                .offset(y: -60)
                                .modifier(FloatingModifier())
                            }
                        }

                        MonsterView(
                            monster: vm.currentMonster,
                            floor: vm.effectiveFloor,
                            isHit: vm.phase == .correct,
                            isDefeated: vm.phase == .defeating,
                            isMistakeBossMode: vm.isMistakeBossMode,
                            isTimeBossMode: vm.isTimeBossMode,
                            isMonsterAttacking: vm.timeBossMonsterAttacking,
                            currentHP: vm.monsterHP,
                            maxHP: vm.isMistakeBossMode ? MistakeBossConfig.bossHP : vm.currentMonster.maxHP,
                            questionsAnswered: vm.questionsAnswered,
                            totalQuestions: vm.isMistakeBossMode ? MistakeBossConfig.bossHP : vm.currentMonster.questionsPerFloor
                        )
                        .offset(x: monsterOffsetX)
                        .offset(y: 50)
                    }
                    .frame(height: 200, alignment: .center)

                    // 地面ライン
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isDarkTheme
                            ? Color.white.opacity(0.2)
                            : Color.black.opacity(0.1))
                        .frame(height: 3)
                        .padding(.horizontal, 30)
                        .offset(y: 50)
                        .opacity(tutorialDim)
                }

                // Floating text
                if let text = vm.floatingText {
                    FloatingText(text: text)
                        .id(text + String(vm.totalInSession))
                }

                // 不正解演出: 敵ニヤリ吹き出し
                Text("battle_enemy_smirk")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1))
                    .offset(x: 50, y: -20)
                    .opacity(vm.showEnemySmirk ? 1 : 0)

                // コンボ3吹き出し
                Text(vm.comboBubbleText)
                    .font(.zenMaru(16, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2))
                    .offset(x: -50, y: -30)
                    .opacity(vm.showComboBubble ? 1 : 0)

                // Combo display (below characters)
                ComboView(
                    combo: vm.combo,
                    multiplier: vm.comboMultiplier,
                    label: vm.comboLabel,
                    stageIcon: vm.comboStageIcon,
                    gaugeProgress: vm.comboGaugeProgress
                )
                .opacity(tutorialDim)

                if vm.phase != .evolving {
                    // Review badge & Problem
                    VStack(spacing: 8) {
                        if vm.currentProblem.isReview {
                            HStack(spacing: 4) {
                                Text("🔁")
                                Text("view_battle_review")
                                    .font(.zenMaru(12, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                        }

                        Text("\(vm.currentProblem.a) \(vm.currentProblem.operatorSymbol) \(vm.currentProblem.b) = ?")
                            .font(.zenMaru(42, weight: .black))
                            .monospacedDigit()
                            .foregroundColor(textColor)
                    }
                    .padding(.bottom, 16)
                    .opacity(tutorialDim)

                    // Timer bar
                    if (vm.currentMonster.timeLimit != nil || vm.isTimeBossMode) && vm.phase == .answering {
                        TimerBarView(
                            remaining: vm.timerRemaining,
                            total: vm.timerTotal,
                            pulseHighlight: vm.timeBossTutorialActive,
                            stolenFlash: vm.timeBossTimerStolen
                        )
                    }

                    // Choice buttons (2x2 grid)
                    let choices = vm.currentProblem.choices
                    let isConfirm = vm.phase == .confirmCorrect
                    VStack(spacing: 6) {
                        HStack(spacing: 12) {
                            ForEach(0..<min(2, choices.count), id: \.self) { i in
                                ChoiceButton(
                                    number: choices[i],
                                    correctAnswer: vm.currentProblem.answer,
                                    selectedAnswer: vm.selectedAnswer,
                                    combo: vm.combo,
                                    isDisabled: (vm.phase != .answering && !isConfirm) || vm.isPaused,
                                    showCorrectHighlight: vm.showCorrectHighlight,
                                    isMistakeBossMode: vm.isMistakeBossMode,
                                    isTimeBossMode: vm.isTimeBossMode
                                ) {
                                    if isConfirm {
                                        vm.confirmCorrectAnswer(choices[i])
                                    } else {
                                        vm.selectAnswer(choices[i])
                                    }
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            ForEach(2..<min(4, choices.count), id: \.self) { i in
                                ChoiceButton(
                                    number: choices[i],
                                    correctAnswer: vm.currentProblem.answer,
                                    selectedAnswer: vm.selectedAnswer,
                                    combo: vm.combo,
                                    isDisabled: (vm.phase != .answering && !isConfirm) || vm.isPaused,
                                    showCorrectHighlight: vm.showCorrectHighlight,
                                    isMistakeBossMode: vm.isMistakeBossMode,
                                    isTimeBossMode: vm.isTimeBossMode
                                ) {
                                    if isConfirm {
                                        vm.confirmCorrectAnswer(choices[i])
                                    } else {
                                        vm.selectAnswer(choices[i])
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .opacity(tutorialDim)
                }
            }
            // シェイク効果（ボス登場時にコンテンツ全体を揺らす）
            .offset(x: shakeOffset)

            // コンボ節目フラッシュ（5/10/15/20 到達時）
            ComboFlashView(combo: vm.combo)

            // Overlays
            if vm.phase == .bossAppearing {
                BossOverlay(monster: vm.currentMonster)
            }

            // ボス撃破演出
            if vm.phase == .defeating && vm.currentMonster.isBoss {
                BossDefeatedOverlay()
            }

            // バトル中進化演出
            if vm.phase == .evolving {
                EvolutionBattleOverlay(newStage: vm.sessionEvolutionStage)
            }

            if vm.phase == .gameOver {
                GameOverOverlay(appearance: vm.battleAppearance)
            }

            if vm.showComboBreak {
                ComboBreakOverlay(combo: vm.comboBeforeBreak)
            }

            if vm.showFloorBanner  && vm.phase != .bossAppearing {
                FloorBannerView(floor: vm.floor)
                    .id("floor-\(vm.floor)")
            }

            // Daily bonus overlay
            if vm.showDailyBonus {
                Color.black.opacity(0.4).ignoresSafeArea()
                DailyBonusOverlay(xp: vm.dailyBonusXP) {
                    vm.showDailyBonus = false
                }
            }


            // ゴールクリアポップアップ
            if vm.reachedGoalFloor {
                GoalClearPopupView(
                    onFinish: { vm.finishAfterGoal() },
                    onContinue: { vm.continueAfterGoal() }
                )
                .zIndex(200)
            }

            // Status bar（ZStack最上層＝タップ確実に届く）
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        // フロア表示のみ（進捗バーは削除）
                        Text("\(vm.floor)F")
                            .font(.zenMaru(20, weight: .bold))
                            .foregroundColor(isDarkTheme ? .white : .primary)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                    }
                    .padding(.bottom, 4)
                    Spacer()
                    HStack(spacing: 8) {
                        Text(String(format: NSLocalizedString(
                            "view_battle_score", comment: ""), vm.score))
                            .font(.zenMaru(17, weight: .bold))
                            .monospacedDigit()
                            .foregroundColor(vm.score > lastScore && lastScore > 0 ? .yellow : textColor)
                            .scaleEffect(scoreScale)
                            .onChange(of: vm.score) { _, newScore in
                                if newScore > lastScore {
                                    withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                                        scoreScale = 1.5
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                            scoreScale = 1.0
                                        }
                                    }
                                }
                                lastScore = newScore
                            }
                        Button {
                            HapticsManager.tap(); SoundManager.shared.playTap()
                            vm.pauseGame()
                        } label: {
                            Text("battle_quit_button")
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 1.0, green: 0.78, blue: 0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.orange.opacity(0.5), radius: 4, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .allowsHitTesting(true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
            .allowsHitTesting(true)
            .zIndex(100)

            #if DEBUG
            // パララックスデバッグ
            VStack {
                HStack {
                    Button(showPxDebug ? "BG ✕" : "BG") { showPxDebug.toggle() }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(6)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                    Spacer()
                }
                .padding(.leading, 16).padding(.top, 10)

                if showPxDebug {
                    VStack(spacing: 3) {
                        HStack {
                            Text("パララックス調整").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            Button("コピー") {
                                print("distant(Y:\(Int(pxDistantY)),S:\(String(format:"%.2f",pxDistantS))) middle(Y:\(Int(pxMiddleY)),S:\(String(format:"%.2f",pxMiddleS))) fg(Y:\(Int(pxForegroundY)),S:\(String(format:"%.2f",pxForegroundS))) gnd(Y:\(Int(pxGroundY)),S:\(String(format:"%.2f",pxGroundS)))")
                            }.font(.system(size: 10)).foregroundColor(.yellow)
                        }
                        pxSlider("遠景Y", $pxDistantY, -600...600, .green)
                        pxSlider("遠景S", $pxDistantS, -0.8...2.0, .green.opacity(0.6))
                        pxSlider("中景Y", $pxMiddleY, -600...300, .cyan)
                        pxSlider("中景S", $pxMiddleS, -0.8...2.0, .cyan.opacity(0.6))
                        pxSlider("近景Y", $pxForegroundY, -600...500, .orange)
                        pxSlider("近景S", $pxForegroundS, -2.0...2.0, .orange.opacity(0.6))
                        pxSlider("地面Y", $pxGroundY, -600...600, .red)
                        pxSlider("地面S", $pxGroundS, -0.8...2.0, .red.opacity(0.6))
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.85)))
                    .padding(.horizontal, 12)
                }
                Spacer()
            }
            .zIndex(998)
            #endif

            // Pause overlay
            if vm.isPaused {
                PauseOverlay(
                    onResume: { vm.resumeGame() },
                    onQuit: { vm.quitGame() }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .onAppear {
            AnalyticsManager.trackScreenEnter("battle")
            updateBGColors(for: vm.floor)
            startBattleEntrance()
        }
        .onChange(of: vm.phase) { _, newPhase in
            if newPhase == .bossAppearing {
                runShake()
            }
            if newPhase == .defeating && vm.currentMonster.isBoss {
                // ボス撃破: 喜びポーズ → 走り退場 → フロア遷移
                playerFacing = .front
                playerPlayEntrance = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    guard vm.phase == .defeating else { return }
                    playerPlayEntrance = false
                    playerFacing = .right

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        playerRunning = true
                        withAnimation(.easeIn(duration: 0.6)) {
                            playerRunOffsetX = 400
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        playerRunning = false
                    }
                }
            } else if newPhase == .defeating {
                // 通常敵撃破: 正面向いて少し待つだけ（すぐフロア遷移）
                playerFacing = .front
            }
        }
        .onChange(of: vm.floor) { _, newFloor in
            withAnimation(.easeInOut(duration: 1.2)) {
                updateBGColors(for: newFloor)
            }
            startBattleEntrance()
        }
        .onChange(of: vm.combo) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                updateBGColors(for: vm.floor)
            }
        }
    }

    // MARK: - フロア連動背景色

    private func updateBGColors(for floor: Int) {
        if vm.isMistakeBossMode {
            bgTop    = Color(red: 0.15, green: 0, blue: 0.1)
            bgBottom = Color(red: 0.3, green: 0, blue: 0)
            return
        }
        if vm.isTimeBossMode {
            bgTop    = Color(red: 0, green: 0, blue: 0.2)
            bgBottom = Color(red: 0, green: 0.1, blue: 0.4)
            return
        }

        let boost: Double = vm.combo >= 5 ? 0.05 : 0

        switch floor {
        case 1...4:
            // 草原（スライム）
            bgTop    = Color(red: 0.72 + boost, green: 0.93 + boost, blue: 1.0)
            bgBottom = Color(red: 0.78 + boost, green: 0.96 + boost, blue: 0.72 + boost)
        case 5:
            // 草原・夕方（ボス）
            bgTop    = Color(red: 0.90 + boost, green: 0.65 + boost, blue: 0.35 + boost)
            bgBottom = Color(red: 0.70 + boost, green: 0.85 + boost, blue: 0.55 + boost)
        case 6...9:
            // 洞窟（ゴブリン）
            bgTop    = Color(red: 0.70 + boost, green: 0.55 + boost, blue: 0.40 + boost)
            bgBottom = Color(red: 0.50 + boost, green: 0.48 + boost, blue: 0.45 + boost)
        case 10:
            // 洞窟・深部（ボス）
            bgTop    = Color(red: 0.50 + boost, green: 0.38 + boost, blue: 0.28 + boost)
            bgBottom = Color(red: 0.35 + boost, green: 0.33 + boost, blue: 0.30 + boost)
        case 11...14:
            // 城（オーク）
            bgTop    = Color(red: 0.55 + boost, green: 0.55 + boost, blue: 0.80 + boost)
            bgBottom = Color(red: 0.45 + boost, green: 0.45 + boost, blue: 0.55 + boost)
        case 15:
            // 城・玉座（ボス）
            bgTop    = Color(red: 0.38 + boost, green: 0.35 + boost, blue: 0.65 + boost)
            bgBottom = Color(red: 0.28 + boost, green: 0.28 + boost, blue: 0.40 + boost)
        case 16...19:
            // 魔王の城（ドラゴン）
            bgTop    = Color(red: 0.15 + boost, green: 0.13 + boost, blue: 0.40 + boost)
            bgBottom = Color(red: 0.55 + boost, green: 0.15 + boost, blue: 0.12 + boost)
        case 20:
            // 溶岩（ボス）
            bgTop    = Color(red: 0.10 + boost, green: 0.08 + boost, blue: 0.30 + boost)
            bgBottom = Color(red: 0.70 + boost, green: 0.12 + boost, blue: 0.08 + boost)
        case 21...29:
            // 闇（デーモン）
            bgTop    = Color(red: 0.12 + boost, green: 0.08 + boost, blue: 0.22 + boost)
            bgBottom = Color(red: 0.10 + boost, green: 0.06 + boost, blue: 0.18 + boost)
        case 30:
            // 最終決戦（まおう）
            bgTop    = Color(red: 0.06 + boost, green: 0.04 + boost, blue: 0.12 + boost)
            bgBottom = Color(red: 0.08 + boost, green: 0.05 + boost, blue: 0.15 + boost)
        default:
            // 完全な闇（31F以上 ???）
            bgTop    = Color(red: 0.02 + boost, green: 0.02 + boost, blue: 0.02 + boost)
            bgBottom = Color(red: 0.0 + boost, green: 0.0 + boost, blue: 0.0 + boost)
        }
    }

    #if DEBUG
    private func pxSlider(_ label: String, _ value: Binding<CGFloat>, _ range: ClosedRange<CGFloat>, _ color: Color) -> some View {
        HStack {
            Text(label).font(.system(size: 10)).foregroundColor(.white).frame(width: 36, alignment: .leading)
            Slider(value: value, in: range).tint(color)
            Text(range.upperBound > 10 ? "\(Int(value.wrappedValue))" : String(format: "%.2f", value.wrappedValue))
                .font(.system(size: 10, design: .monospaced)).foregroundColor(.white).frame(width: 35)
        }
    }
    #endif

    // MARK: - シェイク演出

    private func startBattleEntrance() {
        playerRunning = false
        playerPlayEntrance = false
        playerFacing = .left

        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            playerRunOffsetX = -200
            monsterOffsetX = 250
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            playerRunning = true
            withAnimation(.easeOut(duration: 0.6)) {
                playerRunOffsetX = 0
            }
            withAnimation(.easeOut(duration: 0.5)) {
                monsterOffsetX = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            playerRunning = false
            playerFacing = .left
        }
    }

    private func runShake() {
        let steps: [(offset: CGFloat, delay: Double)] = [
            ( 6, 0.00),
            (-5, 0.05),
            ( 4, 0.10),
            (-4, 0.15),
            ( 3, 0.20),
            (-2, 0.25),
            ( 2, 0.30),
            (-1, 0.35),
            ( 1, 0.40),
            ( 0, 0.45),
        ]
        for step in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
                withAnimation(.linear(duration: 0.04)) {
                    shakeOffset = step.offset
                }
            }
        }
    }
}

// MARK: - Floating Modifier

private struct FloatingModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                ) { offset = -6 }
            }
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
