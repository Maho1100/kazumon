import SwiftUI

struct ResultView: View {
    @Bindable var gameVM: GameViewModel
    @State private var resultVM = ResultViewModel()
    @State private var phase = 0
    @State private var showFlash = true
    @State private var bgRevealed = false
    @State private var shakeOffset: CGFloat = 0
    @State private var charScale: CGFloat = 1.0
    @State private var charOpacity: Double = 1
    @State private var charFloat: CGFloat = 0
    @State private var resultEntrance: Bool = false
    @State private var wellDoneScale: CGFloat = 3.0
    @State private var wellDoneOpacity: Double = 0
    @State private var floorScale: CGFloat = 3.0
    @State private var floorOpacity: Double = 0
    @State private var cardOpacity: Double = 0
    @State private var cardOffset: CGFloat = 30
    @State private var recordScale: CGFloat = 0.5
    @State private var recordOpacity: Double = 0
    @State private var streakOpacity: Double = 0
    @State private var missionOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiVisible = false
    @State private var showFloorLimitOverlay = false
    @State private var showItemPopup = false
    @State private var showEvolutionPopup = false
    @State private var showLevelUpOverlay = false
    @State private var showRankPopup = false
    @State private var animateNewRecord = false
    @State private var speechOpacity: Double = 0
    @State private var isShareSheetPresented = false
    @State private var showStreakReward = false
    @State private var showMistakeOniWarning = false
    @State private var showTimeBossWarning = false

    // WEB版カラー定義
    private let bgGradientStart = Color(red: 0.40, green: 0.49, blue: 0.92)  // #667eea
    private let bgGradientEnd   = Color(red: 0.46, green: 0.29, blue: 0.64)  // #764ba2
    private let textDark        = Color(red: 0.18, green: 0.22, blue: 0.28)  // #2D3748
    private let labelGray       = Color(red: 0.44, green: 0.50, blue: 0.59)  // #718096
    private let accentGold      = Color(red: 0.93, green: 0.79, blue: 0.30)  // #ECC94B
    private let retryRed        = Color(red: 0.90, green: 0.24, blue: 0.24)  // #E53E3E

