import SwiftUI
import Combine

struct TitleView: View {
    let gameVM: GameViewModel
    @Bindable var extraVM: ExtraViewModel
    @State private var vm = TitleViewModel()
    @State private var pulseScale: CGFloat = 1.0
@State private var shimmerOffset: CGFloat = -1.0
    @State private var bounceOffset: CGFloat = 0
    @State private var titleOffset: CGFloat = 0
    @State private var activeSheet: ActiveSheet?
    @State private var showDashboard = false
    @State private var showDifficultySheet = false
    @State private var showChallengeMap = false
    @State private var showCertificate = false
    @State private var showBossEntrance = false
    @State private var showTimeBossEntrance = false
    @State private var statsReady = false
    @State private var breakingSlotIndex: Int = -1
    @State private var missionCardId: UUID = UUID()

    // ビフォーテスト
    @State private var beforeTestPhase: Int = 0
    @State private var beforeTestScore: Int = 0
    @State private var beforeTestAvgTime: Double = 0

    // アフターテストバナー
    @State private var showAfterTestBanner = false

    // olderモード段階選択
    @State private var olderPhase: Int = 0
    @State private var showProfileSwitcher = false
    @State private var olderTransition = false
    @State private var charTapped = false
    @State private var charSleeping = false
    @State private var startFlash = false
    @State private var selectedDifficultyOlder: Difficulty = .normal
    @State private var olderBounce: CGFloat = 0

    #if DEBUG
    @State private var moodTimer: Timer? = nil
    @State private var debugMood = CharacterMoodDebug.shared
    #endif

    // タイトルキャラ表情
    @State private var titleMood: KennyCharacterView.IdleMood = .normal
    @State private var titleTapCount = 0
    @State private var titleIdleTimer: Timer? = nil
    @State private var titleLeftEye: CGFloat = 1.0
    @State private var titleRightEye: CGFloat = 1.0
    @State private var titleEyeWasBig = false
    @State private var showEyeBubble = false
    @State private var titleBubbleText = ""
    @State private var showTitleBubble = false

    // まほうのじかん
    @State private var isMagicTime = false
    @State private var animateGradient = false
    @State private var magicSpeech: String? = nil
    @State private var showMagicSpeech = false
    @State private var magicSpeechTimer: Timer? = nil
    @State private var powerDiff: Int = 0
    @State private var cardPage: Int = 0
    @State private var ringAnimated = false
    @State private var statsAnimated = false
    @State private var statsCurrent = PlayerStats(speed: 0, topFloor: 0, maxCombo: 0, playDays: 0)
    @State private var statsPrevious = PlayerStats(speed: 0, topFloor: 0, maxCombo: 0, playDays: 0)

    enum ActiveSheet: Identifiable {
        case settings, beforeTest
        #if DEBUG
        case layoutDebug
        case debugPanel
        #endif

        var id: Int { hashValue }
    }

