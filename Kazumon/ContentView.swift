import SwiftUI

struct ContentView: View {
    @State private var gameVM = GameViewModel()
    @State private var extraVM = ExtraViewModel()
    @State private var afterTestPhase: Int = 0
    @State private var afterTestScore: Int = 0
    @State private var afterTestTotal: Int = 30
    @State private var versusPhase: Int = -1  // -1=モード選択(NPC/Online), -2=家族選択, 0=コース選択, 1=BGM選択, 2=ロビー, 3=対戦, 4=結果
    @State private var versusPlayerScore: Int = 0
    @State private var versusOpponentScore: Int = 0
    @State private var versusBGM: String = "bgm_versus_1"
    @State private var versusAdditionOnly: Bool = false
    // gameVM.versusIsFamily は gameVM.gameVM.versusIsFamily を使用
    @State private var setupComplete = DataStore.hasCompletedSetup()

    /// プレイヤー名に「ちゃん」を自動付与（既に敬称付きならそのまま）
    private func playerNameWithChan(_ name: String) -> String {
        let existing = ["ちゃん", "くん", "さん", "様", "ちゃま", "君", "さま"]
        if existing.contains(where: { name.hasSuffix($0) }) {
            return name
        }
        return name + "ちゃん"
    }

    var body: some View {
        Group {
            if !setupComplete {
                ParentSetupView { setupComplete = true }
                    .transition(.opacity)
            } else {
                mainApp
            }
        }
        .animation(.easeInOut(duration: 0.3), value: setupComplete)
        .zenMaruFont()
        .statusBarHidden(true)
        .task { await PurchaseManager.shared.fetchPrice() }
    }

    // MARK: - メインアプリ

