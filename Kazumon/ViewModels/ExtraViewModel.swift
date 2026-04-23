import Foundation

enum ExtraFinishReason {
    case timeUp    // 時間切れ
    case lifeZero  // HP0
    case quit      // ユーザー退出
}

@Observable
final class ExtraViewModel {

    // MARK: - Stage Selection
    var selectedStage: ExtraBossStage?

    // MARK: - Battle State
    var phase: BattlePhase = .answering
    var currentProblem: Problem = Problem.generate(floor: 1, mistakeLog: [])
    var selectedAnswer: Int?
    var lifeCount: Int = 3
    var correctCount: Int = 0
    var totalAnswered: Int = 0

    // MARK: - Monster
    var monster: Monster = Monster.forFloor(5)

    // MARK: - Timer
    var timeRemaining: Double = 60
    var timerTotal: Double = 60
    private var timerTask: Task<Void, Never>?

    // MARK: - Result
    var isFinished: Bool = false
    var isBestScore: Bool = false
    var finishReason: ExtraFinishReason = .timeUp

    // MARK: - Feedback
    var floatingText: String?
    var showCorrectHighlight: Bool = false

    // MARK: - Pause
    var isPaused: Bool = false

    // MARK: - Actions

    func selectStage(_ stage: ExtraBossStage) {
        selectedStage = stage
    }

    func startBattle() {
        guard let stage = selectedStage else { return }
        lifeCount = 3
        correctCount = 0
        totalAnswered = 0
        timeRemaining = stage.timeLimit
        timerTotal = stage.timeLimit
        isFinished = false
        isBestScore = false
        selectedAnswer = nil
        floatingText = nil
        showCorrectHighlight = false
        isPaused = false
        monster = Monster.forFloor(stage.floor)
        generateProblem()
        phase = .answering
        startTimer()
        SoundManager.shared.playBGMBattle()
    }

    private func generateProblem() {
        guard selectedStage != nil else { return }
        selectedAnswer = nil
        floatingText = nil
        showCorrectHighlight = false
        currentProblem = Problem.generate(
            floor: selectedStage!.floor,
            mistakeLog: []
        )
    }

    // MARK: - Answer

    func handleAnswer(_ selected: Int) {
        guard phase == .answering, !isFinished else { return }

        selectedAnswer = selected
        totalAnswered += 1

        if selected == currentProblem.answer {
            handleCorrect()
        } else {
            handleIncorrect()
        }
    }

    private func handleCorrect() {
        phase = .correct
        correctCount += 1
        SoundManager.shared.playCorrect()
        HapticsManager.correct()
        floatingText = "+1"

        scheduleTransition(after: 0.4) { [weak self] in
            guard let self, !self.isFinished else { return }
            self.generateProblem()
            self.phase = .answering
        }
    }

    private func handleIncorrect() {
        phase = .incorrect
        lifeCount -= 1
        SoundManager.shared.playIncorrect()
        HapticsManager.incorrect()
        floatingText = String(format: NSLocalizedString("floating_answer", comment: ""), currentProblem.answer)

        if lifeCount <= 0 {
            finishReason = .lifeZero
            scheduleTransition(after: 0.8) { [weak self] in
                self?.finishBattle()
            }
        } else {
            // 正解タップ待ちフェーズへ
            scheduleTransition(after: 0.5) { [weak self] in
                guard let self, !self.isFinished else { return }
                self.selectedAnswer = nil
                self.showCorrectHighlight = true
                self.phase = .confirmCorrect
                self.floatingText = nil
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

        scheduleTransition(after: 0.4) { [weak self] in
            guard let self, !self.isFinished else { return }
            self.generateProblem()
            self.phase = .answering
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while let self, self.timeRemaining > 0, !self.isFinished {
                try? await Task.sleep(for: .milliseconds(50))
                guard !self.isPaused else { continue }
                self.timeRemaining = max(0, self.timeRemaining - 0.05)
            }
            if let self, !self.isFinished {
                self.finishBattle()
            }
        }
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
        isPaused = false
        timerTask?.cancel()
        finishReason = .quit
        isFinished = true
        SoundManager.shared.fadeBGM(duration: 0.3)
    }

    // MARK: - Finish

    func finishBattle() {
        guard !isFinished else { return }
        timerTask?.cancel()
        isFinished = true
        phase = .gameOver

        guard let stage = selectedStage else { return }
        let prev = DataStore.loadExtraRecord().bestCorrectByStage[stage.id] ?? 0
        isBestScore = correctCount > prev
        if isBestScore {
            var record = DataStore.loadExtraRecord()
            record.bestCorrectByStage[stage.id] = correctCount
            DataStore.saveExtraRecord(record)
        }

        SoundManager.shared.fadeBGM(duration: 0.5)
        SoundManager.shared.playResult()
    }

    // MARK: - Helpers

    private func scheduleTransition(after seconds: Double, action: @escaping @Sendable () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            action()
        }
    }
}