    var body: some View {
        ZStack {
            // 暗転→背景
            Color.black.ignoresSafeArea()
            if bgRevealed {
                LinearGradient(
                    colors: [bgGradientStart, bgGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }

            if confettiVisible { ResultConfettiView().allowsHitTesting(false) }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    // Phase 0: キャラ + wellDone
                    VStack(spacing: 4) {
                        if phase >= 1 {
                            // セリフ吹き出し（キャラの上）
                            VStack(spacing: 0) {
                                Text(FloorRank.characterComment(for: gameVM.floor - 1))
                                    .font(.zenMaru(13, weight: .bold))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    )
                                ResultTriangle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 7)
                            }
                            .opacity(speechOpacity)
                        }

                        if phase >= 0 {
                            KennyCharacterView(
                                appearance: gameVM.playerAppearance,
                                size: 100,
                                playEntrance: resultEntrance
                            )
                            .scaleEffect(charScale)
                            .opacity(charOpacity)
                            .offset(y: charFloat)
                        }

                        if phase >= 1 {

                            Text("view_result_well_done")
                                .font(.zenMaru(36, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                                .scaleEffect(wellDoneScale)
                                .opacity(wellDoneOpacity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)

                    // Phase 2: フロア数 ドドーン + カード
                    if phase >= 2 {
                        VStack(spacing: 12) {
                            if !gameVM.isFamilyNPCMode {
                                Text("▲ \(gameVM.floor - 1)F")
                                    .font(.zenMaru(48, weight: .black))
                                    .foregroundColor(textDark)
                                    .scaleEffect(floorScale)
                                    .opacity(floorOpacity)
                            }

                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [.clear, Color(red: 0.89, green: 0.91, blue: 0.94), .clear],
                                    startPoint: .leading, endPoint: .trailing))
                                .frame(height: 2).padding(.vertical, 2)

                            resultRow(label: NSLocalizedString("view_result_score", comment: ""), value: String(gameVM.score))
                            resultRow(label: NSLocalizedString("view_result_combo", comment: ""), value: "×\(gameVM.maxCombo)")
                            resultRow(
                                label: NSLocalizedString("view_result_accuracy", comment: ""),
                                value: gameVM.totalInSession > 0
                                    ? "\(Int(Double(gameVM.correctInSession) / Double(gameVM.totalInSession) * 100))%"
                                    : "---"
                            )
                            resultRow(
                                label: NSLocalizedString("view_result_play_time", comment: ""),
                                value: {
                                    let secs = Int(Date().timeIntervalSince(gameVM.startTime ?? Date()))
                                    return String(format: "%d:%02d", secs / 60, secs % 60)
                                }()
                            )
                            if gameVM.earnedXP > 0 {
                                resultRow(label: NSLocalizedString("view_result_earned_xp", comment: ""), value: "+\(gameVM.earnedXP)")
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 4)
                        .padding(.horizontal, 20)
                        .opacity(cardOpacity)
                        .offset(y: cardOffset)
                    }

                    // Phase 3: New record + streak
                    if phase >= 3 {
                        if gameVM.isNewRecord {
                            Text("view_result_new_record")
                                .font(.zenMaru(28, weight: .black))
                                .foregroundColor(accentGold)
                                .shadow(color: accentGold.opacity(0.6), radius: 16)
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                                .scaleEffect(recordScale)
                                .opacity(recordOpacity)
                        }

                        if gameVM.playerData.streakDays > 0 {
                            HStack(spacing: 4) {
                                Text(String(format: NSLocalizedString("streak_badge", comment: ""), gameVM.playerData.streakDays))
                                    .font(.zenMaru(16, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .opacity(streakOpacity)
                        }
                    }

                    // Phase 4: ミッション
                    if phase >= 4 {
                        if resultVM.canClaimMissionBonus {
                            Button {
                                resultVM.claimMissionBonus(gameVM: gameVM)
                                HapticsManager.correct()
                            } label: {
                                HStack(spacing: 8) {
                                    Text(String(format: NSLocalizedString("view_result_daily_mission_bonus", comment: ""), DailyMission.bonusXP))
                                        .font(.zenMaru(15, weight: .bold))
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50)
                                .background(Color.orange).clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 20).opacity(missionOpacity)
                        } else if resultVM.missionBonusClaimed {
                            HStack(spacing: 8) {
                                Text("view_result_mission_claimed")
                                    .font(.zenMaru(15, weight: .bold))
                                    .foregroundColor(accentGold)
                            }.opacity(missionOpacity)
                        }
                    }

                    Spacer().frame(height: 100)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if phase >= 5 {
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                        .background(
                            LinearGradient(
                                colors: [bgGradientEnd, bgGradientEnd.opacity(0.95)],
                                startPoint: .top, endPoint: .bottom
                            ).ignoresSafeArea(edges: .bottom)
                        )
                        .opacity(buttonOpacity)
                }
            }

            // レベルアップオーバーレイ（WEB版準拠・自動クローズ）
            if showLevelUpOverlay {
                LevelUpOverlayView(newLevel: gameVM.newLevel) {
                    showLevelUpOverlay = false
                    if !gameVM.earnedItems.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showItemPopup = true
                        }
                    } else if gameVM.streakMilestone != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showStreakReward = true
                        }
                    }
                }
            }

            // 進化ポップアップ
            if showEvolutionPopup {
                EvolutionPopupView(
                    stage: gameVM.currentEvolutionStage,
                    appearance: gameVM.playerAppearance
                ) {
                    showEvolutionPopup = false
                    if gameVM.didLevelUp {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showLevelUpOverlay = true
                        }
                    } else if !gameVM.earnedItems.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showItemPopup = true
                        }
                    } else if gameVM.streakMilestone != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showStreakReward = true
                        }
                    }
                }
            }

            // アイテム報酬ポップアップ
            if showItemPopup {
                ItemRewardPopupView(items: gameVM.earnedItems) {
                    showItemPopup = false
                    if gameVM.streakMilestone != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showStreakReward = true
                        }
                    } else if gameVM.gachaItem != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            gameVM.showGachaPull = true
                        }
                    }
                }
            }

            // ストリーク報酬ポップアップ
            if showStreakReward, let milestone = gameVM.streakMilestone {
                StreakRewardPopupView(milestone: milestone) {
                    showStreakReward = false
                    gameVM.streakMilestone = nil
                    if gameVM.gachaItem != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            gameVM.showGachaPull = true
                        }
                    }
                }
            }

            // ガチャプル
            if gameVM.showGachaPull, let item = gameVM.gachaItem {
                GachaPullView(item: item) {
                    gameVM.showGachaPull = false
                    gameVM.gachaItem = nil
                }
            }

            // ランクバッジポップアップ
            if showRankPopup {
                RankBadgePopupView(
                    floor: gameVM.floor - 1,
                    correctCount: gameVM.correctInSession,
                    totalCount: gameVM.totalInSession,
                    bestFloor: gameVM.playerData.bestFloor,
                    isNewRecord: gameVM.isNewRecord
                ) {
                    showRankPopup = false
                    // 閉じた後にアイテムポップアップへ連鎖
                    if gameVM.didEvolve {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showEvolutionPopup = true
                        }
                    } else if gameVM.didLevelUp {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showLevelUpOverlay = true
                        }
                    } else if !gameVM.earnedItems.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showItemPopup = true
                        }
                    } else if gameVM.streakMilestone != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showStreakReward = true
                        }
                    }
                }
                .zIndex(200)
            }

            // フロア制限オーバーレイ
            if showFloorLimitOverlay {
                FloorLimitOverlay(
                    onUpgrade: {
                        showFloorLimitOverlay = false
                        Task { try? await PurchaseManager.shared.purchase() }
                    },
                    onDismiss: {
                        showFloorLimitOverlay = false
                    }
                )
            }

            // シェアボーナスポップアップ
            if gameVM.showShareBonusPopup {
                ShareBonusPopupView(isPro: PurchaseManager.shared.isPro) {
                    gameVM.showShareBonusPopup = false
                }
            }

            // 白フラッシュ
            Color.white.ignoresSafeArea()
                .opacity(showFlash ? 0.9 : 0)
                .allowsHitTesting(false)
        }
        .offset(x: shakeOffset)
        .onAppear {
            AnalyticsManager.trackScreenEnter("result")
            // 最新のdailyMissionを再読み込みしてcanContinue判定を正確にする
            gameVM.dailyMission = DataStore.loadDailyMission()
            resultVM.checkMissionBonus()
            gameVM.checkShareBonus()
            // 初回プレイ完了時に通知許可をリクエスト
            if !DataStore.hasStartedOnce() {
                DataStore.setHasStartedOnce()
                NotificationManager.shared.requestPermission()
            }
            // ヒカキン流シーケンス
            runResultSequence()
            // フロア制限到達時
            if gameVM.didReachFloorLimit {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                    showFloorLimitOverlay = true
                }
            }
            // RankBadgePopup（全演出の後に）
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                showRankPopup = true
            }
        }
        .fullScreenCover(isPresented: $showMistakeOniWarning) {
            MistakeOniWarningView {
                showMistakeOniWarning = false
                gameVM.returnToTitle()
            }
        }
        .fullScreenCover(isPresented: $showTimeBossWarning) {
            TimeBossWarningView {
                showTimeBossWarning = false
                gameVM.returnToTitle()
            }
        }
    }

    // MARK: - ヒカキン流シーケンス

    private func runResultSequence() {
        // 0.0s: フラッシュ + 背景
        withAnimation(.easeOut(duration: 0.2)) { bgRevealed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.25)) { showFlash = false }
        }
        SoundManager.shared.playBossAppear()
        HapticsManager.incorrect()

        // 0.5s: 登場アニメーション開始
        at(0.5) {
            resultEntrance = true
            HapticsManager.tap(); SoundManager.shared.playTap()
            at(2.0) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { charFloat = -8 }
            }
        }

        // 1.2s: 「おつかれさま！」バウンス + 吹き出し
        at(1.2) {
            phase = 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                wellDoneScale = 1.0; wellDoneOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4)) { speechOpacity = 1 }
            HapticsManager.tap(); SoundManager.shared.playTap()
        }

        // 2.0s: フロア数 ドドーン + フラッシュ + シェイク + 紙吹雪
        at(2.0) {
            phase = 2
            showFlash = true
            at(0.1) { withAnimation(.easeOut(duration: 0.2)) { showFlash = false } }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                floorScale = 1.0; floorOpacity = 1
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cardOpacity = 1; cardOffset = 0
            }
            SoundManager.shared.playBossVictory()
            HapticsManager.incorrect()
            runShake()
            confettiVisible = true
        }

        // 3.0s: NEW RECORD + ストリーク
        at(3.0) {
            phase = 3
            if gameVM.isNewRecord {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    recordScale = 1.0; recordOpacity = 1
                }
                HapticsManager.tap(); SoundManager.shared.playTap()
            }
            withAnimation(.easeOut(duration: 0.4)) { streakOpacity = 1 }
        }

        // 3.8s: ミッション
        at(3.8) {
            phase = 4
            withAnimation(.easeOut(duration: 0.4)) { missionOpacity = 1 }
        }

        // 4.5s: ボタン
        at(4.5) {
            phase = 5
            SoundManager.shared.playResult()
            withAnimation(.easeOut(duration: 0.4)) { buttonOpacity = 1 }
        }

    }

    private func at(_ d: Double, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + d, execute: action)
    }

    private func runShake() {
        let steps: [(CGFloat, Double)] = [(10,0),(-10,0.04),(8,0.08),(-6,0.12),(4,0.16),(0,0.20)]
        for (o, d) in steps {
            at(d) { withAnimation(.linear(duration: 0.03)) { shakeOffset = o } }
        }
    }

    private var canContinue: Bool {
        PurchaseManager.shared.isPro || gameVM.dailyMission.playCount < PurchaseManager.maxFreePlayCount
    }

    private func reloadAndCheckCanContinue() -> Bool {
        gameVM.dailyMission = DataStore.loadDailyMission()
        return canContinue
    }

    private var shareText: String {
        let floor = gameVM.floor - 1
        let medal = FloorRank.medal(for: floor)
        let correctRate = gameVM.totalInSession > 0
            ? Int(Double(gameVM.correctInSession) / Double(gameVM.totalInSession) * 100)
            : 0
        return String(format: NSLocalizedString("share_text_format", comment: ""), medal, floor, correctRate)
    }

    @ViewBuilder
    private var shareButton: some View {
        ShareLink(item: shareText) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                if gameVM.canReceiveShareBonus {
                    Text("share_button_bonus")
                        .font(.zenMaru(15, weight: .bold))
                } else {
                    Text("share_button_normal")
                        .font(.zenMaru(15, weight: .regular))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        gameVM.canReceiveShareBonus
                            ? Color.green
                            : Color.white.opacity(0.2)
                    )
            )
        }
        .simultaneousGesture(TapGesture().onEnded {
            gameVM.grantShareBonus()
            AnalyticsManager.logShareTapped()
        })
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 8) {
            shareButton

            if canContinue {
                HStack(spacing: 16) {
                    Button {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        guard reloadAndCheckCanContinue() else { return }
                        if gameVM.shouldShowTimeBossWarning {
                            showTimeBossWarning = true
                        } else if gameVM.shouldShowMistakeWarning {
                            showMistakeOniWarning = true
                        } else {
                            gameVM.startGame()
                        }
                    } label: {
                        Text("view_result_retry")
                            .font(.zenMaru(24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(retryRed)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: retryRed.opacity(0.4), radius: 15, y: 4)
                    }

                    Button {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        if gameVM.shouldShowTimeBossWarning {
                            showTimeBossWarning = true
                        } else if gameVM.shouldShowMistakeWarning {
                            showMistakeOniWarning = true
                        } else {
                            gameVM.returnToTitle()
                        }
                    } label: {
                        Text("view_result_finish")
                            .font(.zenMaru(18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 100, maxWidth: 160, minHeight: 50)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                    }
                }
            } else {
                // プレイ回数上限到達: Pro版への誘導ボタン
                Button {
                    HapticsManager.tap(); SoundManager.shared.playTap()
                    Task { try? await PurchaseManager.shared.purchase() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                        Text("title_upgrade_pro")
                            .font(.zenMaru(20, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.orange.opacity(0.4), radius: 15, y: 4)
                }

                Text("view_title_play_limit_reached")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))

                Button {
                    HapticsManager.tap(); SoundManager.shared.playTap()
                    if gameVM.shouldShowMistakeWarning {
                        showMistakeOniWarning = true
                    } else {
                        gameVM.returnToTitle()
                    }
                } label: {
                    Text("view_result_finish")
                        .font(.zenMaru(24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                }
            }
        }
    }

    @ViewBuilder
    private var evolutionGoalView: some View {
        if let nextLv = CharacterAppearanceFactory.nextEvolutionLevel(after: gameVM.playerData.level) {
            let levelsLeft = nextLv - gameVM.playerData.level
            HStack(spacing: 6) {
                Text("🌟")
                Text(String(format: NSLocalizedString("view_result_evolution_goal", comment: ""), levelsLeft, nextLv))
                    .font(.zenMaru(13, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
        } else {
            HStack(spacing: 6) {
                Text("👑")
                Text("view_result_max_evolution")
                    .font(.zenMaru(12, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
    }

    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.zenMaru(16, weight: .bold))
                .foregroundColor(labelGray)
            Spacer()
            Text(value)
                .font(.zenMaru(22, weight: .black))
                .foregroundColor(textDark)
                .monospacedDigit()
        }
    }
}

// MARK: - Triangle Shape

private struct ResultTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
