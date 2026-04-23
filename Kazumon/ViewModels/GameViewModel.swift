import Foundation
import Combine
import SwiftUI
import StoreKit

@Observable
final class GameViewModel {
    // MARK: - Screen State
    var screen: GameScreen = .title
    var phase: BattlePhase = .answering

    // MARK: - Battle State
    var floor: Int = 1
    var score: Int = 0
    var combo: Int = 0
    var maxCombo: Int = 0
    var playerHP: Int = 3
    var playerMaxHP: Int = 3
    var currentMonster: Monster = Monster.forFloor(1)
    var monsterHP: Int = 1
    var currentProblem: Problem = Problem.generate(floor: 1, mistakeLog: [])
    var questionsAnswered: Int = 0
    var correctInSession: Int = 0
    var totalInSession: Int = 0

    // MARK: - XP / Items
    var earnedXP: Int = 0
    var earnedItems: [Item] = []
    var isNewRecord: Bool = false
    var didLevelUp: Bool = false
    var newLevel: Int = 1

    // MARK: - Timer
    var timerRemaining: Double = 0
    var timerTotal: Double = 0
    private var timerCancellable: AnyCancellable?

    // MARK: - Answer Time Tracking
    private var problemStartTime: Date = Date()
    private var currentSessionLogs: [AnswerTimeLog] = []

    // MARK: - Session Tracking
    var startTime: Date?
    var playerData: PlayerData = DataStore.loadPlayerData()
    var mistakeLog: [MistakeEntry] = DataStore.loadMistakeLog()
    var dailyMission: DailyMission = DataStore.loadDailyMission()

    // MARK: - Feedback
    var floatingText: String?
    var selectedAnswer: Int?
    var showDailyBonus: Bool = false
    var dailyBonusXP: Int = 0

    // MARK: - Combo Effects
    var showComboBreak: Bool = false
    var comboBeforeBreak: Int = 0
    var showCorrectHighlight: Bool = false

    // MARK: - Floor Banner
    var showFloorBanner: Bool = false

    // MARK: - Supabase Session
    private var supabaseSessionId: String?

    // MARK: - Evolution
    var didEvolve: Bool = false

    // MARK: - Battle Evolution (フロアベースのセッション進化)
    var sessionEvolutionStage: CharacterEvolutionStage = .base
    var isNearEvolution: Bool = false
    var showSparkle: Bool = false

    // MARK: - Rock Break Animation
    /// リザルトからタイトルに戻る際、破壊演出の起点となる旧 playCount を保持する。
    /// TitleView が読み取った後 nil にリセットされる。
    var pendingBreakFromIndex: Int? = nil

    // MARK: - Streak
    var streakMilestone: Int? = nil

    // MARK: - Share Bonus
    var showShareBonusPopup: Bool = false
    var canReceiveShareBonus: Bool = false

    func grantShareBonus() {
        guard canReceiveShareBonus else { return }
        if !PurchaseManager.shared.isPro {
            var mission = DataStore.loadDailyMission()
            if mission.playCount >= PurchaseManager.maxFreePlayCount {
                mission.playCount = max(0, mission.playCount - 1)
                DataStore.saveDailyMission(mission)
                dailyMission = mission
            }
        }
        DataStore.markShareBonusReceived()
        canReceiveShareBonus = false
        showShareBonusPopup = true
    }

    func checkShareBonus() {
        canReceiveShareBonus = !DataStore.hasReceivedShareBonusToday()
    }

    // MARK: - Attack Animation
    var isAttacking: Bool = false
    var isJoyPose: Bool = false