    @ViewBuilder
    private var mainApp: some View {
        Group {
            switch gameVM.screen {
            case .island:
                IslandWorldView(gameVM: gameVM)
                    .transition(.opacity)

            case .title:
                StartScreenView(gameVM: gameVM)
                    .transition(.opacity)

            case .battle:
                if DataStore.loadAgeGroup() == .young4 {
                    Young4BattleView(vm: gameVM)
                        .transition(.opacity)
                } else {
                    BattleView(vm: gameVM)
                        .transition(.opacity)
                }

            case .result:
                if gameVM.isMistakeBossMode && gameVM.mistakeBossDefeated {
                    MistakeBossResultView(gameVM: gameVM).transition(.opacity)
                } else if gameVM.isTimeBossMode && gameVM.timeBossDefeated {
                    TimeBossResultView(gameVM: gameVM).transition(.opacity)
                } else if DataStore.loadAgeGroup().isYoungMode {
                    YoungResultView(gameVM: gameVM).transition(.opacity)
                } else {
                    ResultView(gameVM: gameVM).transition(.opacity)
                }

            case .collection:
                CollectionView { gameVM.screen = .island }.transition(.move(edge: .trailing))
            case .extraSelect:
                ExtraSelectView(extraVM: extraVM, gameVM: gameVM).transition(.opacity)
            case .extraBattle:
                ExtraBattleView(extraVM: extraVM, gameVM: gameVM).transition(.opacity)
            case .extraResult:
                ExtraResultView(extraVM: extraVM, gameVM: gameVM).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameVM.screen)
        .fullScreenCover(isPresented: $gameVM.showVersus) {
            if versusPhase == -1 {
                // ① イントロ: ちょうせんじょうを かこう！
                ChallengeLetterIntroView(
                    onSelectFamily: {
                        gameVM.isFamilyNPCMode = true
                        gameVM.versusIsFamily = false
                        withAnimation { versusPhase = -2 }
                    },
                    onSelectOnline: {
                        gameVM.isFamilyNPCMode = false
                        withAnimation { versusPhase = 0 }
                    },
                    onBack: {
                        gameVM.showVersus = false
                        versusPhase = -1
                        gameVM.clearFamilyMode()
                    }
                )
            } else if versusPhase == -2 {
                // ② 宛先選択: だれに ちょうせんじょう？
                RecipientSelectView(
                    gameVM: gameVM,
                    onSelect: { member in
                        gameVM.currentFamilyMember = member
                        AnalyticsManager.logFamilyMemberSelected(member: member.rawValue)
                        withAnimation { versusPhase = -3 }
                    },
                    onBack: {
                        gameVM.clearFamilyMode()
                        withAnimation { versusPhase = -1 }
                    }
                )
            } else if versusPhase == -3 {
                // ③ 挑戦内容設計: どんな ちょうせん？
                ChallengeDesignView(
                    recipient: gameVM.currentFamilyMember ?? .self_,
                    onComplete: { monster, difficulty, problemType in
                        gameVM.challengeMonster = monster
                        gameVM.difficulty = difficulty
                        gameVM.problemType = problemType
                        versusAdditionOnly = (problemType == .addition)
                        withAnimation { versusPhase = -4 }
                    },
                    onBack: {
                        withAnimation { versusPhase = -2 }
                    }
                )
            } else if versusPhase == -4 {
                // ④ 書く演出（1.5秒）
                WritingAnimationView(
                    recipient: gameVM.currentFamilyMember ?? .self_,
                    monster: gameVM.challengeMonster ?? .slime,
                    difficulty: gameVM.difficulty,
                    problemType: gameVM.problemType,
                    onComplete: {
                        // じぶん選択時は渡す演出&Welcomeをスキップ → 直接BGMへ
                        if gameVM.currentFamilyMember == .self_ {
                            withAnimation { versusPhase = 1 }
                        } else {
                            withAnimation { versusPhase = -5 }
                        }
                    }
                )
            } else if versusPhase == -5 {
                // ⑤ 渡す演出（1.5秒）
                DeliveryAnimationView(
                    recipient: gameVM.currentFamilyMember ?? .father,
                    onComplete: {
                        withAnimation { versusPhase = -7 }
                    }
                )
            } else if versusPhase == -7 {
                // ⑤½ わたしてね画面（子供→相手へ端末を渡す）
                HandoffScreenView(
                    recipient: gameVM.currentFamilyMember ?? .father,
                    onHandedOver: {
                        withAnimation { versusPhase = -6 }
                    },
                    onPlaySelf: {
                        // 「やっぱり じぶんでやる！」→ BGM選択へ（じぶんモードで）
                        gameVM.currentFamilyMember = .self_
                        withAnimation { versusPhase = 1 }
                    }
                )
            } else if versusPhase == -6 {
                // ⑥ ParentWelcomeView: 受け取った瞬間
                ParentWelcomeView(
                    recipient: gameVM.currentFamilyMember ?? .father,
                    monster: gameVM.challengeMonster ?? .slime,
                    difficulty: gameVM.difficulty,
                    problemType: gameVM.problemType,
                    playerName: playerNameWithChan(gameVM.playerData.playerName),
                    onStart: {
                        withAnimation { versusPhase = 1 }
                    },
                    onTimeout: {
                        gameVM.showVersus = false
                        versusPhase = -1
                        gameVM.clearFamilyMode()
                    }
                )
            } else if versusPhase == 0 {
                // コース選択（オンラインのみ）
                versusCourseSelectView
            } else if versusPhase == 1 {
                VersusBGMSelectView(
                    onSelect: { bgm in
                        versusBGM = bgm
                        if gameVM.isFamilyNPCMode {
                            // 家族NPCモード: ソロバトル開始（挑戦設計の内容で）
                            gameVM.versusBGM = bgm
                            gameVM.showVersus = false
                            versusPhase = -1
                            AnalyticsManager.logFamilyBattleStart(
                                member: gameVM.currentFamilyMember?.rawValue ?? "unknown",
                                additionOnly: versusAdditionOnly
                            )
                            gameVM.startGame(difficulty: gameVM.difficulty)
                        } else {
                            withAnimation { versusPhase = 2 }
                        }
                    },
                    onBack: { versusPhase = 0 }
                )
            } else if versusPhase == 2 {
                OnlineLobbyView(
                    isFamily: gameVM.versusIsFamily,
                    onStart: {
                        SoundManager.shared.playBGM(versusBGM)
                        AnalyticsManager.logOnlineBattleStart(isFamily: gameVM.versusIsFamily)
                        withAnimation { versusPhase = 3 }
                    },
                    onCancel: {
                        gameVM.showVersus = false; versusPhase = -1; gameVM.versusIsFamily = false
                        MultiplayerService.shared.reset()
                    }
                )
            } else if versusPhase == 3 {
                OnlineMatchView(isFamily: gameVM.versusIsFamily, additionOnly: versusAdditionOnly) { myScore, opScore in
                    versusPlayerScore = myScore
                    versusOpponentScore = opScore
                    AnalyticsManager.logOnlineBattleComplete(myScore: myScore, opponentScore: opScore)
                    SoundManager.shared.fadeBGM(duration: 0.5)
                    withAnimation { versusPhase = 4 }
                }
            } else {
                VersusResultView(
                    playerScore: versusPlayerScore, cpuScore: versusOpponentScore,
                    onRematch: {
                        MultiplayerService.shared.reset()
                        versusPhase = 1
                    },
                    onHome: {
                        MultiplayerService.shared.leaveRoom()
                        gameVM.showVersus = false; versusPhase = -1; gameVM.versusIsFamily = false
                        gameVM.refreshTrigger += 1
                    },
                    opponentName: NSLocalizedString("versus_opponent_name", comment: ""),
                    isFamily: gameVM.versusIsFamily
                )
            }
        }
        .fullScreenCover(isPresented: $gameVM.showAfterTest) {
            if afterTestPhase == 0 {
                AfterTestView { score, total in
                    afterTestScore = score; afterTestTotal = total
                    DataStore.saveAfterTestResult(score: score, total: total, level: 0)
                    withAnimation { afterTestPhase = 1 }
                }
            } else {
                AfterTestResultView(
                    afterScore: afterTestScore, afterTotal: afterTestTotal,
                    onPass: { gameVM.showAfterTest = false; afterTestPhase = 0; gameVM.refreshTrigger += 1; gameVM.showCertificate = true },
                    onRetry: { afterTestPhase = 0 },
                    onHome: { gameVM.showAfterTest = false; afterTestPhase = 0; gameVM.refreshTrigger += 1 }
                )
            }
        }
        .fullScreenCover(isPresented: $gameVM.showAdditionCheck) {
            AdditionCheckTestView { lastPassedRound in
                gameVM.showAdditionCheck = false
                // 合流レベルに基づいてバトル開始
                DataStore.saveAdditionCheckRound(lastPassedRound)
                gameVM.startGame(difficulty: .easy)
            }
        }
        .fullScreenCover(isPresented: $gameVM.showCertificate) {
            CertificateView(
                playerName: gameVM.playerData.playerName,
                completionDate: { let f = DateFormatter(); f.dateStyle = .long; return f.string(from: Date()) }(),
                bestFloor: gameVM.playerData.bestFloor,
                totalCorrect: gameVM.playerData.totalCorrect,
                totalAnswered: gameVM.playerData.totalAnswered,
                onDismiss: { gameVM.showCertificate = false; gameVM.refreshTrigger += 1 }
            )
        }
        .overlay {
            if gameVM.playLimitReached {
                PlayLimitOverlay(
                    onUpgrade: {
                        gameVM.playLimitReached = false
                        Task { try? await PurchaseManager.shared.purchase() }
                    },
                    onDismiss: {
                        AnalyticsManager.logPaywallDismiss(source: "play_limit")
                        gameVM.playLimitReached = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $gameVM.showFamilyRanking) {
            FamilyRankingView(
                highlightedMember: gameVM.currentFamilyMember,
                didUpdateBest: gameVM.familyScoreUpdated,
                onClose: {
                    gameVM.clearFamilyMode()
                    gameVM.refreshTrigger += 1
                }
            )
        }
    }

    // MARK: - 対戦ステップインジケーター

    @ViewBuilder
    private func versusStepIndicator(current: Int) -> some View {
        HStack(spacing: 16) {
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .fill(i <= current ? Color.white : Color.white.opacity(0.3))
                    .frame(width: i == current ? 14 : 10, height: i == current ? 14 : 10)
                    .shadow(color: i == current ? .white.opacity(0.6) : .clear, radius: 4)
            }
        }
    }

    // MARK: - コース選択

    @ViewBuilder
    private var versusCourseSelectView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.40, blue: 0.80), Color(red: 0.30, green: 0.25, blue: 0.65)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Button {
                        HapticsManager.tap()
                        gameVM.showVersus = false; versusPhase = -1; gameVM.versusIsFamily = false
                        gameVM.clearFamilyMode()
                    } label: {
                        Text("battle_quit_button")
                            .font(.zenMaru(14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)

                Spacer()

                Text("versus_course_title")
                    .font(.zenMaru(24, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 2)

                // ステップインジケーター（● ○）
                versusStepIndicator(current: 0)
                    .padding(.top, 8)

                Spacer().frame(height: 20)

                // たしざんだけ
                Button {
                    HapticsManager.tap()
                    SoundManager.shared.playTap()
                    versusAdditionOnly = true
                    versusPhase = 1
                } label: {
                    VStack(spacing: 4) {
                        Text("versus_course_addition")
                            .font(.zenMaru(22, weight: .black))
                        Text("versus_course_addition_desc")
                            .font(.zenMaru(12, weight: .bold))
                            .opacity(0.7)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 80)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.green))
                    .shadow(color: Color.green.opacity(0.4), radius: 8, y: 4)
                }

                // つうじょう（たしざん＋ひきざん）
                Button {
                    HapticsManager.tap()
                    SoundManager.shared.playTap()
                    versusAdditionOnly = false
                    versusPhase = 1
                } label: {
                    VStack(spacing: 4) {
                        Text("versus_course_normal")
                            .font(.zenMaru(22, weight: .black))
                        Text("versus_course_normal_desc")
                            .font(.zenMaru(12, weight: .bold))
                            .opacity(0.7)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 80)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.50, green: 0.47, blue: 0.87)))
                    .shadow(color: Color(red: 0.50, green: 0.47, blue: 0.87).opacity(0.4), radius: 8, y: 4)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}
