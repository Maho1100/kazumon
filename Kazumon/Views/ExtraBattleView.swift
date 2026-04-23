import SwiftUI

struct ExtraBattleView: View {
    @Bindable var extraVM: ExtraViewModel
    @Bindable var gameVM: GameViewModel

    var body: some View {
        ZStack {
            // 暗めの背景
            LinearGradient(
                colors: bgColors(for: extraVM.selectedStage?.floor ?? 5),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Status bar はZStack上層に移動済み
                Spacer().frame(height: 40)

                // Timer bar
                if extraVM.phase == .answering || extraVM.phase == .correct
                    || extraVM.phase == .incorrect || extraVM.phase == .confirmCorrect {
                    TimerBarView(
                        remaining: extraVM.timeRemaining,
                        total: extraVM.timerTotal
                    )
                }

                Spacer()

                // Monster
                MonsterView(
                    monster: extraVM.monster,
                    floor: extraVM.selectedStage?.floor ?? 5,
                    isHit: extraVM.phase == .correct,
                    isDefeated: false
                )
                .frame(height: 160)

                // Floating text
                if let text = extraVM.floatingText {
                    FloatingText(text: text)
                        .id(text + String(extraVM.totalAnswered))
                }

                Spacer()

                // Problem
                if extraVM.phase != .gameOver {
                    Text("\(extraVM.currentProblem.a) \(extraVM.currentProblem.operatorSymbol) \(extraVM.currentProblem.b) = ?")
                        .font(.zenMaru(42, weight: .black))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .padding(.bottom, 8)

                    // Choice buttons (2x2)
                    let choices = extraVM.currentProblem.choices
                    let isConfirm = extraVM.phase == .confirmCorrect
                    VStack(spacing: 6) {
                        HStack(spacing: 12) {
                            ForEach(0..<min(2, choices.count), id: \.self) { i in
                                ChoiceButton(
                                    number: choices[i],
                                    correctAnswer: extraVM.currentProblem.answer,
                                    selectedAnswer: extraVM.selectedAnswer,
                                    combo: 0,
                                    isDisabled: (extraVM.phase != .answering && !isConfirm) || extraVM.isPaused,
                                    showCorrectHighlight: extraVM.showCorrectHighlight
                                ) {
                                    if isConfirm {
                                        extraVM.confirmCorrectAnswer(choices[i])
                                    } else {
                                        extraVM.handleAnswer(choices[i])
                                    }
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            ForEach(2..<min(4, choices.count), id: \.self) { i in
                                ChoiceButton(
                                    number: choices[i],
                                    correctAnswer: extraVM.currentProblem.answer,
                                    selectedAnswer: extraVM.selectedAnswer,
                                    combo: 0,
                                    isDisabled: (extraVM.phase != .answering && !isConfirm) || extraVM.isPaused,
                                    showCorrectHighlight: extraVM.showCorrectHighlight
                                ) {
                                    if isConfirm {
                                        extraVM.confirmCorrectAnswer(choices[i])
                                    } else {
                                        extraVM.handleAnswer(choices[i])
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }

            // Game over overlay
            if extraVM.phase == .gameOver {
                GameOverOverlay(reason: extraVM.finishReason)
            }

            // Status bar（ZStack上層＝タップ確実に届く）
            VStack {
                HStack {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Text(i < extraVM.lifeCount ? "❤️" : "🖤")
                                .font(.system(size: 22))
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Text(String(format: NSLocalizedString("extra_score_count", comment: ""), extraVM.correctCount))
                            .font(.zenMaru(20, weight: .black))
                            .foregroundColor(.yellow)
                            .monospacedDigit()
                        Button {
                            extraVM.pauseGame()
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
            .zIndex(100)

            // Pause overlay
            if extraVM.isPaused {
                PauseOverlay(
                    onResume: { extraVM.resumeGame() },
                    onQuit: {
                        extraVM.quitGame()
                        gameVM.screen = .extraSelect
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .onChange(of: extraVM.isFinished) { _, finished in
            if finished && !extraVM.isPaused {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    gameVM.screen = .extraResult
                }
            }
        }
    }

    // MARK: - Boss Floor Background Colors

    private func bgColors(for floor: Int) -> [Color] {
        switch floor {
        case 5:
            return [
                Color(red: 0.50, green: 0.35, blue: 0.20),
                Color(red: 0.40, green: 0.45, blue: 0.30)
            ]
        case 10:
            return [
                Color(red: 0.35, green: 0.28, blue: 0.20),
                Color(red: 0.25, green: 0.23, blue: 0.20)
            ]
        case 15:
            return [
                Color(red: 0.28, green: 0.25, blue: 0.50),
                Color(red: 0.18, green: 0.18, blue: 0.30)
            ]
        case 20:
            return [
                Color(red: 0.10, green: 0.08, blue: 0.25),
                Color(red: 0.50, green: 0.10, blue: 0.08)
            ]
        case 25:
            return [
                Color(red: 0.10, green: 0.06, blue: 0.18),
                Color(red: 0.08, green: 0.05, blue: 0.14)
            ]
        case 30:
            return [
                Color(red: 0.06, green: 0.04, blue: 0.12),
                Color(red: 0.08, green: 0.05, blue: 0.15)
            ]
        default:
            return [
                Color(red: 0.12, green: 0.10, blue: 0.25),
                Color(red: 0.08, green: 0.06, blue: 0.18)
            ]
        }
    }
}