    var body: some View {
        ZStack {
            // メインコンテンツ（タブ別）
            tabContent
                .safeAreaInset(edge: .bottom) {
                    TabBarView(
                        currentTab: $vm.currentTab,
                        totalXP: vm.playerData.totalXP,
                        newlyUnlockedTab: vm.newlyUnlockedTab,
                        onTabTapped: { tab in vm.markTabTapped(tab) },
                        isTabPulsing: { tab in vm.isTabPulsing(tab) }
                    )
                }


            // タブ解放ポップアップ
            if let tab = vm.newlyUnlockedTab {
                TabUnlockPopupView(tab: tab) {
                    vm.dismissUnlockPopup()
                }
                .zIndex(100)
            }
        }
        .onAppear {
            print("🎮 [TitleView] onAppear fired")
            vm.refresh()
            AnalyticsManager.logTitleShown(ageGroup: DataStore.loadAgeGroup().rawValue)
            if SoundManager.shared.isEnabled {
                SoundManager.shared.playBGM(SoundManager.shared.selectedBGM)
            }
            // ビフォーテストは初回バトル内で自動判定（画面表示なし）
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView(onNameChanged: { vm.refresh() }, onPlayWithChild: {
                    gameVM.versusIsFamily = true
                    gameVM.showVersus = true
                })
            case .beforeTest:
                beforeTestFlow
                    .interactiveDismissDisabled()
            #if DEBUG
            case .debugPanel:
                DebugPanelView(gameVM: gameVM) { vm.refresh() }
            case .layoutDebug:
                CharacterLayoutDebugView()
            #endif
            }
        }
        .onChange(of: activeSheet) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                vm.refresh()
            }
        }
        .onDisappear {
            stopMagicSpeechLoop()
        }
        .fullScreenCover(isPresented: $showBossEntrance) {
            MistakeOniAppearView {
                showBossEntrance = false
                gameVM.startMistakeBoss()
            }
        }
        .fullScreenCover(isPresented: $showTimeBossEntrance) {
            TimeBossAppearView {
                showTimeBossEntrance = false
                gameVM.startTimeBoss()
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch vm.currentTab {
        case .home:
            homeView
                .id(gameVM.refreshTrigger)
        case .collection:
            CollectionView {
                vm.currentTab = .home
            }
        case .bgm:
            BGMTabView(soundManager: SoundManager.shared)
        case .extra:
            ExtraSelectView(extraVM: extraVM, gameVM: gameVM)
        case .settings:
            SettingsView(onNameChanged: { vm.refresh() }, onPlayWithChild: {
                gameVM.versusIsFamily = true
                gameVM.showVersus = true
            }, showCloseButton: false)
                .onAppear { vm.refresh() }
        }
    }

    // MARK: - Home View

    private var homeView: some View {
        Group {
            if DataStore.loadAgeGroup().isYoungMode {
                youngHomeView
            } else {
                olderHomeView
            }
        }
    }

    // MARK: - Older Home View（段階選択式）

    private var olderHomeView: some View {
        ZStack {
            // 背景（8歳: ダーク系 / まほうのじかん対応）
            Group {
                if isMagicTime {
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.4),
                            Color(red: 1.0, green: 0.7, blue: 0.0),
                            Color(red: 0.4, green: 0.9, blue: 0.4),
                            Color(red: 0.3, green: 0.7, blue: 1.0),
                            Color(red: 0.7, green: 0.4, blue: 1.0),
                        ],
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                } else {
                    LinearGradient(
                        colors: [UITheme.Older.bgTop, UITheme.Older.bgBottom],
                        startPoint: .top, endPoint: .bottom
                    )
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 上部バー
                HStack {
                    #if DEBUG
                    Button("D") { activeSheet = .debugPanel }
                        .font(.zenMaru(12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    #endif
                    Spacer()
                    Button {
                        HapticsManager.tap()
                        SoundManager.shared.toggle()
                    } label: {
                        Image(systemName: SoundManager.shared.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title3).foregroundColor(.white)
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.top, 8)
                .zIndex(10)

                // プロフィールカード
                HStack {
                    if let profile = DataStore.activeProfile() {
                        Button {
                            HapticsManager.tap()
                            showProfileSwitcher = true
                        } label: {
                            profileCard(profile: profile)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .sheet(isPresented: $showProfileSwitcher) {
                    ProfileSwitcherView {
                        vm.refresh()
                        gameVM.refreshTrigger += 1
                    }
                }

                // タイトルロゴ
                Text(NSLocalizedString("title_logo", comment: ""))
                    .font(.zenMaru(18, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                    .padding(.top, 12)

                Spacer()

                // キャラクター（でかく）
                KennyCharacterView(
                    appearance: CharacterAppearanceFactory.appearance(for: vm.playerData.level),
                    size: UITheme.Older.characterSize,
                    idleMood: olderCharMood,
                    debugMoodOffsets: MoodOverlayOffsets(leftEyeScale: titleLeftEye, rightEyeScale: titleRightEye)
                )
                .allowsHitTesting(false)
                .scaleEffect(charTapped ? 1.3 : 1.0)
                .rotationEffect(.degrees(charSleeping ? -5 : 0))
                .offset(y: olderBounce)
                .contentShape(Rectangle())
                .onTapGesture {
                    #if DEBUG
                    if CharacterMoodDebug.shared.tapReaction {
                        handleDebugCharTap()
                        return
                    }
                    #endif
                    handleTitleCharTap()
                }

                // 吹き出し（常在ビュー・opacity制御）
                Text(showEyeBubble ? NSLocalizedString("title_bubble_eyes", comment: "") : titleBubbleText)
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2))
                    .opacity(showEyeBubble || showTitleBubble ? 1 : 0)

                // 名前 + Lv
                Text("\(vm.playerData.playerName)  Lv.\(vm.playerData.level)")
                    .font(.zenMaru(20, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
                    .padding(.top, 8)

                // アフターテストバナー
                if showAfterTestBanner {
                    Button {
                        HapticsManager.tap()
                        gameVM.showAfterTest = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("after_test_banner_title")
                                .font(.zenMaru(14, weight: .black))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("after_test_banner_subtitle")
                                .font(.zenMaru(11, weight: .regular))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color(red: 0.85, green: 0.6, blue: 0), Color(red: 1.0, green: 0.75, blue: 0.2)], startPoint: .leading, endPoint: .trailing)))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24).padding(.top, 12)
                }

                Spacer()

                // 段階選択エリア
                VStack(spacing: 14) {
                    if olderPhase == 0 {
                        if vm.canPlay {
                            // スタートボタン（グラデーション+パルス+グロー）
                            startButton {
                                startFlash = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation(.easeOut(duration: 0.2)) { startFlash = false }
                                }
                                HapticsManager.tap()
                                SoundManager.shared.playBossAppear()
                                olderPhase = 1
                            }
                        } else {
                            Button {
                                HapticsManager.tap()
                                Task { try? await PurchaseManager.shared.purchase() }
                            } label: {
                                Text("view_title_upgrade_pro")
                                    .font(.zenMaru(18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity).frame(height: 60)
                                    .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    } else if olderPhase == 1 {
                        // モード選択（8歳ゲーム風）
                        olderBackButton { olderPhase = 0 }
                        olderIconButton(
                            text: NSLocalizedString("older_mode_challenge", comment: ""),
                            icon: UITheme.Older.trainIcon,
                            color: UITheme.Older.trainColor,
                            delay: 0
                        ) {
                            HapticsManager.tap()
                            olderPhase = 2
                        }
                        // バトルボタン（発光+シマー効果）
                        Button {
                                HapticsManager.tap()
                                gameVM.versusIsFamily = false
                                gameVM.showVersus = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: UITheme.Older.battleIcon)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("older_mode_versus")
                                        .font(.zenMaru(UITheme.Older.buttonFontSize, weight: .black))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: UITheme.Older.buttonHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: UITheme.Older.buttonRadius)
                                        .fill(LinearGradient(
                                            colors: [UITheme.Older.battleGradient1, UITheme.Older.battleGradient2],
                                            startPoint: .leading, endPoint: .trailing
                                        ))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: UITheme.Older.buttonRadius)
                                        .stroke(UITheme.Older.battleGlow, lineWidth: 1.5)
                                )
                                .shadow(color: UITheme.Older.battleGradient1.opacity(0.5), radius: 8, y: UITheme.Older.buttonShadowY)
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))

                        // 感情トリガー（連勝/BEST）
                        olderTriggerText
                    } else if olderPhase == 2 {
                        // 難易度選択
                        olderBackButton { olderPhase = 1 }
                        ForEach(Array(Difficulty.allCases.enumerated()), id: \.element) { i, diff in
                            difficultyButton(diff: diff, delay: Double(i) * 0.12) {
                                HapticsManager.tap()
                                selectedDifficultyOlder = diff
                                olderPhase = 3
                            }
                        }
                    } else if olderPhase == 3 {
                        // 問題タイプ選択
                        olderBackButton { olderPhase = 2 }
                        ForEach(Array(ProblemType.allCases.enumerated()), id: \.element) { i, pt in
                            olderAnimatedButton(
                                text: pt.label, color: Color.blue,
                                fontSize: 22, delay: Double(i) * 0.12
                            ) {
                                HapticsManager.tap()
                                gameVM.problemType = pt
                                gameVM.startGame(difficulty: selectedDifficultyOlder)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: olderPhase)
            }

            // 白フラッシュ
            Color.white.ignoresSafeArea()
                .opacity(startFlash ? 0.8 : 0)
                .allowsHitTesting(false)

        }
        .onAppear {
            showAfterTestBanner = DataStore.loadChallenge().completedDays.contains(30)
                && !DataStore.hasCompletedAfterTest()
            olderPhase = 0
            olderBounce = 0
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                olderBounce = -10
            }
            // タイトルキャラ表情タイマー開始
            startTitleIdleTimer()
            // まほうのじかん判定
            let magic = MagicTimeConfig.isMagicTime(
                start: DataStore.loadMagicTimeStart(),
                end: DataStore.loadMagicTimeEnd()
            )
            isMagicTime = magic
            if magic {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }

            // まちがいおに登場 → フルスクリーン演出
            if DataStore.isMistakeBossScheduledToday() && DataStore.loadMistakeLog().count >= MistakeBossConfig.minMistakesRequired {
                DataStore.clearMistakeBossSchedule()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showBossEntrance = true
                }
            }

            // じかんどろぼう登場 → フルスクリーン演出
            if DataStore.isTimeBossScheduledToday() && !DataStore.isTimeBossDefeated() {
                DataStore.clearTimeBossSchedule()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTimeBossEntrance = true
                }
            }
            #if DEBUG
            startMoodAutoChange()
            #endif
        }
        .onChange(of: gameVM.refreshTrigger) { _, _ in
            showAfterTestBanner = DataStore.loadChallenge().completedDays.contains(30)
                && !DataStore.hasCompletedAfterTest()
        }
    }

    // MARK: - Older mode ボタン部品

    // MARK: - スタートボタン（グラデーション+パルス+グロー）

    @ViewBuilder
    private func startButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("view_title_start")
                .font(.zenMaru(28, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.75, blue: 0.35),
                                Color(red: 0.3, green: 0.85, blue: 0.45),
                                Color(red: 0.2, green: 0.75, blue: 0.7)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                .scaleEffect(pulseScale)
        }
        .onAppear {
            pulseScale = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func olderAnimatedButton(text: String, color: Color, fontSize: CGFloat, delay: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.zenMaru(fontSize, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(RoundedRectangle(cornerRadius: 20).fill(color))
                .shadow(color: color.opacity(0.4), radius: 8, y: 4)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func olderIconButton(text: String, icon: String, iconColor: Color = .white, color: Color, delay: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(iconColor)
                    .frame(width: 28)
                Text(text)
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(RoundedRectangle(cornerRadius: 20).fill(color))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func difficultyButton(diff: Difficulty, delay: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(diff.labelWithTime)
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(.white)
                ForEach(0..<diff.starCount, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(RoundedRectangle(cornerRadius: 20).fill(diff.color))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func olderBackButton(action: @escaping () -> Void) -> some View {
        HStack {
            Button {
                HapticsManager.tap()
                action()
            } label: {
                Text("older_back_button")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
    }

    // MARK: - 感情トリガー（8歳）

    @ViewBuilder
    private var olderTriggerText: some View {
        let bestFloor = vm.playerData.bestFloor
        VStack(spacing: 4) {
            if bestFloor > 0 {
                Text("BEST \(bestFloor)F")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(0.8))
            }
        }
        .padding(.top, 4)
    }

    // MARK: - 感情トリガー（5歳）

    @ViewBuilder
    private var youngTriggerText: some View {
        let level = vm.playerData.level
        let xpProgress = vm.xpProgress
        if xpProgress > 0.7 {
            Text("young_trigger_levelup")
                .font(.zenMaru(14, weight: .bold))
                .foregroundStyle(.yellow)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        } else {
            Text("young_trigger_play")
                .font(.zenMaru(14, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - DEBUG表情

    // MARK: - タイトルキャラ表情管理

    private func handleTitleCharTap() {
        HapticsManager.tap()
        SoundManager.shared.playTap()

        // バウンスアニメ
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { charTapped = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { charTapped = false }
        }

        // 目サイズ変更
        randomizeEyeSize()

        titleTapCount += 1

        if titleMood == .sleepy {
            // 寝てる → ワンタップで起きる（吹き出しなし）
            titleMood = .normal
            titleTapCount = 0
            titleLeftEye = 1.0; titleRightEye = 1.0
            resetTitleIdleTimer()
            return
        }

        // タップ吹き出し（sleepy以外）
        showRandomTitleBubble()

        if titleTapCount >= 3 {
            // 連続タップ → ジト目
            titleMood = .squint
            SoundManager.shared.playIncorrect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                titleMood = .normal
                titleTapCount = 0
            }
        } else {
            // 1-2タップ → てれ
            titleMood = .blush
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if titleMood == .blush { titleMood = .normal }
            }
        }

        // タップカウントを3秒後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if titleMood != .squint { titleTapCount = 0 }
        }

        resetTitleIdleTimer()
    }

    private func randomizeEyeSize() {
        let min: CGFloat = 0.5
        let max: CGFloat = 1.131
        let avgSmall: CGFloat = 0.832
        let avgBig: CGFloat = 1.087

        // 10%の確率で両方MAX or 両方MIN
        let special = Int.random(in: 1...10)
        if special == 1 {
            titleLeftEye = max; titleRightEye = max; titleEyeWasBig = true; return
        }
        if special == 2 {
            titleLeftEye = min; titleRightEye = min; titleEyeWasBig = false
            showEyeBubble = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showEyeBubble = false
            }
            return
        }

        // 前回大きかったら今回は小さめ、逆なら大きめ
        let (base1, base2): (CGFloat, CGFloat)
        if titleEyeWasBig {
            base1 = avgSmall + CGFloat.random(in: -0.15...0.05)
            base2 = avgBig + CGFloat.random(in: -0.05...0.04)
        } else {
            base1 = avgBig + CGFloat.random(in: -0.05...0.04)
            base2 = avgSmall + CGFloat.random(in: -0.15...0.05)
        }

        // 左右をランダムに割り当て
        if Bool.random() {
            titleLeftEye = Swift.min(Swift.max(base1, min), max)
            titleRightEye = Swift.min(Swift.max(base2, min), max)
        } else {
            titleLeftEye = Swift.min(Swift.max(base2, min), max)
            titleRightEye = Swift.min(Swift.max(base1, min), max)
        }

        titleEyeWasBig.toggle()
    }

    private func resetTitleIdleTimer() {
        titleIdleTimer?.invalidate()
        titleIdleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
            Task { @MainActor in
                titleMood = .sleepy
            }
        }
    }

    private func showRandomTitleBubble() {
        let keys = [
            "title_bubble_1", "title_bubble_2", "title_bubble_3",
            "title_bubble_4", "title_bubble_5", "title_bubble_6",
            "title_bubble_7", "title_bubble_8", "title_bubble_9",
        ]
        let messages = keys.map { NSLocalizedString($0, comment: "") }
        titleBubbleText = messages.randomElement()!
        showTitleBubble = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showTitleBubble = false
        }
    }

    private func startTitleIdleTimer() {
        titleMood = .normal
        titleTapCount = 0
        resetTitleIdleTimer()
    }

    /// キャラの表情
    private var olderCharMood: KennyCharacterView.IdleMood {
        #if DEBUG
        if debugMood.isEnabled {
            return debugMoodToIdleMood(debugMood.currentMood)
        }
        #endif
        return titleMood
    }

    #if DEBUG
    private func debugMoodToIdleMood(_ mood: CharacterMoodDebug.Mood) -> KennyCharacterView.IdleMood {
        switch mood {
        case .normal:    return .normal
        case .smirk:     return .smirk
        case .blush:     return .blush
        case .squint:    return .squint
        case .surprised: return .surprised
        }
    }

    private func handleDebugCharTap() {
        let mood = CharacterMoodDebug.shared
        // ランダムSE
        let sounds = [
            { SoundManager.shared.playCorrect() },
            { SoundManager.shared.playTap() },
            { SoundManager.shared.playCombo() },
            { SoundManager.shared.playLevelUp() },
        ]
        sounds.randomElement()?()
        HapticsManager.tap()

        // 一瞬表情変更（0.8秒後に戻す）
        let prev = mood.currentMood
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            mood.currentMood = mood.randomMood()
            charTapped = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { charTapped = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                mood.currentMood = prev
            }
        }
    }

    private func startMoodAutoChange() {
        moodTimer?.invalidate()
        moodTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            Task { @MainActor in
                let mood = CharacterMoodDebug.shared
                guard mood.isEnabled && mood.autoChange else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    mood.currentMood = mood.randomMood()
                }
                // 3秒後にnormalに戻す
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        mood.currentMood = .normal
                    }
                }
            }
        }
    }

    private func stopMoodAutoChange() {
        moodTimer?.invalidate()
        moodTimer = nil
    }
    #endif


    // MARK: - プロフィールカード

    @ViewBuilder
    private func profileCard(profile: PlayerProfile) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: profile.avatarColor))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(profile.name.prefix(1)))
                        .font(.zenMaru(14, weight: .black))
                        .foregroundColor(.white)
                )
                .scaleEffect(profileIconBounce == 0 ? 1.0 : 1.05)
            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name)
                    .font(.zenMaru(12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("Lv.\(vm.playerData.level)")
                    .font(.zenMaru(10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                profileIconBounce = 1
            }
        }
    }

    // MARK: - Young Home View（既存）

    @State private var profileIconBounce: CGFloat = 0
    @State private var youngBounce: CGFloat = 0
    @State private var youngCharTapped = false
    @State private var youngStartFlash = false
    @State private var youngPhase: Int = 0  // 0=スタート, 1=モード選択

    private var youngHomeView: some View {
        ZStack {
            // 背景（まほうのじかん対応）
            Group {
                if isMagicTime {
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.4),
                            Color(red: 1.0, green: 0.7, blue: 0.0),
                            Color(red: 0.4, green: 0.9, blue: 0.4),
                            Color(red: 0.3, green: 0.7, blue: 1.0),
                            Color(red: 0.7, green: 0.4, blue: 1.0),
                        ],
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                } else {
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.1)],
                        startPoint: .top, endPoint: .bottom
                    )
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 上部バー
                HStack {
                    #if DEBUG
                    Button("D") { activeSheet = .debugPanel }
                        .font(.zenMaru(12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    #endif

                    // プロフィールカード
                    if let profile = DataStore.activeProfile() {
                        Button {
                            HapticsManager.tap()
                            showProfileSwitcher = true
                        } label: {
                            profileCard(profile: profile)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                    Button {
                        HapticsManager.tap()
                        SoundManager.shared.toggle()
                    } label: {
                        Image(systemName: SoundManager.shared.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title3).foregroundColor(.white)
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.top, 8)
                .zIndex(10)
                .sheet(isPresented: $showProfileSwitcher) {
                    ProfileSwitcherView {
                        vm.refresh()
                        gameVM.refreshTrigger += 1
                    }
                }

                // タイトルロゴ
                Text(NSLocalizedString("title_logo", comment: ""))
                    .font(.zenMaru(18, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                    .padding(.top, 12)

                Spacer()

                // まほうのじかん吹き出し（キャラの上）
                if let speech = magicSpeech {
                    Text(speech)
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2))
                        .opacity(showMagicSpeech ? 1 : 0)
                        .allowsHitTesting(false)
                        .padding(.bottom, 4)
                }

                // キャラクター（でかく・タップで反応）
                ZStack {
                    KennyCharacterView(
                        appearance: CharacterAppearanceFactory.appearance(for: vm.playerData.level),
                        size: UITheme.Young.characterSize
                    )
                    .allowsHitTesting(false)
                }
                .scaleEffect(youngCharTapped ? 1.3 : 1.0)
                .offset(y: youngBounce)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticsManager.tap()
                    SoundManager.shared.playTap()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { youngCharTapped = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { youngCharTapped = false }
                    }
                }

                // 感情トリガー（5歳）
                youngTriggerText
                    .padding(.top, 4)

                // 名前 + Lv
                Text("\(vm.playerData.playerName)  Lv.\(vm.playerData.level)")
                    .font(.zenMaru(20, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
                    .padding(.top, 8)

                Spacer()

                // 段階選択エリア
                VStack(spacing: 14) {
                    if youngPhase == 0 {
                        if vm.canPlay {
                            startButton {
                                youngStartFlash = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation(.easeOut(duration: 0.2)) { youngStartFlash = false }
                                }
                                HapticsManager.tap()
                                SoundManager.shared.playBossAppear()
                                if DataStore.loadAgeGroup() == .young4 {
                                    startYoungBattle()
                                } else {
                                    youngPhase = 1
                                }
                            }
                        } else {
                            Button {
                                HapticsManager.tap()
                                Task { try? await PurchaseManager.shared.purchase() }
                            } label: {
                                Text("view_title_upgrade_pro")
                                    .font(.zenMaru(18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 240, height: 60)
                                    .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    } else if youngPhase == 1 {
                        olderBackButton { youngPhase = 0 }
                        olderIconButton(
                            text: NSLocalizedString("older_mode_challenge", comment: ""),
                            icon: UITheme.Young.trainIcon,
                            color: UITheme.Young.trainColor,
                            delay: 0
                        ) {
                            HapticsManager.tap()
                            startYoungBattle()
                        }
                        olderIconButton(
                            text: NSLocalizedString("older_mode_versus", comment: ""),
                            icon: UITheme.Young.battleIcon,
                            color: UITheme.Young.battleColor,
                            delay: 0.15
                        ) {
                            HapticsManager.tap()
                            gameVM.versusIsFamily = false
                            gameVM.showVersus = true
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: youngPhase)
            }

            // 白フラッシュ
            Color.white.ignoresSafeArea()
                .opacity(youngStartFlash ? 0.8 : 0)
                .allowsHitTesting(false)
        }
        .onAppear {
            youngPhase = 0
            youngBounce = 0
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { youngBounce = -10 }

            // まほうのじかん判定（全モード共通）
            let magic = MagicTimeConfig.isMagicTime(
                start: DataStore.loadMagicTimeStart(),
                end: DataStore.loadMagicTimeEnd()
            )
            isMagicTime = magic
            if magic {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) { animateGradient = true }
                startMagicSpeechLoop()
            }

            // タブ復帰時にアニメーションを再トリガー
            let p = DataStore.loadPlayerData()
            let s = DataStore.loadSessionHistory()
            let m = DataStore.loadMistakeLog()
            let result = PlayerStats.calculate(player: p, sessions: s, mistakes: m)
            statsCurrent = result.current
            statsPrevious = result.previous
            let lastPower = DataStore.loadLastPowerLevel()
            powerDiff = statsCurrent.powerLevel - lastPower

            // アニメーション起動
            ringAnimated = false
            statsAnimated = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                ringAnimated = true
                statsAnimated = true
            }

            // まちがいおに登場 → フルスクリーン演出
            if DataStore.isMistakeBossScheduledToday() && DataStore.loadMistakeLog().count >= MistakeBossConfig.minMistakesRequired {
                DataStore.clearMistakeBossSchedule()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showBossEntrance = true
                }
            }

            // じかんどろぼう登場 → フルスクリーン演出
            if DataStore.isTimeBossScheduledToday() && !DataStore.isTimeBossDefeated() {
                DataStore.clearTimeBossSchedule()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTimeBossEntrance = true
                }
            }

            // 破壊演出: GameViewModel から破壊起点インデックスを受け取る
            let currentDone = min(DataStore.loadDailyMission().playCount, DailyMission.requiredPlays)
            if let fromIndex = gameVM.pendingBreakFromIndex, fromIndex < currentDone {
                // ゲーム後に増えた → 破壊演出トリガー
                breakingSlotIndex = fromIndex
                missionCardId = UUID()  // カードを強制再生成
                gameVM.pendingBreakFromIndex = nil  // 消費済み
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    breakingSlotIndex = -1
                }
            } else {
                // 初回表示 or 変化なし：演出なし
                gameVM.pendingBreakFromIndex = nil
                breakingSlotIndex = -1
            }
        }
    }

    // MARK: - youngモードバトル開始

    private func startYoungBattle() {
        if DataStore.loadAgeGroup() == .young4 {
            gameVM.startGame(difficulty: .easy)
        } else {
            // 5歳モード: たすテスト不要、直接バトル開始
            var challenge = DataStore.loadChallenge()
            if !challenge.isActive { challenge = DataStore.startChallenge() }
            let day = challenge.currentDay
            if day <= 30 && !challenge.completedDays.contains(day) {
                gameVM.startChallengeDay(day)
            } else {
                gameVM.startGame(difficulty: .easy)
            }
        }
    }

    // MARK: - ビフォーテストフロー

    @ViewBuilder
    private var beforeTestFlow: some View {
        if beforeTestPhase == 0 {
            BeforeTestView { score, total, level, avgTime in
                beforeTestScore = score
                beforeTestAvgTime = avgTime
                DataStore.saveBeforeTestResult(score: score, total: total, level: level)
                withAnimation { beforeTestPhase = 1 }
            }
        } else {
            BeforeTestResultView(
                score: beforeTestScore,
                total: BeforeTestView.totalQuestions,
                avgTime: beforeTestAvgTime
            ) {
                activeSheet = nil
                beforeTestPhase = 0
                vm.refresh()
            }
        }
    }

    // MARK: - まほうのじかん吹き出しループ

    private func startMagicSpeechLoop() {
        // 最初の表示（1秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showNextMagicSpeech()
        }
        // 以降5秒ごと
        magicSpeechTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                showNextMagicSpeech()
            }
        }
    }

    private func showNextMagicSpeech() {
        guard isMagicTime else { return }
        magicSpeech = MagicTimeConfig.speeches.randomElement()
        withAnimation(.easeIn(duration: 0.3)) { showMagicSpeech = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.3)) { showMagicSpeech = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { magicSpeech = nil }
        }
    }

    private func stopMagicSpeechLoop() {
        magicSpeechTimer?.invalidate()
        magicSpeechTimer = nil
    }

    // MARK: - youngモード チャレンジバナー（シンプル・大きい）

    private var youngChallengeBanner: some View {
        let challenge = DataStore.loadChallenge()

        return Button {
            if !challenge.isActive {
                _ = DataStore.startChallenge()
            }
            let latestChallenge = DataStore.loadChallenge()
            let day = latestChallenge.currentDay
            if day <= 30 && !latestChallenge.completedDays.contains(day) {
                gameVM.startChallengeDay(day)
            }
        } label: {
            HStack(spacing: 16) {
                Text("⭐️")
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("title_daily_challenge", comment: ""))
                        .font(.zenMaru(22, weight: .black))
                        .foregroundStyle(.white)

                    if challenge.isActive {
                        Text("Day \(challenge.currentDay)")
                            .font(.zenMaru(16, weight: .bold))
                            .foregroundStyle(.yellow)
                    }
                }

                Spacer()

                Text("▶︎")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 30日チャレンジバナー

    private var challengeBanner: some View {
        let challenge = DataStore.loadChallenge()
        let progress = Double(challenge.completedDays.count) / 30.0
        let dayLabel = challenge.isActive ? "Day \(challenge.currentDay) / 30" : "はじめよう！"

        return Button {
            if !challenge.isActive {
                _ = DataStore.startChallenge()
            }
            showChallengeMap = true
        } label: {
            HStack(spacing: 12) {
                Text("🗺️")

                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("title_30day_challenge", comment: ""))
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundStyle(.white)

                    if challenge.isActive {
                        ProgressView(value: progress)
                            .tint(.yellow)

                        Text(dayLabel)
                            .font(.zenMaru(11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text(dayLabel)
                            .font(.zenMaru(12, weight: .bold))
                            .foregroundStyle(.yellow)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showChallengeMap) {
            let latestChallenge = DataStore.loadChallenge()
            ChallengeMapView(
                challenge: latestChallenge,
                onStartDay: { day in
                    showChallengeMap = false
                    gameVM.startChallengeDay(day)
                },
                onClose: {
                    showChallengeMap = false
                }
            )
        }
    }

    // MARK: - Daily Mission Card

    private var dailyMissionCard: some View {
        let done = min(vm.dailyMission.playCount, DailyMission.requiredPlays)
        let isAllDone = done >= DailyMission.requiredPlays

        return VStack(spacing: 8) {
            // ヘッダー
            HStack {
                Text(isAllDone ? "⭐" : "⛏️")
                    .font(.system(size: 18))
                Text(isAllDone
                     ? NSLocalizedString("challenge_clear", comment: "")
                     : NSLocalizedString("challenge_title", comment: ""))
                    .font(.zenMaru(12, weight: .regular))
                    .foregroundColor(isAllDone
                        ? Color(red: 0.573, green: 0.251, blue: 0.055)
                        : Color.secondary)
                Spacer()
                if isAllDone {
                    Text(NSLocalizedString("challenge_achieved", comment: ""))
                        .font(.zenMaru(11, weight: .bold))
                        .foregroundColor(Color(red: 0.573, green: 0.251, blue: 0.055))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.988, green: 0.827, blue: 0.302))
                        .clipShape(Capsule())
                }
            }

            // 岩/ダイヤスロット
            HStack(spacing: 16) {
                ForEach(0..<DailyMission.requiredPlays, id: \.self) { i in
                    let shouldBreak = breakingSlotIndex >= 0 && i >= breakingSlotIndex && i < done
                    VStack(spacing: 4) {
                        RockDiamondSlotView(
                            isDone: i < done,
                            breakDelay: shouldBreak ? 0.5 + Double(i - breakingSlotIndex) * 1.0 : nil
                        )
                        .id("\(missionCardId)-\(i)")
                        Text(i < done && !shouldBreak ? "GET!" : "")
                            .font(.zenMaru(9, weight: .bold))
                            .foregroundColor(Color(red: 0.118, green: 0.533, blue: 0.898))
                            .frame(height: 12)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            // 残り回数テキスト（未達成時のみ）
            if !isAllDone {
                let remaining = DailyMission.requiredPlays - done
                Text(String(format: NSLocalizedString("challenge_remaining", comment: ""), remaining))
                    .font(.zenMaru(12, weight: .bold))
                    .foregroundColor(Color(red: 0.573, green: 0.251, blue: 0.055))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isAllDone
                    ? Color(red: 1.0, green: 0.984, blue: 0.922)
                    : Color(red: 0.953, green: 0.957, blue: 1.0))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isAllDone
                        ? Color(red: 0.988, green: 0.827, blue: 0.302)
                        : Color(red: 0.686, green: 0.678, blue: 0.910),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - BGM Tab View

struct BGMTabView: View {
    var soundManager: SoundManager

    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .red
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("BGM")
                .font(.zenMaru(20, weight: .black))
                .padding(.top, 24)
                .padding(.bottom, 16)

            List {
                // 解放済みBGM
                ForEach(SoundManager.bgmList.filter { !$0.isLocked }, id: \.name) { bgm in
                    BGMRow(
                        bgmName: bgm.name,
                        bgmLabel: bgm.label,
                        rainbowColors: rainbowColors,
                        soundManager: soundManager
                    )
                }

                // ロック中BGM
                ForEach(SoundManager.bgmList.filter { $0.isLocked }, id: \.name) { bgm in
                    HStack {
                        Text("🔒")
                            .opacity(0.4)
                        Text(bgm.label)
                            .font(.zenMaru(16, weight: .bold))
                            .foregroundColor(.primary.opacity(0.4))
                        Spacer()
                    }
                    .frame(minHeight: 56)
                }
                .listRowBackground(Color(.systemGray6))

                // 解除ヒント
                Text("bgm_unlock_hint")
                    .font(.zenMaru(11, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
    }
}

// MARK: - BGM Row

/// soundManager.selectedBGM (String) を直接 onChange で監視し、
/// 自行が選択中かどうかを判定する。タプル渡しを廃止して Equatable な値のみ保持。
struct BGMRow: View {
    let bgmName: String
    let bgmLabel: String
    let rainbowColors: [Color]
    var soundManager: SoundManager

    @State private var bouncing = false
    @State private var noteAnimate = false

    private var isSelected: Bool {
        soundManager.selectedBGM == bgmName
    }

    var body: some View {
        Button {
            soundManager.playTap()
            soundManager.selectBGM(bgmName)
            soundManager.playBGM(bgmName)
            bouncing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                bouncing = false
            }
        } label: {
            HStack {
                // タイトル
                Text(bgmLabel)
                    .font(isSelected ? .zenMaru(20, weight: .black) : .zenMaru(16, weight: .bold))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: rainbowColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(Color.primary)
                    )

                Spacer()

                // 音符アイコン
                Image(systemName: "music.note")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: rainbowColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color.blue.opacity(0.4))
                    )
                    .scaleEffect(noteAnimate ? 1.35 : 1.0)
                    .opacity(noteAnimate ? 1.0 : 0.65)
                    .animation(
                        isSelected
                            ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.15),
                        value: noteAnimate
                    )
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .scaleEffect(bouncing ? 1.06 : 1.0)
        .animation(.spring(duration: 0.25, bounce: 0.5), value: bouncing)
        .listRowBackground(
            isSelected
                ? Color.blue.opacity(0.06)
                : Color.clear
        )
        .onAppear {
            noteAnimate = isSelected
            print("🎵 [BGMRow] \(bgmName) onAppear isSelected=\(isSelected)")
        }
        .onChange(of: soundManager.selectedBGM) { _, newBGM in
            let nowSelected = (newBGM == bgmName)
            print("🎵 [BGMRow] \(bgmName) isSelected -> \(nowSelected) (selectedBGM=\(newBGM))")
            noteAnimate = nowSelected
        }
    }
}