    private func triggerAttackAnimation() {
        withAnimation(.easeOut(duration: 0.15)) {
            isAttacking = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeIn(duration: 0.2)) {
                isAttacking = false
            }
        }
    }

    // MARK: - 不正解演出
    var showIncorrectReaction = false
    var showEnemySmirk = false

    // MARK: - コンボ吹き出し
    var comboBubbleText = ""
    var showComboBubble = false

    // MARK: - Pause
    var isPaused: Bool = false

    // MARK: - Floor Limit
    var didReachFloorLimit: Bool = false

    // MARK: - Difficulty & Problem Type
    var difficulty: Difficulty = DataStore.loadDifficulty()
    var problemType: ProblemType = .mixed

    // MARK: - 30日チャレンジ
    var challengeDay: Int? = nil  // nil = フリープレイ
    var challengeRequiredCorrect: Int = 10
    var showCertificate: Bool = false
    var showAfterTest: Bool = false
    var showVersus: Bool = false
    var playLimitReached: Bool = false
    var comebackBonus: Int = 0
    var gachaItem: Item?
    var showGachaPull: Bool = false
    var versusIsFamily: Bool = false

    // MARK: - 家族モード（NPCモード／パス＆プレイ）
    var isFamilyNPCMode: Bool = false
    var currentFamilyMember: FamilyMember? = nil
    var showFamilyRanking: Bool = false
    var familyScoreUpdated: Bool = false  // 直前のバトルでベスト更新したか
    var challengeMonster: MonsterChoice? = nil  // 挑戦状で選んだモンスター（nil=デフォルト1F）
    var versusBGM: String? = nil  // 対戦BGM選択（nilなら通常BGM）

    /// 家族モードのフラグを完全リセット（ランキング画面を閉じる時に呼ぶ）
    func clearFamilyMode() {
        isFamilyNPCMode = false
        currentFamilyMember = nil
        showFamilyRanking = false
        familyScoreUpdated = false
        challengeMonster = nil
        versusBGM = nil
    }
    var showAdditionCheck: Bool = false
    var pendingCertificate: Bool = false
    var refreshTrigger: Int = 0  // body再評価用トグル

    // MARK: - サイレントレベル判定（初回バトル内ビフォーテスト）
    private var silentTestActive = false
    private var silentTestLevel = 1
    private var silentTestMaxLevel = 1
    private var silentTestCount = 0
    private let silentTestTotal = 8

    private func completeSilentTest() {
        silentTestActive = false
        DataStore.saveBeforeTestResult(score: silentTestCount, total: silentTestTotal, level: silentTestMaxLevel)
        print("[SilentTest] Completed: maxLevel=\(silentTestMaxLevel), correct=\(correctInSession)/\(silentTestTotal)")
    }

    // MARK: - まちがいおに
    var isMistakeBossMode: Bool = false
    var mistakeBossProblems: [MistakeEntry] = []
    var mistakeBossDefeated: Bool = false
    var shouldShowMistakeWarning: Bool = false

    // MARK: - じかんどろぼう
    var isTimeBossMode: Bool = false
    var timeBossDefeated: Bool = false
    var shouldShowTimeBossWarning: Bool = false
    var timeBossTutorialActive: Bool = false   // 1F演出中（暗転＋タイマーパルス）
    var timeBossMonsterAttacking: Bool = false // 敵の時間泥棒アニメ中
    var timeBossTimerStolen: Bool = false      // タイマーが奪われた瞬間（1秒間色変え）
    var reachedGoalFloor: Bool = false
    private var hasPassedGoal: Bool = false

    var playerAppearance: CharacterAppearance {
        CharacterAppearanceFactory.appearance(for: playerData.level)
    }

    var currentEvolutionStage: CharacterEvolutionStage {
        CharacterAppearanceFactory.stage(for: playerData.level)
    }

    var battleAppearance: CharacterAppearance {
        CharacterAppearanceFactory.appearance(for: sessionEvolutionStage)
    }

    // MARK: - Computed

    var comboMultiplier: Int {
        switch combo {
        case 0...4:   return 1
        case 5...9:   return 2
        case 10...14: return 3
        case 15...19: return 4
        default:      return 5
        }
    }

    var comboLabel: String? {
        switch combo {
        case 5:  return "NICE!"
        case 10: return "SUPER!"
        case 15: return "AMAZING!"
        case 20: return "LEGENDARY!"
        default: return nil
        }
    }

    var comboStageIcon: String {
        switch combo {
        case 0...4:   return ""
        case 5...9:   return "🔥"
        case 10...14: return "🔥🔥"
        case 15...19: return "🔥🔥🔥"
        default:      return "⚡✨"
        }
    }

    var comboGaugeProgress: Double {
        guard combo > 0 else { return 0 }
        return min(1.0, Double(combo) / 20.0)
    }

    var monsterProgress: Double {
        guard currentMonster.maxHP > 0 else { return 0 }
        return Double(currentMonster.maxHP - monsterHP) / Double(currentMonster.maxHP)
    }

    var playerHPProgress: Double {
        guard playerMaxHP > 0 else { return 0 }
        return Double(playerHP) / Double(playerMaxHP)
    }

    // MARK: - Game Flow

    func startGame(difficulty: Difficulty? = nil) {
        if let difficulty {
            self.difficulty = difficulty
            DataStore.saveDifficulty(difficulty)
        }

        // 最新のプレイヤーデータを再読み込み（デバッグリセット対応）
        playerData = DataStore.loadPlayerData()

        // Play limit check (free users: 3 plays/day)
        let todayCount = DataStore.todayPlayCount()
        let isPro = PurchaseManager.shared.isPro
        print("🎮 [startGame] isPro=\(isPro), todayPlayCount=\(todayCount), max=\(PurchaseManager.maxFreePlayCount)")
        guard isPro || todayCount < PurchaseManager.maxFreePlayCount else {
            print("🎮 [startGame] ⛔ BLOCKED — limit reached")
            playLimitReached = true
            AnalyticsManager.logFreePlayLimitHit(playCount: todayCount)
            return
        }

        // Check daily bonus
        if DataStore.checkDailyBonus() {
            dailyBonusXP = DataStore.claimDailyBonus()
            _ = DataStore.addXP(dailyBonusXP, to: &playerData)
            DataStore.savePlayerData(playerData)
            showDailyBonus = true
        }

        // ストリーク更新は endGame() で処理

        // Reset battle state
        floor = 1
        score = 0
        combo = 0
        maxCombo = 0
        playerHP = 3
        playerMaxHP = 3
        earnedXP = 0
        earnedItems = []
        isNewRecord = false
        didLevelUp = false
        questionsAnswered = 0
        correctInSession = 0
        totalInSession = 0
        startTime = Date()
        selectedAnswer = nil
        showComboBreak = false
        comboBeforeBreak = 0
        showFloorBanner = false
        showCorrectHighlight = false
        didEvolve = false
        didReachFloorLimit = false
        reachedGoalFloor = false
        hasPassedGoal = false
        currentSessionLogs = []
        sessionEvolutionStage = .base
        isNearEvolution = false
        showSparkle = false
        isPaused = false
        challengeCleared = false
        // まちがいおにモードは startMistakeBoss() で startGame() 後に再設定
        isMistakeBossMode = false
        mistakeBossProblems = []
        mistakeBossDefeated = false
        // じかんどろぼうモードは startTimeBoss() で startGame() 後に再設定
        isTimeBossMode = false
        timeBossDefeated = false
        timeBossTutorialActive = false
        timeBossMonsterAttacking = false
        timeBossTimerStolen = false

        mistakeLog = DataStore.loadMistakeLog()

        // まほうのじかん日数カウント + じかんどろぼうトリガー
        if MagicTimeConfig.isMagicTime(
            start: DataStore.loadMagicTimeStart(),
            end: DataStore.loadMagicTimeEnd()
        ) {
            DataStore.incrementMagicTimeDayCount()
            let count = DataStore.loadMagicTimeDayCount()
            if count >= MagicTimeConfig.timeBossTriggerCount
                && !DataStore.isTimeBossDefeated()
                && !DataStore.isTimeBossScheduledToday() {
                DataStore.scheduleTimeBoss()
                DataStore.resetMagicTimeDayCount()
            }
        }

        // サイレントレベル判定: 初回バトルで自動的にレベル判定
        if !DataStore.hasCompletedBeforeTest() && DataStore.loadAgeGroup() != .young4 {
            silentTestActive = true
            silentTestLevel = 1
            silentTestMaxLevel = 1
            silentTestCount = 0
        } else {
            silentTestActive = false
        }

        setupFloor()
        screen = .battle
        phase = .answering
        if let bgm = versusBGM {
            SoundManager.shared.playBGMBattle(override: bgm)
        } else {
            SoundManager.shared.playBGMBattle()
        }
        AnalyticsManager.logBattleStart(ageGroup: DataStore.loadAgeGroup().rawValue, difficulty: self.difficulty.rawValue)

        // Supabase セッション作成（バックグラウンド）
        let contentType: String
        switch problemType {
        case .addition:    contentType = "addition"
        case .subtraction: contentType = "subtraction"
        case .mixed:       contentType = "mixed"
        }
        supabaseSessionId = nil
        Task { @MainActor [weak self] in
            let id = await SupabaseService.shared.createSession(contentType: contentType)
            self?.supabaseSessionId = id
        }
    }

    /// 挑戦状モード: 実フロア → Monster.forFloor用の仮想フロアに変換
    /// 1〜4F: 一つ下のモンスター（ザコ）、5F: 選んだモンスター（ボス）
    var effectiveFloor: Int { challengeVirtualFloor(floor) }

    private func challengeVirtualFloor(_ actualFloor: Int) -> Int {
        guard let challenge = challengeMonster, isFamilyNPCMode else { return actualFloor }
        if actualFloor < 3 {
            let prev = challenge.previousTier ?? challenge
            return prev.startFloor + (actualFloor - 1)
        } else {
            return challenge.bossFloor
        }
    }

    func setupFloor() {
        let virtualFloor = challengeVirtualFloor(floor)
        currentMonster = Monster.forFloor(virtualFloor)
        monsterHP = currentMonster.maxHP
        print("🎮 [setupFloor] floor=\(floor) virtualFloor=\(virtualFloor) monster=\(currentMonster.name) isBoss=\(currentMonster.isBoss) hp=\(monsterHP) challengeMonster=\(String(describing: challengeMonster)) isFamilyNPC=\(isFamilyNPCMode)")

        if currentMonster.isBoss && floor > 1 {
            phase = .bossAppearing
            HapticsManager.bossAppear()
            SoundManager.shared.playBossAppear()
            scheduleTransition(after: 2.3) { [weak self] in
                self?.phase = .answering
                self?.nextProblem()
                self?.startTimerIfNeeded()
            }
        } else {
            nextProblem()
            startTimerIfNeeded()
        }
    }

    func nextProblem() {
        selectedAnswer = nil
        let effectiveFloor = challengeVirtualFloor(floor)
        if isMistakeBossMode, !mistakeBossProblems.isEmpty {
            // まちがいおにモード: MistakeLogからランダムで出題
            let entry = mistakeBossProblems.randomElement()!
            currentProblem = Problem.generate(floor: effectiveFloor, mistakeLog: [entry], difficulty: difficulty, problemType: problemType)
        } else if let day = challengeDay {
            // チャレンジモード: フェーズ別のマスター問題を生成
            let phase = ChallengeConfig.masteryPhase(for: day)
            currentProblem = Problem.generateMastery(phase: phase)
        } else {
            currentProblem = Problem.generate(floor: effectiveFloor, mistakeLog: mistakeLog, difficulty: difficulty, problemType: problemType)
        }
        problemStartTime = Date()
    }

    // MARK: - Answer Selection

    func selectAnswer(_ answer: Int) {
        guard phase == .answering else { return }

        let elapsed = Date().timeIntervalSince(problemStartTime)
        let isCorrect = answer == currentProblem.answer
        currentSessionLogs.append(AnswerTimeLog(
            problemIndex: totalInSession,
            isCorrect: isCorrect,
            elapsedSeconds: elapsed
        ))

        selectedAnswer = answer
        totalInSession += 1
        stopTimer()

        // Supabase answer_logs に送信（バックグラウンド）
        SupabaseService.shared.logAnswer(
            operatorSymbol: currentProblem.operatorSymbol,
            a: currentProblem.a,
            b: currentProblem.b,
            correctAnswer: currentProblem.answer,
            userAnswer: answer,
            isCorrect: isCorrect,
            responseTimeMs: Int(elapsed * 1000),
            attemptCount: totalInSession
        )

        if answer == currentProblem.answer {
            handleCorrect()
        } else {
            handleIncorrect(selected: answer)
        }
    }

    private func handleCorrect() {
        triggerAttackAnimation()
        phase = .correct
        combo += 1
        maxCombo = max(maxCombo, combo)
        correctInSession += 1

        // サイレントレベル判定: 正解→レベルUP
        if silentTestActive {
            silentTestCount += 1
            silentTestLevel = min(silentTestLevel + 1, 8)
            silentTestMaxLevel = max(silentTestMaxLevel, silentTestLevel)
            if silentTestCount >= silentTestTotal {
                completeSilentTest()
            }
        }

        // コンボ3で吹き出し
        if combo == 3 {
            comboBubbleText = NSLocalizedString("combo_bubble_3", comment: "")
            showComboBubble = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showComboBubble = false
            }
        }

        // コンボ5ごとに喜びポーズ
        if combo > 0 && combo % 5 == 0 {
            isJoyPose = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isJoyPose = false
            }
        }

        // コンボ5ごとにおうえんボイス再生
        if combo > 0 && combo % 5 == 0 && DataStore.hasParentVoiceRecording() {
            SoundManager.shared.playParentVoice()
        }

        let baseXP = 10
        let speedBonus: Int = {
            let t = Date().timeIntervalSince(problemStartTime)
            if t < 1.5 { return 10 }
            if t < 3.0 { return 5 }
            if t < 5.0 { return 2 }
            return 0
        }()
        let xpGained = baseXP * comboMultiplier + speedBonus
        score += xpGained
        earnedXP += xpGained

        // マスター度記録
        DataStore.recordCorrectProblem(
            a: currentProblem.a,
            b: currentProblem.b,
            operatorSymbol: currentProblem.operatorSymbol
        )

        // If review problem answered correctly, mark as reviewed
        if currentProblem.isReview {
            DataStore.markReviewed(a: currentProblem.a, b: currentProblem.b)
            mistakeLog = DataStore.loadMistakeLog()
        }

        // チャレンジモードのクリア判定
        checkChallengeComplete()
        checkMistakeBossComplete()
        checkTimeBossComplete()

        SoundManager.shared.playCorrect()
        SoundManager.shared.updateBGMRate(forCombo: combo)
        HapticsManager.correct()

        floatingText = "+\(xpGained)XP"

        monsterHP -= 1

        if monsterHP <= 0 {
            scheduleTransition(after: 0.6) { [weak self] in
                self?.handleMonsterDefeated()
            }
        } else {
            scheduleTransition(after: 0.6) { [weak self] in
                self?.phase = .answering
                self?.nextProblem()
                self?.startTimerIfNeeded()
            }
        }
    }

    private func handleIncorrect(selected: Int) {
        phase = .incorrect
        if combo > 2 {
            comboBeforeBreak = combo
            showComboBreak = true
        }
        combo = 0
        playerHP -= 1

        // サイレントレベル判定: 不正解→レベルDOWN
        if silentTestActive {
            silentTestCount += 1
            silentTestLevel = max(1, silentTestLevel - 1)
            if silentTestCount >= silentTestTotal {
                completeSilentTest()
            }
        }

        // Log mistake + 累計カウンター
        DataStore.addMistake(
            a: currentProblem.a,
            b: currentProblem.b,
            answer: currentProblem.answer,
            wrongAnswer: selected
        )
        DataStore.incrementTotalMistakeCount()
        mistakeLog = DataStore.loadMistakeLog()

        SoundManager.shared.playIncorrect()
        SoundManager.shared.resetBGMRate()
        HapticsManager.incorrect()

        // 不正解演出: キャラ「え？」+ 敵ニヤリ
        showIncorrectReaction = true
        showEnemySmirk = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.showIncorrectReaction = false
            self?.showEnemySmirk = false
        }

        floatingText = String(format: NSLocalizedString("floating_answer", comment: ""), currentProblem.answer)

        if playerHP <= 0 {
            scheduleTransition(after: 1.0) { [weak self] in
                self?.handleGameOver()
            }
        } else {
            // 正解タップ待ちフェーズへ移行
            scheduleTransition(after: 0.6) { [weak self] in
                self?.showComboBreak = false
                self?.selectedAnswer = nil
                self?.showCorrectHighlight = true
                self?.phase = .confirmCorrect
                self?.floatingText = nil
            }
        }
    }

    /// 不正解後に正解ボタンをタップしたとき
    func confirmCorrectAnswer(_ answer: Int) {
        guard phase == .confirmCorrect else { return }
        guard answer == currentProblem.answer else { return }

        showCorrectHighlight = false
        selectedAnswer = answer
        SoundManager.shared.playCorrect()
        HapticsManager.correct()
        floatingText = nil

        scheduleTransition(after: 0.5) { [weak self] in
            self?.phase = .answering
            self?.nextProblem()
            self?.startTimerIfNeeded()
        }
    }

    // MARK: - Monster Defeated

    private func handleMonsterDefeated() {
        phase = .defeating
        SoundManager.shared.playDefeat()

        // Boss drop: 30% chance
        if currentMonster.isBoss {
            if Int.random(in: 1...100) <= 30, let item = Item.randomDrop() {
                earnedItems.append(item)
                DataStore.addItem(item)
            }
        }

        let defeatWait = currentMonster.isBoss ? 1.2 : 0.4
        scheduleTransition(after: defeatWait) { [weak self] in
            self?.advanceFloor()
        }
    }

    func advanceFloor() {
        let nextFloor = floor + 1

        // 挑戦状モード: ボス（3F）撃破でクリア
        if isFamilyNPCMode && challengeMonster != nil && floor >= 3 {
            endGame()
            return
        }

        // Free user floor limit
        if !PurchaseManager.shared.isPro && nextFloor > PurchaseManager.maxFreeFloor {
            didReachFloorLimit = true
            endGame()
            return
        }

        floor = nextFloor

        // ゴールフロア到達チェック
        if floor > difficulty.goalFloor && !hasPassedGoal {
            hasPassedGoal = true
            reachedGoalFloor = true
            return
        }

        showFloorBanner = true
        scheduleTransition(after: 1.0) { [weak self] in
            self?.showFloorBanner = false
        }

        // バトル中進化チェック
        let newStage = evolutionStage(for: floor)
        isNearEvolution = evolutionStage(for: floor + 1) != newStage

        if newStage != sessionEvolutionStage {
            // 進化発生 → 演出してからフロア開始
            sessionEvolutionStage = newStage
            phase = .evolving
            SoundManager.shared.playLevelUp()
            HapticsManager.correct()
            // 進化演出終了後にきらめきエフェクト
            scheduleTransition(after: 2.0) { [weak self] in
                guard let self else { return }
                self.showSparkle = true
                self.setupFloor()
                if self.phase != .bossAppearing {
                    self.phase = .answering
                }
            }
            scheduleTransition(after: 3.5) { [weak self] in
                self?.showSparkle = false
            }
        } else {
            setupFloor()
            if phase != .bossAppearing {
                phase = .answering
            }
        }
    }

    // MARK: - Game Over

    private func handleGameOver() {
        phase = .gameOver
        showComboBreak = false
        SoundManager.shared.playGameOver()

        scheduleTransition(after: 2.0) { [weak self] in
            self?.endGame()
        }
    }

    // MARK: - Timer Expired

    private func handleTimerExpired() {
        guard phase == .answering else { return }

        let elapsed = Date().timeIntervalSince(problemStartTime)
        currentSessionLogs.append(AnswerTimeLog(
            problemIndex: totalInSession,
            isCorrect: false,
            elapsedSeconds: elapsed
        ))

        totalInSession += 1
        if combo > 2 {
            comboBeforeBreak = combo
            showComboBreak = true
        }
        combo = 0
        playerHP -= 1

        SoundManager.shared.playIncorrect()
        SoundManager.shared.resetBGMRate()
        HapticsManager.incorrect()

        floatingText = "じかんぎれ！"
        phase = .incorrect

        if playerHP <= 0 {
            scheduleTransition(after: 1.0) { [weak self] in
                self?.handleGameOver()
            }
        } else {
            scheduleTransition(after: 1.0) { [weak self] in
                self?.showComboBreak = false
                self?.phase = .answering
                self?.nextProblem()
                self?.startTimerIfNeeded()
            }
        }
    }

    // MARK: - End Game

    func endGame() {
        stopTimer()
        AnalyticsManager.trackScreenEnter("result")
        AnalyticsManager.markSessionTracked()

        let playTime = Int(Date().timeIntervalSince(startTime ?? Date()))

        // Update player data
        isNewRecord = floor - 1 > playerData.bestFloor
        if floor - 1 > playerData.bestFloor {
            playerData.bestFloor = floor - 1
        }
        // ベスト記録更新時にレビューを促進（5回に1回）
        if isNewRecord {
            let key = "kazumon_new_record_count"
            let count = UserDefaults.standard.integer(forKey: key) + 1
            UserDefaults.standard.set(count, forKey: key)
            if count % 5 == 0 {
                Task { @MainActor in
                    if let scene = UIApplication.shared.connectedScenes
                        .first as? UIWindowScene {
                        AppStore.requestReview(in: scene)
                    }
                }
            }
        }
        if score > playerData.bestScore {
            playerData.bestScore = score
        }
        // 家族モードのスコア保存
        familyScoreUpdated = false
        if isFamilyNPCMode, let member = currentFamilyMember {
            familyScoreUpdated = DataStore.updateFamilyBestScore(member, score: score)
        }
        playerData.totalPlayCount += 1
        playerData.totalCorrect += correctInSession
        playerData.totalAnswered += totalInSession

        // Add earned XP
        let oldLevel = playerData.level
        didLevelUp = DataStore.addXP(earnedXP, to: &playerData)
        newLevel = playerData.level
        didEvolve = CharacterAppearanceFactory.stage(for: newLevel)
            != CharacterAppearanceFactory.stage(for: oldLevel)
        DataStore.savePlayerData(playerData)

        // コイン報酬（フロア×10 + スコア÷10）
        let coinReward = (floor - 1) * 10 + score / 10
        DataStore.addCoins(coinReward)

        // ガチャクレジット加算（正解数分）
        DataStore.addGachaCredits(correctInSession)
        if DataStore.consumeGachaPull(), let drop = Item.randomDrop() {
            var items = DataStore.loadItems()
            if let idx = items.firstIndex(where: { $0.id == drop.id }) {
                items[idx].count += 1
            } else {
                items.append(drop)
            }
            DataStore.saveItems(items)
            gachaItem = drop
        }

        // Daily mission — 破壊演出用に increment 前の playCount を記憶
        let preIncrementCount = min(DataStore.loadDailyMission().playCount, DailyMission.requiredPlays)
        pendingBreakFromIndex = preIncrementCount
        print("🎮 [endGame] calling incrementDailyMissionPlay...")
        DataStore.incrementDailyMissionPlay()
        dailyMission = DataStore.loadDailyMission()
        print("🎮 [endGame] after increment → playCount=\(dailyMission.playCount)")

        // Save session
        let record = SessionRecord(
            date: {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f.string(from: Date())
            }(),
            floor: floor - 1,
            score: score,
            correctCount: correctInSession,
            totalCount: totalInSession,
            maxCombo: maxCombo,
            playTimeSeconds: playTime,
            itemsEarned: earnedItems.map { $0.localizedName },
            answerTimeLogs: currentSessionLogs
        )
        DataStore.saveSession(record)

        // Supabase セッション更新
        if let sessionId = supabaseSessionId {
            SupabaseService.shared.updateSession(
                id: sessionId,
                totalQuestions: totalInSession,
                correctCount: correctInSession
            )
        }

        // ストリーク更新 + マイルストーン報酬
        let milestone = DataStore.updateStreak(&playerData)
        DataStore.savePlayerData(playerData)
        if let milestone {
            DataStore.grantStreakReward(milestone: milestone)
            dailyMission = DataStore.loadDailyMission()
            streakMilestone = milestone
        }

        // まちがいおに予告: 累計間違い10問以上で翌日にスケジュール
        if !isMistakeBossMode && DataStore.loadTotalMistakeCount() >= MistakeBossConfig.appearanceThreshold {
            DataStore.scheduleMistakeBoss()
            DataStore.resetTotalMistakeCount()
            shouldShowMistakeWarning = true
        }

        // じかんどろぼう予告: startGame()でスケジュール済みなら予告表示
        if !isTimeBossMode && !shouldShowTimeBossWarning {
            // scheduleTimeBoss() は翌日を設定するので、今日スケジュール=明日出現
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "en_US_POSIX")
            let tomorrowStr = f.string(from: tomorrow)
            if let scheduled = UserDefaults.standard.string(forKey: "kazumon_time_boss_date"),
               scheduled == tomorrowStr {
                shouldShowTimeBossWarning = true
            }
        }

        // Day30チャレンジ完了フラグ（修了証はリザルト画面のDone後に表示）
        pendingCertificate = challengeCleared && (challengeDay ?? 0) >= 30
        challengeDay = nil

        SoundManager.shared.fadeBGM(duration: 1.0)

        screen = .result
        SoundManager.shared.playResult()

        NotificationManager.shared.scheduleStreakReminders(playerName: playerData.playerName)

        AnalyticsManager.logBattleComplete(
            floor: floor - 1,
            correctCount: correctInSession,
            totalCount: totalInSession,
            isPro: PurchaseManager.shared.isPro
        )
    }

    /// まちがいおにバトルを開始
    func startMistakeBoss() {
        let log = DataStore.loadMistakeLog()
        guard log.count >= MistakeBossConfig.minMistakesRequired else { return }

        // 間違いログから最大20問取得（足りなければ繰り返し出題される）
        let count = min(log.count, MistakeBossConfig.maxProblems)
        let problems = Array(log.shuffled().prefix(count))
        startGame(difficulty: .normal)
        // startGame がリセットした後にフラグを立てる
        isMistakeBossMode = true
        mistakeBossProblems = problems
        mistakeBossDefeated = false
        // 撃破に必要な正解数 = 30 (HPバー連動)
        monsterHP = MistakeBossConfig.bossHP
        // 通常BGMを上書き → ボス専用BGM
        SoundManager.shared.playBGMMistakeBoss()
    }

    /// まちがいおに撃破判定
    private func checkMistakeBossComplete() {
        guard isMistakeBossMode, !mistakeBossDefeated else { return }
        // 30問正解で撃破（HPバーと連動）
        let requiredCorrect = MistakeBossConfig.bossHP
        if correctInSession >= requiredCorrect {
            mistakeBossDefeated = true
            // 正解した問題をMistakeLogから削除
            for entry in mistakeBossProblems {
                DataStore.removeMistake(a: entry.a, b: entry.b)
            }
            mistakeLog = DataStore.loadMistakeLog()
            DataStore.resetTotalMistakeCount()
            // 特別XPボーナス
            earnedXP += MistakeBossConfig.xpBonus
            _ = DataStore.addXP(MistakeBossConfig.xpBonus, to: &playerData)
            DataStore.savePlayerData(playerData)
            // 即座にバトル終了 → リザルト画面へ
            stopTimer()
            scheduleTransition(after: 1.0) { [weak self] in
                self?.endGame()
            }
        }
    }

    // MARK: - じかんどろぼうバトル

    func startTimeBoss() {
        startGame(difficulty: .normal)
        isTimeBossMode = true
        timeBossDefeated = false
        SoundManager.shared.playBGMMistakeBoss()

        // 1Fチュートリアル: フルタイマーを見せてから半分に奪う演出
        timeBossTutorialActive = true
        timerTotal = TimeBossConfig.fullTimeLimit
        timerRemaining = TimeBossConfig.fullTimeLimit

        // 2.0秒後: 敵が攻撃 → タイマーを半分に奪う
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self, self.isTimeBossMode else { return }
            self.timeBossMonsterAttacking = true
            SoundManager.shared.playBossAppear()
            HapticsManager.incorrect()
            // タイマーを半分に + 盗まれた色変え
            self.timerRemaining = TimeBossConfig.timeLimitSeconds
            self.timeBossTimerStolen = true
        }
        // 2.8秒後: 攻撃終了
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            guard let self, self.isTimeBossMode else { return }
            self.timeBossMonsterAttacking = false
        }
        // 3.0秒後: 盗まれた色変え終了（1秒間表示）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self else { return }
            self.timeBossTimerStolen = false
        }
        // 4.2秒後: チュートリアル終了、暗転解除、タイマー開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) { [weak self] in
            guard let self, self.isTimeBossMode else { return }
            self.timeBossTutorialActive = false
            self.startTimeBossTimer()
        }
    }

    /// じかんどろぼう用タイマー開始（timerTotal=12, timerRemaining=6 で半分表示）
    private func startTimeBossTimer() {
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.isPaused else { return }
                self.timerRemaining -= 0.05
                if self.timerRemaining <= 0 {
                    self.timerRemaining = 0
                    self.stopTimer()
                    self.handleTimerExpired()
                }
            }
    }

    private func checkTimeBossComplete() {
        guard isTimeBossMode, !timeBossDefeated else { return }
        if correctInSession >= TimeBossConfig.requiredCorrect {
            timeBossDefeated = true
            DataStore.markTimeBossDefeated()
            var p = DataStore.loadPlayerData()
            _ = DataStore.addXP(TimeBossConfig.xpBonus, to: &p)
            DataStore.savePlayerData(p)
            playerData = p
            earnedXP += TimeBossConfig.xpBonus
            stopTimer()
            scheduleTransition(after: 1.0) { [weak self] in
                self?.endGame()
            }
        }
    }

    /// チャレンジモードでバトルを開始
    func startChallengeDay(_ day: Int) {
        challengeDay = day
        challengeRequiredCorrect = ChallengeConfig.requiredCorrectPerDay
        let config = ChallengeConfig.forDay(day)
        problemType = config.problemType
        startGame(difficulty: config.difficulty)
    }

    /// チャレンジのクリア判定（正解数ベース）
    private var challengeCleared: Bool = false

    private func checkChallengeComplete() {
        guard let day = challengeDay, !challengeCleared else { return }
        if correctInSession >= challengeRequiredCorrect {
            DataStore.completeDay(day)
            challengeCleared = true
            // 修了証はendGame()後に表示（バトル中には出さない）
            // challengeDayはendGameまで保持（問題生成に使うため）
        }
    }

    func returnToTitle() {
        isMistakeBossMode = false
        mistakeBossDefeated = false
        mistakeBossProblems = []
        shouldShowMistakeWarning = false
        isTimeBossMode = false
        timeBossDefeated = false
        shouldShowTimeBossWarning = false
        // 家族モード: ランキング表示が必要なら true にし、リセットは clearFamilyMode() で行う
        if isFamilyNPCMode {
            showFamilyRanking = true
        }
        // Day30修了証はリザルト→タイトル遷移時に表示
        if pendingCertificate {
            pendingCertificate = false
            showCertificate = true
        }
        playerData = DataStore.loadPlayerData()
        dailyMission = DataStore.loadDailyMission()
        print("🎮 [returnToTitle] playCount=\(dailyMission.playCount)")
        screen = .island
    }

    // MARK: - Goal Clear

    func continueAfterGoal() {
        reachedGoalFloor = false  // ポップアップを閉じる（hasPassedGoal は true のまま → 再発動しない）
        showFloorBanner = true
        scheduleTransition(after: 1.0) { [weak self] in
            self?.showFloorBanner = false
        }
        setupFloor()
        if phase != .bossAppearing {
            phase = .answering
        }
    }

    func finishAfterGoal() {
        reachedGoalFloor = false
        endGame()
    }

    // MARK: - Pause

    func pauseGame() {
        guard !isPaused else { return }
        isPaused = true
    }

    func resumeGame() {
        guard isPaused else { return }
        isPaused = false
    }

    func quitGame() {
        AnalyticsManager.logBattleQuit(floor: floor, questionsAnswered: questionsAnswered)
        isPaused = false
        isMistakeBossMode = false
        isTimeBossMode = false
        timeBossDefeated = false
        mistakeBossDefeated = false
        mistakeBossProblems = []
        stopTimer()
        SoundManager.shared.fadeBGM(duration: 0.3)
        screen = .island
    }

    // MARK: - Timer

    private func startTimerIfNeeded() {
        if isTimeBossMode && !timeBossTutorialActive {
            // じかんどろぼう 2F以降: 毎問ボスが時間を奪う演出
            timerTotal = TimeBossConfig.fullTimeLimit
            timerRemaining = TimeBossConfig.fullTimeLimit  // まずMAXで見せる
            // 攻撃アニメ → タイマー半減 → 開始
            timeBossMonsterAttacking = true
            SoundManager.shared.playBossAppear()
            HapticsManager.incorrect()
            timeBossTimerStolen = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.timerRemaining = TimeBossConfig.timeLimitSeconds
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self else { return }
                self.timeBossMonsterAttacking = false
                self.timeBossTimerStolen = false
                self.startTimeBossTimer()
            }
            return
        }
        guard let tl = currentMonster.timeLimit else { return }
        let timeLimit = Double(tl)
        timerTotal = timeLimit
        timerRemaining = timerTotal

        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.isPaused else { return }
                self.timerRemaining -= 0.05
                if self.timerRemaining <= 0 {
                    self.timerRemaining = 0
                    self.stopTimer()
                    self.handleTimerExpired()
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Battle Evolution Stage

    private func evolutionStage(for floor: Int) -> CharacterEvolutionStage {
        switch floor {
        case 1...4:   return .base
        case 5...9:   return .evolve1
        case 10...19: return .evolve2
        default:      return .finalForm
        }
    }

    // MARK: - Helpers

    private func scheduleTransition(after seconds: Double, action: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            action()
        }
    }

    #if DEBUG
    func debugStartFromFloor(_ startFloor: Int) {
        startGame(difficulty: difficulty)
        floor = startFloor
        setupFloor()
    }
    #endif
}
