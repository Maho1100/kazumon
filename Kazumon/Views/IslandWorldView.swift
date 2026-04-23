import SwiftUI

// MARK: - 球体アイテム

/// 植樹時の「+スライム」ポップアップ
struct PlantPopup: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let color: Color
    var floatY: CGFloat = 0
    var opacity: Double = 1.0
}

/// コイン+1 ポップアップ
struct CoinPopup: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    var floatY: CGFloat = 0
    var opacity: Double = 1.0
}

struct WanderingSlime: Identifiable {
    let id = UUID()
    let color: Color
    var x: CGFloat   // -0.5 〜 0.5（島の幅に対する比率）
    var y: CGFloat   // -0.5 〜 0.5（島の高さに対する比率）
    var jumpY: CGFloat = 0      // 上下のジャンプオフセット (pt)
    var visible: Bool = true    // 表示中
    var disappearScale: CGFloat = 1.0   // 消える時の縮小
    var disappearOpacity: Double = 1.0
    var shakeOffset: CGFloat = 0
    var hitTriggerCount: Int = 0  // タップ反応用
    var isFighting: Bool = false  // 喧嘩中
    var fightShake: CGFloat = 0   // 喧嘩用の左右シェイク
}

struct IslandItem: Identifiable {
    let id: String
    let label: String
    let imageName: String
    let isLocked: Bool
    var angle: Double
    /// アイテムごとの X/Y ランダムオフセット（球体上の位置ずらし）
    let jitterX: CGFloat
    let jitterY: CGFloat
    /// 解放に必要なレベル (ロック中のみ表示)
    var requiredLevel: Int = 0
    /// 新しく解放されたか (NEW! バッジ用)
    var isNewlyUnlocked: Bool = false
}

// MARK: - IslandWorldView

struct IslandWorldView: View {
    let gameVM: GameViewModel

    @State private var islandState = DataStore.loadIslandState()
    @State private var showSettings = false
    @State private var showLockedBubble = false
    @State private var lockedBubbleText = ""

    // 球体アイテム（レベルで解放）
    @State private var items: [IslandItem] = []
    @State private var showUnlockFlash = false
    @State private var unlockMessage = ""
    @State private var showUnlockMessage = false

    private static func buildItems(level: Int) -> [IslandItem] {
        [
            IslandItem(id: "battle",  label: NSLocalizedString("island_label_battle", comment: ""),  imageName: "island_battle",  isLocked: false, angle: 0,
                       jitterX: 15, jitterY: -8),
            IslandItem(id: "family",  label: NSLocalizedString("island_label_family", comment: ""),  imageName: "figure.2.and.child.holdinghands",  isLocked: false, angle: 60,
                       jitterX: -10, jitterY: 5),
            IslandItem(id: "bgm",     label: NSLocalizedString("island_label_bgm", comment: ""),     imageName: "island_bgm",     isLocked: false, angle: 120,
                       jitterX: -20, jitterY: 5),
            IslandItem(id: "kisekae", label: NSLocalizedString("island_label_kisekae", comment: ""), imageName: "island_kisekae", isLocked: level < 5, angle: 180,
                       jitterX: 25, jitterY: -3,
                       requiredLevel: 5,
                       isNewlyUnlocked: level >= 5 && !DataStore.hasShownUnlockBanner(shop: "kisekae")),
            IslandItem(id: "koukan",  label: NSLocalizedString("island_label_koukan", comment: ""),  imageName: "island_koukan",  isLocked: level < 3, angle: 240,
                       jitterX: -15, jitterY: 10,
                       requiredLevel: 3,
                       isNewlyUnlocked: level >= 3 && !DataStore.hasShownUnlockBanner(shop: "koukan")),
            IslandItem(id: "tree",    label: NSLocalizedString("island_label_tree", comment: ""),       imageName: "island_tree",    isLocked: false, angle: 300,
                       jitterX: 0, jitterY: 0),
        ]
    }
    @State private var lastDragY: CGFloat = 0
    private let dragSensitivity: Double = -0.4

    // キャラ
    @State private var charOffsetX: CGFloat = 0
    @State private var charTimer: Timer?

    // ボタン別セリフ吹き出し
    @State private var shopBubbleText = ""
    @State private var showShopBubble = false
    @State private var lastShopBubbleId = ""

    // キャラタップ表情
    @State private var titleMood: KennyCharacterView.IdleMood = .normal
    @State private var titleTapCount = 0
    @State private var titleIdleTimer: Timer?
    @State private var titleLeftEye: CGFloat = 1.0
    @State private var titleRightEye: CGFloat = 1.0
    @State private var titleEyeWasBig = false
    @State private var showEyeBubble = false
    @State private var titleBubbleText = ""
    @State private var showTitleBubble = false
    @State private var charTapped = false
    @State private var charSleeping = false

    // プロフィール
    @State private var showProfileSwitcher = false
    @State private var profileIconBounce: CGFloat = 0

    @State private var selectedDifficulty: Difficulty = .normal

    // BGM店
    @State private var showBGMSheet = false
    // きせかえショップ
    @State private var showKisekaeShop = false
    // 交換所
    @State private var showKoukanShop = false

    // お店入店演出
    @State private var isEnteringShop = false
    @State private var enteringShopId: String?
    @State private var shopEnterScale: CGFloat = 1.0
    @State private var shopEnterOffset: CGSize = .zero
    @State private var otherItemsOpacity: Double = 1.0
    @State private var shopFlashOpacity: Double = 0
    @State private var showBattleShop = false
    @State private var showYoung4BattleChoice = false
    #if DEBUG
    @State private var menuOffsetX: CGFloat = -0.45
    @State private var menuOffsetY: CGFloat = 0.40
    @State private var charOffsetXR: CGFloat = 0.08
    @State private var charOffsetYR: CGFloat = -0.30
    @State private var showMenuDebug = false
    #endif
    @State private var showBossEntrance = false
    @State private var showTimeBossEntrance = false
    @State private var shopShakeAngle: Double = 0

    #if DEBUG
    @State private var showDebugPanel = false
    @State private var showSphereDebug = false
    @State private var dbgCenterYRatio: Double = 0.62
    @State private var dbgYRadius: Double = 0.32
    @State private var dbgXRadius: Double = 0.26
    @State private var dbgXCurve: Double = 0.89
    @State private var dbgScaleMin: Double = 0.16
    @State private var dbgScalePow: Double = 3.9
    @State private var dbgIslandY: Double = 0.11
    @State private var dbgIslandW: Double = 1.42
    @State private var dbgIslandH: Double = 0.74
    #endif

    // 雲
    @State private var cloud1X: CGFloat = -120
    @State private var cloud2X: CGFloat = -200
    @State private var cloud3X: CGFloat = -80

    // 火山アニメーション
    @State private var volcanoScale: CGFloat = 1.0
    @State private var volcanoStretch: CGFloat = 1.0  // 縦伸び
    @State private var volcanoTint: Double = 0       // 色変化 0=通常 / 1=赤強め
    @State private var volcanoGlowScale: CGFloat = 0.5  // 赤い波紋
    @State private var volcanoGlowOpacity: Double = 0.6
    @State private var smokeCloudY: CGFloat = 0      // 噴煙の雲を上に流す
    @State private var smokeCloudOpacity: Double = 1.0
    @State private var smokeCloudScale: CGFloat = 0.6
    // 噴煙パフ (3つを位相ずらして表示)
    @State private var puff1Phase: Double = 0
    @State private var puff2Phase: Double = 0.33
    @State private var puff3Phase: Double = 0.66

    // 散歩スライム
    @State private var wanderSlimes: [WanderingSlime] = []

    // 植えた木
    @State private var plantedTrees: [PlantedTree] = []
    // 植樹モード（購入直後にtrueになり、島タップで植える）
    @State private var plantingMode: Bool = false

    // 木を植えた時のフィードバック演出
    @State private var plantPopups: [PlantPopup] = []
    @State private var coinPopups: [CoinPopup] = []

    // 植樹プレビュー（指の位置に丸い輪、植えられるかで色変化）
    @State private var plantPreviewPos: CGPoint? = nil
    @State private var plantPreviewValid: Bool = true

    // 宝箱
    @State private var chestPos: (x: Double, y: Double) = (0, 0)
    @State private var chestOpened: Bool = false
    @State private var chestVisible: Bool = true
    @State private var chestBubbleText: String? = nil
    @State private var chestBounce: CGFloat = 0
    @State private var dailyMissionFullyComplete: Bool = false

    // まほうのじかん (虹色オーバーレイ)
    @State private var isMagicTime = false
    @State private var magicGradientAnimate = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                islandBackground(w: w, h: h)

                // まほうのじかん用 虹色グラデーション（背景の上に重ねる）
                if isMagicTime {
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.4),
                            Color(red: 1.0, green: 0.7, blue: 0.0),
                            Color(red: 0.4, green: 0.9, blue: 0.4),
                            Color(red: 0.3, green: 0.7, blue: 1.0),
                            Color(red: 0.7, green: 0.4, blue: 1.0),
                        ],
                        startPoint: magicGradientAnimate ? .topLeading : .bottomTrailing,
                        endPoint: magicGradientAnimate ? .bottomTrailing : .topLeading
                    )
                    .ignoresSafeArea()
                    .opacity(0.5)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                }

                islandGround(w: w, h: h)
                seaLayer(w: w, h: h)

                // 植樹モード時の島タップ検出 + プレビュー表示
                if plantingMode {
                    ZStack {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("islandRoot"))
                                    .onChanged { value in
                                        updatePlantPreview(at: value.location, in: CGSize(width: w, height: h))
                                    }
                                    .onEnded { value in
                                        handlePlantTap(at: value.location, in: CGSize(width: w, height: h))
                                        plantPreviewPos = nil
                                    }
                            )

                        // プレビュー（指の位置に木アイコン + 色付き輪）
                        if let pos = plantPreviewPos {
                            ZStack {
                                Circle()
                                    .fill((plantPreviewValid ? Color.cyan : Color.red).opacity(0.25))
                                    .frame(width: 70, height: 70)
                                Circle()
                                    .stroke(plantPreviewValid ? Color.cyan : Color.red, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                Image("island_tree")
                                    .resizable().scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .opacity(plantPreviewValid ? 0.9 : 0.5)
                            }
                            .shadow(color: (plantPreviewValid ? Color.cyan : Color.red).opacity(0.6), radius: 8)
                            .position(pos)
                            .allowsHitTesting(false)
                        }
                    }
                    .zIndex(50)
                }

                decorationsLayer(w: w, h: h)
                    .opacity(otherItemsOpacity)

                // 植えた木
                plantedTreesLayer(w: w, h: h)
                    .opacity(otherItemsOpacity)
                    .allowsHitTesting(plantingMode)

                // 散歩スライム
                wanderSlimeLayer(w: w, h: h)
                    .opacity(otherItemsOpacity)

                // 宝箱
                treasureChestLayer(w: w, h: h)
                    .opacity(otherItemsOpacity)

                // ポップアップ
                plantPopupsLayer(w: w, h: h)
                    .allowsHitTesting(false)
                coinPopupsLayer(w: w, h: h)
                    .allowsHitTesting(false)

                // 雲（島の前面を流れる）
                cloudsLayer(w: w, h: h)
                    .opacity(otherItemsOpacity)
                    .allowsHitTesting(false)

                // マリカー風メニュー（島と独立、固定位置）
                mainMenuLayer(w: w, h: h)
                    .zIndex(90)
                    .allowsHitTesting(!isEnteringShop)

                uiOverlayLayer(w: w, h: h)
                    .opacity(otherItemsOpacity)
                    .zIndex(80)

                // 入店フラッシュ
                Color.white.ignoresSafeArea()
                    .opacity(shopFlashOpacity)
                    .allowsHitTesting(false)

                // 解放フラッシュ
                Color.white.ignoresSafeArea()
                    .opacity(showUnlockFlash ? 0.9 : 0)
                    .allowsHitTesting(false)

                // 解放メッセージ（画面中央）
                if showUnlockMessage {
                    Text(unlockMessage)
                        .font(.zenMaru(22, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.7)))
                        .shadow(color: .yellow.opacity(0.5), radius: 12)
                        .position(x: w / 2, y: h / 2)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(200)
                }

                // カムバックボーナスポップアップ
                if gameVM.comebackBonus > 0 {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            Text("🎉").font(.system(size: 48))
                            Text(NSLocalizedString("comeback_title", comment: ""))
                                .font(.zenMaru(20, weight: .black))
                                .foregroundColor(.white)
                            Text(String(format: NSLocalizedString("comeback_reward", comment: ""), gameVM.comebackBonus))
                                .font(.zenMaru(16, weight: .bold))
                                .foregroundColor(.yellow)
                            Button {
                                withAnimation { gameVM.comebackBonus = 0 }
                            } label: {
                                Text(NSLocalizedString("comeback_dismiss", comment: ""))
                                    .font(.zenMaru(16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24).padding(.vertical, 12)
                                    .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(24)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.15, green: 0.15, blue: 0.25)))
                        .shadow(color: .black.opacity(0.3), radius: 16, y: 6)
                    }
                    .zIndex(300)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .coordinateSpace(name: "islandRoot")
        }
        .ignoresSafeArea()
        .gesture(sphereDrag)
        .onAppear {
            AnalyticsManager.logViewIsland()
            AnalyticsManager.trackScreenEnter("island")
            let level = DataStore.loadPlayerData().level
            items = Self.buildItems(level: level)
            checkNewUnlocks(level: level)
            startCloudAnimation()
            // 植えた木を読み込む
            plantedTrees = DataStore.loadPlantedTrees()
            startWanderingSlimes()
            // 宝箱の位置と状態
            chestPos = DataStore.loadTreasureChestPosition()
            // デイリーミッション全クリア状態
            dailyMissionFullyComplete = DataStore.isDailyMissionFullyComplete()
            // まちがいおに登場チェック
            if DataStore.isMistakeBossScheduledToday() && DataStore.loadMistakeLog().count >= MistakeBossConfig.minMistakesRequired {
                DataStore.clearMistakeBossSchedule()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showBossEntrance = true
                }
            }
            // じかんどろぼう登場チェック
            if DataStore.isTimeBossScheduledToday() && !DataStore.isTimeBossDefeated() {
                DataStore.clearTimeBossSchedule()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showTimeBossEntrance = true
                }
            }
            // カムバックボーナス（3日以上不在→コイン報酬）
            let comeback = DataStore.checkComebackBonus()
            if comeback > 0 {
                gameVM.comebackBonus = comeback
            }
            // 木購入時に植樹モードを有効化
            NotificationCenter.default.addObserver(forName: .treePurchased, object: nil, queue: .main) { _ in
                plantingMode = true
            }
            // プロファイル切替時に島データを再読込
            NotificationCenter.default.addObserver(forName: .activeProfileChanged, object: nil, queue: .main) { _ in
                refreshIslandForProfile()
            }
            // まほうのじかん判定
            isMagicTime = MagicTimeConfig.isMagicTime(
                start: DataStore.loadMagicTimeStart(),
                end: DataStore.loadMagicTimeEnd()
            )
            if isMagicTime {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                    magicGradientAnimate = true
                }
            }
            startCharacterAutonomous()
            startTitleIdleTimer()
        }
        .onDisappear {
            charTimer?.invalidate(); charTimer = nil
            titleIdleTimer?.invalidate(); titleIdleTimer = nil
        }
        .sheet(isPresented: $showSettings) { SettingsView(showCloseButton: true) }
        .sheet(isPresented: $showProfileSwitcher) { ProfileSwitcherView { gameVM.refreshTrigger += 1 } }
        .sheet(isPresented: $showBGMSheet) {
            NavigationStack {
                BGMTabView(soundManager: SoundManager.shared)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showBGMSheet = false } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showBattleShop) {
            BattleShopView(gameVM: gameVM) { showBattleShop = false }
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
        .sheet(isPresented: $showYoung4BattleChoice) {
            young4BattleChoiceSheet
                .presentationDetents([.height(260)])
        }
        .fullScreenCover(isPresented: $showKisekaeShop) {
            KisekaeShopView(gameVM: gameVM) { showKisekaeShop = false }
        }
        .fullScreenCover(isPresented: $showKoukanShop) {
            KoukanShopView(gameVM: gameVM) { showKoukanShop = false }
        }
        #if DEBUG
        .sheet(isPresented: $showDebugPanel) { DebugPanelView(gameVM: gameVM) {} }
        #endif
    }

    // MARK: - 球体パラメータ（DEBUG時はスライダー調整可能）

    private var sphereCenterYRatio: Double {
        #if DEBUG
        return dbgCenterYRatio
        #else
        return 0.62
        #endif
    }
    private var sphereYRadius: Double {
        #if DEBUG
        return dbgYRadius
        #else
        return 0.32
        #endif
    }
    private var sphereXRadius: Double {
        #if DEBUG
        return dbgXRadius
        #else
        return 0.26
        #endif
    }
    private var sphereXCurve: Double {
        #if DEBUG
        return dbgXCurve
        #else
        return 0.89
        #endif
    }
    private var sphereScaleMin: Double {
        #if DEBUG
        return dbgScaleMin
        #else
        return 0.16
        #endif
    }
    private var sphereScalePow: Double {
        #if DEBUG
        return dbgScalePow
        #else
        return 3.9
        #endif
    }
    private var islandYRatio: Double {
        #if DEBUG
        return dbgIslandY
        #else
        return 0.11
        #endif
    }
    private var islandWRatio: Double {
        #if DEBUG
        return dbgIslandW
        #else
        return 1.42
        #endif
    }
    private var islandHRatio: Double {
        #if DEBUG
        return dbgIslandH
        #else
        return 0.74
        #endif
    }

    // MARK: - 球体座標計算

    private func normalizeAngle(_ a: Double) -> Double {
        var v = a.truncatingRemainder(dividingBy: 360)
        if v > 180 { v -= 360 }
        if v < -180 { v += 360 }
        return v
    }

    private func spherePosition(for angle: Double, in size: CGSize) -> CGPoint {
        let norm = normalizeAngle(angle)
        let rad = norm * .pi / 180
        let centerY = size.height * sphereCenterYRatio
        let yRadius = size.height * sphereYRadius
        let y = centerY - sin(rad) * yRadius
        let xRadius = size.width * sphereXRadius
        let x = size.width * 0.5 + cos(rad) * xRadius * sphereXCurve
        return CGPoint(x: x, y: y)
    }

    private func sphereScale(for angle: Double) -> CGFloat {
        let norm = normalizeAngle(angle)
        let rad = norm * .pi / 180
        let cosVal = cos(rad)
        let normalized = (cosVal + 1.0) / 2.0
        let curved = pow(normalized, sphereScalePow)
        let minS = sphereScaleMin
        return CGFloat(minS + curved * (1.0 - minS))
    }

    private func sphereOpacity(for angle: Double) -> Double {
        let sc = Double(sphereScale(for: angle))
        if sc < 0.3 { return max(0, (sc - sphereScaleMin) / (0.3 - sphereScaleMin)) }
        return 1.0
    }

    // MARK: - 球体ドラッグ

    private var sphereDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isEnteringShop else { return }
                let delta = value.translation.height - lastDragY
                lastDragY = value.translation.height
                for i in items.indices {
                    items[i].angle += delta * dragSensitivity
                    if items[i].angle > 180 { items[i].angle -= 360 }
                    if items[i].angle < -180 { items[i].angle += 360 }
                }
            }
            .onEnded { _ in
                lastDragY = 0
                snapToNearest()
            }
    }

    private func snapToNearest() {
        guard let nearest = items.min(by: {
            abs(normalizeAngle($0.angle)) < abs(normalizeAngle($1.angle))
        }) else { return }
        let diff = -normalizeAngle(nearest.angle)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            for i in items.indices {
                items[i].angle += diff
                if items[i].angle > 180 { items[i].angle -= 360 }
                if items[i].angle < -180 { items[i].angle += 360 }
            }
        }
        // スナップ先のアイテムでセリフ表示
        showShopBubbleFor(nearest)
    }

    // MARK: - ボタン別セリフ

    private static let shopLineKeys: [String: [String]] = [
        "battle":  ["island_bubble_battle_1",  "island_bubble_battle_2",  "island_bubble_battle_3"],
        "bgm":     ["island_bubble_bgm_1",     "island_bubble_bgm_2",     "island_bubble_bgm_3"],
        "kisekae": ["island_bubble_kisekae_1", "island_bubble_kisekae_2", "island_bubble_kisekae_3"],
        "koukan":  ["island_bubble_koukan_1",  "island_bubble_koukan_2",  "island_bubble_koukan_3"],
    ]

    private func showShopBubbleFor(_ item: IslandItem) {
        let sc = sphereScale(for: item.angle)
        // スケール80%以上（= ボタンが前面に十分大きく表示されている）
        guard sc >= 0.8 else { return }
        // 同じボタンで既に表示中ならキャンセル
        guard item.id != lastShopBubbleId || !showShopBubble else { return }

        guard let keys = Self.shopLineKeys[item.id],
              let key = keys.randomElement() else { return }
        let line = NSLocalizedString(key, comment: "")

        lastShopBubbleId = item.id
        shopBubbleText = line
        showShopBubble = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if lastShopBubbleId == item.id {
                showShopBubble = false
            }
        }
    }

    // MARK: - マリカー風メニュー

    @ViewBuilder
    private func mainMenuLayer(w: CGFloat, h: CGFloat) -> some View {
        let isYoung4 = DataStore.loadAgeGroup() == .young4

        ZStack(alignment: .bottomTrailing) {
            // 左: メニューリスト
            VStack(alignment: .leading, spacing: 16) {
                #if DEBUG
                Spacer().frame(height: h * menuOffsetY)
                #else
                Spacer().frame(height: h * 0.28)
                #endif

                menuItem(
                    icon: "bolt.fill",
                    iconColor: Color(red: 0.30, green: 0.72, blue: 0.49),
                    label: NSLocalizedString("menu_solo", comment: "")
                ) {
                    HapticsManager.tap(); SoundManager.shared.playTap()
                    if isYoung4 {
                        gameVM.startGame(difficulty: .easy)
                    } else {
                        showBattleShop = true
                    }
                }

                menuItem(
                    icon: "person.3.fill",
                    iconColor: Color(red: 0.48, green: 0.44, blue: 0.86),
                    label: NSLocalizedString("menu_family", comment: "")
                ) {
                    HapticsManager.tap(); SoundManager.shared.playTap()
                    gameVM.showVersus = true
                }

                menuItem(
                    icon: "tshirt.fill",
                    iconColor: Color(red: 0.85, green: 0.45, blue: 0.65),
                    label: NSLocalizedString("menu_kisekae", comment: ""),
                    locked: DataStore.loadPlayerData().level < 5
                ) {
                    HapticsManager.tap(); SoundManager.shared.playTap()
                    if DataStore.loadPlayerData().level >= 5 {
                        showKisekaeShop = true
                    } else {
                        showLockedMessage()
                    }
                }

                menuItem(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: Color(red: 0.85, green: 0.65, blue: 0.20),
                    label: NSLocalizedString("menu_koukan", comment: ""),
                    locked: DataStore.loadPlayerData().level < 3
                ) {
                    HapticsManager.tap(); SoundManager.shared.playTap()
                    if DataStore.loadPlayerData().level >= 3 {
                        showKoukanShop = true
                    } else {
                        showLockedMessage()
                    }
                }

                Spacer()

                // 下部サブアイコン
                HStack(spacing: 20) {
                    subIcon(icon: "music.note", color: .cyan) {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        showBGMSheet = true
                    }
                    subIcon(icon: "leaf.fill", color: .green) {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        plantingMode = true
                    }
                    subIcon(icon: "chart.line.uptrend.xyaxis", color: .orange) {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        showSettings = true
                    }
                }
                .opacity(0.7)
                .padding(.bottom, 40)
            }
            .padding(.leading, 16)
            #if DEBUG
            .offset(x: w * menuOffsetX)
            #else
            .offset(x: -w * 0.50)
            #endif

            // 右下: キャラクター（大きく表示）
            KennyCharacterView(
                appearance: CharacterAppearanceFactory.appearance(for: DataStore.loadPlayerData().level),
                size: 160,
                idleMood: charMood
            )
            .id(DataStore.loadSelectedBodyColor() + DataStore.loadSelectedDetailType())
            .scaleEffect(charTapped ? 1.3 : 1.0)
            .onTapGesture {
                handleCharTap()
            }
            #if DEBUG
            .offset(x: w * charOffsetXR, y: h * charOffsetYR)
            #else
            .offset(x: 0, y: -h * 0.37)
            #endif
        }
        .frame(width: w, height: h)
    }

    @ViewBuilder
    private func menuItem(icon: String, iconColor: Color, label: String, locked: Bool = false, action: @escaping () -> Void) -> some View {
        MenuItemButton(icon: icon, iconColor: iconColor, label: label, locked: locked, action: action)
    }

    @ViewBuilder
    private func subIcon(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }

    // 旧球体レイヤー（mainMenuLayerに置き換え済み、コード参照用に残す）
    @ViewBuilder
    private func sphereItemsLayer_legacy(w: CGFloat, h: CGFloat) -> some View {
        let size = CGSize(width: w, height: h)
        ForEach(items) { item in
            let basePos = spherePosition(for: item.angle, in: size)
            let sc = sphereScale(for: item.angle)
            let op = sphereOpacity(for: item.angle)
            let pos = CGPoint(x: basePos.x + item.jitterX * sc, y: basePos.y + item.jitterY * sc)
            let isEntering = enteringShopId == item.id

            IslandItemView(item: item, currentScale: sc) { handleItemTap(item, at: pos, screenSize: size) }
                .scaleEffect(isEntering ? shopEnterScale : sc)
                .offset(isEntering ? shopEnterOffset : .zero)
                .rotationEffect(.degrees(isEntering ? shopShakeAngle : 0))
                .position(pos)
                .zIndex(isEntering ? 200 : Double(sc) * 100)
                .opacity(isEntering ? 1.0 : op * otherItemsOpacity)
                .allowsHitTesting(!isEnteringShop && sc > 0.35)
        }
    }

    private func handleItemTap(_ item: IslandItem, at position: CGPoint, screenSize: CGSize) {
        guard !isEnteringShop else { return }

        if item.isLocked {
            showLockedMessage()
            return
        }

        HapticsManager.tap()
        SoundManager.shared.playTap()
        AnalyticsManager.logTapShop(shopId: item.id)
        enterShop(item.id, itemPosition: position, screenSize: screenSize)
    }

    /// お店入店演出
    private func enterShop(_ shopId: String, itemPosition: CGPoint, screenSize: CGSize) {
        isEnteringShop = true
        enteringShopId = shopId

        // Phase 1: ぷるぷる（0〜0.15秒）
        withAnimation(.easeInOut(duration: 0.07).repeatCount(4, autoreverses: true)) {
            shopShakeAngle = 3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            shopShakeAngle = 0
        }

        // Phase 1: ズームイン + 他フェード（0〜0.45秒）
        let targetX = screenSize.width / 2 - itemPosition.x
        let targetY = screenSize.height * 0.45 - itemPosition.y
        withAnimation(.easeIn(duration: 0.45)) {
            shopEnterScale = 2.8
            shopEnterOffset = CGSize(width: targetX, height: targetY)
            otherItemsOpacity = 0
        }

        // Phase 2: フラッシュ（0.4〜0.6秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.2)) {
                shopFlashOpacity = 1.0
            }
        }

        // Phase 3: 画面遷移（0.65秒〜）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            switch shopId {
            case "battle":
                if DataStore.loadAgeGroup() == .young4 {
                    gameVM.startGame(difficulty: .easy)
                } else if DataStore.loadAgeGroup() == .young {
                    gameVM.startGame(difficulty: .easy)
                } else {
                    showBattleShop = true
                }
            case "family":
                gameVM.showVersus = true
            case "bgm":
                showBGMSheet = true
            case "kisekae":
                showKisekaeShop = true
            case "koukan":
                showKoukanShop = true
            case "tree":
                // 木を植えるボタン: 在庫があれば植樹モードへ、なければ案内
                let stock = DataStore.loadTreeShopStock()
                let inventory = DataStore.loadCoins()
                if stock > 0 || inventory >= TreeConfig.costPerTree {
                    showKoukanShop = true   // 購入画面へ誘導
                } else {
                    plantingMode = true
                }
            default:
                break
            }
            // リセット
            resetShopEnterState()
        }
    }

    // MARK: - 新規解放チェック + ヒカキン演出

    private static let unlockShownKey = "kazumon_shop_unlock_shown"

    private func checkNewUnlocks(level: Int) {
        let shownSet = Set(UserDefaults.standard.stringArray(forKey: Self.unlockShownKey) ?? [])

        // 解放条件: koukan=Lv3, kisekae=Lv5
        let unlocks: [(id: String, minLevel: Int, msgKey: String)] = [
            ("koukan",  3, "island_unlock_koukan"),
            ("kisekae", 5, "island_unlock_kisekae"),
        ]

        for unlock in unlocks {
            if level >= unlock.minLevel && !shownSet.contains(unlock.id) {
                // 初回解放 → 演出
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    playUnlockAnimation(shopId: unlock.id, messageKey: unlock.msgKey)
                }
                var newShown = shownSet
                newShown.insert(unlock.id)
                UserDefaults.standard.set(Array(newShown), forKey: Self.unlockShownKey)
                break  // 1つずつ演出
            }
        }
    }

    private func playUnlockAnimation(shopId: String, messageKey: String) {
        // そのお店にスナップ
        guard let idx = items.firstIndex(where: { $0.id == shopId }) else { return }
        let targetAngle = normalizeAngle(items[idx].angle)
        let diff = -targetAngle

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            for i in items.indices {
                items[i].angle += diff
                if items[i].angle > 180 { items[i].angle -= 360 }
                if items[i].angle < -180 { items[i].angle += 360 }
            }
        }

        // 白フラッシュ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SoundManager.shared.playBossAppear()
            HapticsManager.tap()
            withAnimation(.easeIn(duration: 0.15)) { showUnlockFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.3)) { showUnlockFlash = false }
            }
        }

        // メッセージ表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            unlockMessage = NSLocalizedString(messageKey, comment: "")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                showUnlockMessage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) { showUnlockMessage = false }
            }
        }
    }

    private func resetShopEnterState() {
        shopEnterScale = 1.0
        shopEnterOffset = .zero
        shopFlashOpacity = 0
        otherItemsOpacity = 1.0
        shopShakeAngle = 0
        isEnteringShop = false
        enteringShopId = nil
    }

    // MARK: - 装飾（木・火山）

    @ViewBuilder
    private func decorationsLayer(w: CGFloat, h: CGFloat) -> some View {
        let islandCenterY = h * 0.5 + h * islandYRatio
        let islandH = h * islandHRatio

        // 木（3本、ランダム配置）
        Image("island_tree")
            .resizable().scaledToFit()
            .frame(height: 55)
            .position(x: w * 0.15, y: islandCenterY - islandH * 0.12)

        Image("island_tree")
            .resizable().scaledToFit()
            .frame(height: 40)
            .position(x: w * 0.82, y: islandCenterY - islandH * 0.05)

        Image("island_tree")
            .resizable().scaledToFit()
            .frame(height: 48)
            .position(x: w * 0.35, y: islandCenterY + islandH * 0.08)

        // 山本体（画像、火山.png）
        Image("island_mountain")
            .resizable().scaledToFit()
            .frame(height: 75)
            .scaleEffect(x: volcanoScale, y: volcanoScale * volcanoStretch, anchor: .bottom)
            .position(x: w * 0.82, y: islandCenterY - islandH * 0.35 + 12)

        // 火口の赤い光（山頂から漏れる）
        Circle()
            .fill(
                RadialGradient(colors: [
                    Color.orange.opacity(0.9),
                    Color.red.opacity(0.5),
                    Color.red.opacity(0)
                ], center: .center, startRadius: 2, endRadius: 18)
            )
            .frame(width: 30, height: 18)
            .position(x: w * 0.82, y: islandCenterY - islandH * 0.35 - 5)
            .blendMode(.plusLighter)

        // 火山の赤い光の波紋（脈動して広がる）
        Circle()
            .fill(
                RadialGradient(colors: [
                    Color.red.opacity(0.5),
                    Color.orange.opacity(0.2),
                    Color.red.opacity(0)
                ], center: .center, startRadius: 5, endRadius: 50)
            )
            .frame(width: 90, height: 60)
            .scaleEffect(volcanoGlowScale)
            .opacity(volcanoGlowOpacity)
            .blendMode(.plusLighter)
            .position(x: w * 0.82, y: islandCenterY - islandH * 0.35)

        // 雲（噴煙、上に上がっていく・ふくらむ・フェードアウト）
        Image("island_volcano")
            .resizable().scaledToFit()
            .frame(height: 60)
            .colorMultiply(
                Color(
                    red: 1.0 + volcanoTint * 0.1,
                    green: 1.0 - volcanoTint * 0.30,
                    blue: 1.0 - volcanoTint * 0.30
                )
            )
            .scaleEffect(smokeCloudScale, anchor: .bottom)
            .opacity(smokeCloudOpacity)
            .position(x: w * 0.82, y: islandCenterY - islandH * 0.35 - 25 + smokeCloudY)

        // 噴煙パフ (3個、位相ずらしで連続的に上がっていく)
        ForEach(0..<3, id: \.self) { i in
            let phase = [puff1Phase, puff2Phase, puff3Phase][i]
            VolcanoPuff(phase: phase)
                .position(x: w * 0.82 + CGFloat([0, -8, 6][i]),
                          y: islandCenterY - islandH * 0.35 - 30)
        }
            .opacity(0.85)
    }

    // MARK: - 背景

    @ViewBuilder
    private func islandBackground(w: CGFloat, h: CGFloat) -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.53, green: 0.81, blue: 0.98),
                Color(red: 0.40, green: 0.70, blue: 0.95),
                Color(red: 0.68, green: 0.88, blue: 1.0)
            ],
            startPoint: .top, endPoint: .center
        ).ignoresSafeArea()
    }

    // MARK: - 雲

    @ViewBuilder
    private func cloudsLayer(w: CGFloat, h: CGFloat) -> some View {
        // 雲は削除（火山の噴煙 + ショップの光のみ）
        EmptyView()
    }

    // MARK: - 散歩スライム

    @ViewBuilder
    private func wanderSlimeLayer(w: CGFloat, h: CGFloat) -> some View {
        let islandCenterY = h * 0.5 + h * islandYRatio
        let islandH = h * islandHRatio
        let charSize: CGFloat = 85
        let slimeSize = charSize / 4
        ForEach(wanderSlimes) { slime in
            SlimeView(
                color: slime.color,
                size: slimeSize,
                isSurprised: slime.isFighting,  // 喧嘩中は驚き顔
                externalHitTrigger: slime.hitTriggerCount,
                tapEnabled: false
            )
            .scaleEffect(slime.disappearScale, anchor: .bottom)
            .opacity(slime.disappearOpacity)
            .offset(x: slime.shakeOffset + slime.fightShake, y: slime.jumpY)
            .position(x: w * 0.5 + slime.x * w * islandWRatio,
                      y: islandCenterY + slime.y * islandH)
            .allowsHitTesting(slime.visible)
            .onTapGesture {
                handleSlimeTap(id: slime.id)
            }
        }
    }

    /// 木の本数に応じたスライムの最大数
    private var slimeMaxCount: Int {
        let bonus = plantedTrees.count / TreeConfig.slimePerTrees
        return min(TreeConfig.maxSlimeCount, TreeConfig.baseSlimeCount + bonus)
    }

    private func startWanderingSlimes() {
        let max = slimeMaxCount
        let count = Int.random(in: 1...max)
        wanderSlimes = (0..<count).map { _ in newRandomSlime() }
        for slime in wanderSlimes {
            scheduleSlimeJump(id: slime.id)
        }
        // 喧嘩判定タイマー (1秒ごとに重なりチェック)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkSlimeOverlaps()
        }
    }

    /// スライムが近すぎる場合に喧嘩トリガー
    private func checkSlimeOverlaps() {
        guard wanderSlimes.count >= 2 else { return }
        for i in 0..<wanderSlimes.count {
            for j in (i+1)..<wanderSlimes.count {
                guard wanderSlimes[i].visible, wanderSlimes[j].visible else { continue }
                guard !wanderSlimes[i].isFighting, !wanderSlimes[j].isFighting else { continue }
                let dx = wanderSlimes[i].x - wanderSlimes[j].x
                let dy = wanderSlimes[i].y - wanderSlimes[j].y
                let dist = hypot(dx, dy)
                if dist < 0.10 {  // 近すぎ → 喧嘩
                    triggerFight(idA: wanderSlimes[i].id, idB: wanderSlimes[j].id)
                    return  // 1組ずつ
                }
            }
        }
    }

    /// 2匹のスライムを喧嘩させる
    private func triggerFight(idA: UUID, idB: UUID) {
        guard let iA = wanderSlimes.firstIndex(where: { $0.id == idA }),
              let iB = wanderSlimes.firstIndex(where: { $0.id == idB }) else { return }
        wanderSlimes[iA].isFighting = true
        wanderSlimes[iB].isFighting = true
        SoundManager.shared.play("sfx_tap1", volume: 0.4)
        // ぶつかりシェイクを6回
        for k in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * 0.06) {
                guard let i = wanderSlimes.firstIndex(where: { $0.id == idA }),
                      let j = wanderSlimes.firstIndex(where: { $0.id == idB }) else { return }
                let amp: CGFloat = (k % 2 == 0) ? 6 : -6
                withAnimation(.linear(duration: 0.06)) {
                    wanderSlimes[i].fightShake = amp
                    wanderSlimes[j].fightShake = -amp
                }
            }
        }
        // 喧嘩終了 → お互い反対方向に逃げる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard let iA2 = wanderSlimes.firstIndex(where: { $0.id == idA }),
                  let iB2 = wanderSlimes.firstIndex(where: { $0.id == idB }) else { return }
            wanderSlimes[iA2].fightShake = 0
            wanderSlimes[iB2].fightShake = 0
            // 反対方向にちょっと逃げる
            let dxA = wanderSlimes[iA2].x - wanderSlimes[iB2].x
            let dyA = wanderSlimes[iA2].y - wanderSlimes[iB2].y
            let len = max(0.01, hypot(dxA, dyA))
            withAnimation(.easeOut(duration: 0.5)) {
                wanderSlimes[iA2].x = max(-0.45, min(0.45, wanderSlimes[iA2].x + dxA / len * 0.15))
                wanderSlimes[iA2].y = max(-0.45, min(0.45, wanderSlimes[iA2].y + dyA / len * 0.15))
                wanderSlimes[iB2].x = max(-0.45, min(0.45, wanderSlimes[iB2].x - dxA / len * 0.15))
                wanderSlimes[iB2].y = max(-0.45, min(0.45, wanderSlimes[iB2].y - dyA / len * 0.15))
            }
            // 1秒後に喧嘩フラグ解除
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let i = wanderSlimes.firstIndex(where: { $0.id == idA }) {
                    wanderSlimes[i].isFighting = false
                }
                if let j = wanderSlimes.firstIndex(where: { $0.id == idB }) {
                    wanderSlimes[j].isFighting = false
                }
            }
        }
    }

    /// プロファイル切替時に島データをすべて再読込
    private func refreshIslandForProfile() {
        let level = DataStore.loadPlayerData().level
        items = Self.buildItems(level: level)
        plantedTrees = DataStore.loadPlantedTrees()
        chestPos = DataStore.loadTreasureChestPosition()
        chestOpened = DataStore.isTreasureChestOpenedToday()
        dailyMissionFullyComplete = DataStore.isDailyMissionFullyComplete()
        // スライムを再生成
        wanderSlimes = []
        startWanderingSlimes()
    }

    /// 島タップで木を植える
    private func handlePlantTap(at location: CGPoint, in size: CGSize) {
        let w = size.width
        let h = size.height
        let islandCenterY = h * 0.5 + h * islandYRatio
        let islandH = h * islandHRatio
        // 島ぴったりの楕円を分母に。tree.x/y は -0.5〜0.5 = 島の縁
        let halfW = w * islandWRatio / 2
        let halfH = islandH / 2
        let relX = Double((location.x - w / 2) / halfW) / 2  // ÷2 で -0.5〜0.5 範囲
        let relY = Double((location.y - islandCenterY) / halfH) / 2
        // 楕円の内側にクランプ（縁からマージン）
        let edge = 0.46
        let r = hypot(relX, relY)
        let clampedX: Double
        let clampedY: Double
        if r > edge {
            clampedX = relX / r * edge
            clampedY = relY / r * edge
        } else {
            clampedX = relX
            clampedY = relY
        }

        // ショップ・キャラ・他の木の上には植えられない
        if isInShopTapArea(x: CGFloat(clampedX), y: CGFloat(clampedY))
            || isNearPlantedTree(x: clampedX, y: clampedY) {
            // 不正解音 + バイブ + メッセージ表示
            SoundManager.shared.play("sfx_wrong", volume: 0.5)
            HapticsManager.incorrect()
            showPlantBlockedMessage()
            return  // 植えない、モードは継続
        }

        if DataStore.plantTree(at: clampedX, y: clampedY) {
            plantedTrees = DataStore.loadPlantedTrees()
            HapticsManager.tap()
            SoundManager.shared.play("Pickup", volume: 0.5)
            spawnPlantPopup(at: clampedX, y: clampedY)
            plantingMode = false
        }
    }

    /// 既存の木の近くか（重なり防止: 木のサイズに合わせて距離を確保）
    private func isNearPlantedTree(x: Double, y: Double) -> Bool {
        plantedTrees.contains { hypot($0.x - x, $0.y - y) < 0.12 }
    }

    /// プレビューの位置と判定を更新（指の動きに追従）
    private func updatePlantPreview(at location: CGPoint, in size: CGSize) {
        plantPreviewPos = location
        let w = size.width
        let h = size.height
        let islandCenterY = h * 0.5 + h * islandYRatio
        let islandH = h * islandHRatio
        // 島ぴったりの楕円
        let halfW = w * islandWRatio / 2
        let halfH = islandH / 2
        let relX = Double((location.x - w / 2) / halfW) / 2
        let relY = Double((location.y - islandCenterY) / halfH) / 2
        // 楕円内（マージン込み）か判定
        let edge = 0.46
        let r = hypot(relX, relY)
        let inIsland = r <= edge
        let cx = inIsland ? relX : relX / r * edge
        let cy = inIsland ? relY : relY / r * edge
        plantPreviewValid = inIsland
            && !isInShopTapArea(x: CGFloat(cx), y: CGFloat(cy))
            && !isNearPlantedTree(x: cx, y: cy)
    }

    /// 「ここには植えられない!」エラー表示用フラグ
    @State private var showPlantBlocked: Bool = false
    private func showPlantBlockedMessage() {
        showPlantBlocked = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showPlantBlocked = false
        }
    }

    /// 植樹時のポップアップ「+ スライム」を表示
    private func spawnPlantPopup(at x: Double, y: Double) {
        let popup = PlantPopup(
            x: x + 0.04,  // 少し右に
            y: y,
            color: SlimeView.randomColor()
        )
        plantPopups.append(popup)
        let id = popup.id
        // 1秒で上に流れてフェードアウト
        withAnimation(.easeOut(duration: 1.0)) {
            if let i = plantPopups.firstIndex(where: { $0.id == id }) {
                plantPopups[i].floatY = -50
                plantPopups[i].opacity = 0
            }
        }
        // 1.1秒後に削除
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            plantPopups.removeAll { $0.id == id }
        }
    }

    /// コイン+1 ポップアップ生成
    private func spawnCoinPopup(at x: Double, y: Double) {
        let popup = CoinPopup(x: x, y: y)
        coinPopups.append(popup)
        let id = popup.id
        withAnimation(.easeOut(duration: 0.9)) {
            if let i = coinPopups.firstIndex(where: { $0.id == id }) {
                coinPopups[i].floatY = -45
                coinPopups[i].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            coinPopups.removeAll { $0.id == id }
        }
    }

    /// コイン+1 レイヤー
    @ViewBuilder
    private func coinPopupsLayer(w: CGFloat, h: CGFloat) -> some View {
        let islandCenterY = h * 0.5 + h * islandYRatio
        let islandH = h * islandHRatio
        ForEach(coinPopups) { popup in
            HStack(spacing: 2) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                Text("+1")
                    .font(.zenMaru(14, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
            .opacity(popup.opacity)
            .offset(y: popup.floatY)
            .position(x: w * 0.5 + CGFloat(popup.x) * w * islandWRatio,
                      y: islandCenterY + CGFloat(popup.y) * islandH)
        }
    }

    /// 植樹ポップアップレイヤー
    @ViewBuilder
    private func plantPopupsLayer(w: CGFloat, h: CGFloat) -> some View {
        let islandCenterY = h * 0.5 + h * islandYRatio
        let islandH = h * islandHRatio
        ForEach(plantPopups) { popup in
            HStack(spacing: 2) {
                Text("+")
                    .font(.zenMaru(20, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                SlimeView(color: popup.color, size: 24, tapEnabled: false)
            }
            .opacity(popup.opacity)
            .offset(y: popup.floatY)
            .position(x: w * 0.5 + CGFloat(popup.x) * w * islandWRatio,
                      y: islandCenterY + CGFloat(popup.y) * islandH)
        }
    }

    /// 既存スライムから離れた位置で新しいスライムを生成（コンテンツのタップ範囲を除外）
    private func newRandomSlime() -> WanderingSlime {
        let existingPositions = wanderSlimes.map { (CGFloat($0.x), CGFloat($0.y)) }
        var bestX: CGFloat = 0, bestY: CGFloat = 0, bestDist: CGFloat = 0
        for _ in 0..<20 {
            let cx = CGFloat.random(in: -0.45...0.45)
            let cy = CGFloat.random(in: -0.45...0.45)
            // 島の楕円外は除外
            if hypot(cx, cy) > 0.46 { continue }
            // ショップ位置を避ける（くもゲート=右下、家=左上、火山=右上、こうかんじょ=右下）
            if isInShopTapArea(x: cx, y: cy) { continue }
            let minDist = existingPositions.map { hypot(cx - $0.0, cy - $0.1) }.min() ?? CGFloat.infinity
            if minDist > bestDist {
                bestDist = minDist; bestX = cx; bestY = cy
            }
        }
        return WanderingSlime(
            color: SlimeView.randomColor(),
            x: bestX,
            y: bestY
        )
    }

    /// 指定座標がショップタップ範囲内か（スライムが踏まないように）
    private func isInShopTapArea(x: CGFloat, y: CGFloat) -> Bool {
        // tree.x/y は -0.5〜0.5 = 島の縁 の正規化空間
        // 球体ボタンの実際のスクリーン位置に対応する位置と物理半径
        // 旧値を新スケールへ: X係数 = 0.35/(islandWRatio/2) ≈ 0.493, Y係数 = 0.4/0.5 = 0.8
        let shopHotspots: [(CGFloat, CGFloat, CGFloat)] = [
            (0.148, -0.04, 0.099),   // battle/くもゲート (右)
            (0.0,    0.24, 0.089),   // bgm (下)
            (-0.148, -0.04, 0.089),  // kisekae (左)
            (0.0,   -0.20, 0.089),   // koukan (上)
        ]
        return shopHotspots.contains { hx, hy, r in
            hypot(x - hx, y - hy) < r
        }
    }

    /// IDで該当スライムのインデックスを取得
    private func slimeIndex(id: UUID) -> Int? {
        wanderSlimes.firstIndex(where: { $0.id == id })
    }

    /// スライムをジャンプして次の位置に移動
    private func scheduleSlimeJump(id: UUID) {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.0...3.5), repeats: true) { timer in
            guard let i = slimeIndex(id: id), wanderSlimes[i].visible else {
                timer.invalidate(); return
            }
            let dx = CGFloat.random(in: -0.08...0.08)
            let dy = CGFloat.random(in: -0.08...0.08)
            var newX = max(-0.45, min(0.45, wanderSlimes[i].x + dx))
            var newY = max(-0.45, min(0.45, wanderSlimes[i].y + dy))
            // 楕円範囲外なら現在位置を維持
            if hypot(newX, newY) > 0.46 {
                newX = wanderSlimes[i].x
                newY = wanderSlimes[i].y
            }
            // ショップタップ範囲なら現在位置を維持
            if isInShopTapArea(x: newX, y: newY) {
                newX = wanderSlimes[i].x
                newY = wanderSlimes[i].y
            }

            withAnimation(.easeOut(duration: 0.35)) {
                wanderSlimes[i].jumpY = -22
                wanderSlimes[i].x = (wanderSlimes[i].x + newX) / 2
                wanderSlimes[i].y = (wanderSlimes[i].y + newY) / 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard let i2 = slimeIndex(id: id) else { return }
                withAnimation(.easeIn(duration: 0.35)) {
                    wanderSlimes[i2].x = newX
                    wanderSlimes[i2].y = newY
                    wanderSlimes[i2].jumpY = 0
                }
            }
        }
    }

    private func handleSlimeTap(id: UUID) {
        guard let index = slimeIndex(id: id), wanderSlimes[index].visible else { return }
        wanderSlimes[index].visible = false
        // sfx_tap1: 元の短いタップ音、音量少し下げ
        SoundManager.shared.play("sfx_tap1", volume: 0.7)
        HapticsManager.tap()
        // コイン+1 報酬
        DataStore.saveCoins(DataStore.loadCoins() + 1)
        spawnCoinPopup(at: Double(wanderSlimes[index].x), y: Double(wanderSlimes[index].y))
        // 1. 驚き + 震え
        wanderSlimes[index].hitTriggerCount += 1
        for k in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * 0.04) {
                guard let i = slimeIndex(id: id) else { return }
                withAnimation(.linear(duration: 0.04)) {
                    wanderSlimes[i].shakeOffset = (k % 2 == 0) ? 4 : -4
                }
            }
        }
        // 2. 高くジャンプ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let i = slimeIndex(id: id) else { return }
            wanderSlimes[i].shakeOffset = 0
            withAnimation(.easeOut(duration: 0.3)) {
                wanderSlimes[i].jumpY = -40
            }
        }
        // 3. 地面に潜る
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let i = slimeIndex(id: id) else { return }
            withAnimation(.easeIn(duration: 0.5)) {
                wanderSlimes[i].jumpY = 35
                wanderSlimes[i].disappearScale = 0.15
                wanderSlimes[i].disappearOpacity = 0
            }
        }
        // 4. 削除（配列から完全に削除）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard let i = slimeIndex(id: id) else { return }
            wanderSlimes.remove(at: i)
            // 5. ランダム確率で5秒後にリスポーン（最大3匹、別の場所・違う色）
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                guard wanderSlimes.count < 3 else { return }
                // 50% の確率でリスポーン
                if Bool.random() {
                    let newSlime = newRandomSlime()
                    wanderSlimes.append(newSlime)
                    scheduleSlimeJump(id: newSlime.id)
                }
            }
        }
    }

    private func startCloudAnimation() {
        cloud1X = -160; cloud2X = -250; cloud3X = -120
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) { cloud1X = 500 }
        withAnimation(.linear(duration: 35).repeatForever(autoreverses: false)) { cloud2X = 500 }
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { cloud3X = 500 }
        // 火山のふくらみ・縮みアニメ（呼吸感）
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            volcanoScale = 1.06
            volcanoStretch = 1.10
        }
        // 火山の色変化（赤強め ↔ 黒っぽい）
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            volcanoTint = 0.6  // 0=通常 → 0.6で赤+暗くなる
        }
        // 火山の赤い光の波紋（脈動して広がる）
        volcanoGlowScale = 0.4
        volcanoGlowOpacity = 0.7
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            volcanoGlowScale = 1.6
            volcanoGlowOpacity = 0
        }
        // 噴煙の雲が上がっていく（小さく出てふくらんで上昇、フェード）
        smokeCloudY = 0; smokeCloudOpacity = 1.0; smokeCloudScale = 0.5
        withAnimation(.easeOut(duration: 4.0).repeatForever(autoreverses: false)) {
            smokeCloudY = -60        // 上に60pt上昇
            smokeCloudOpacity = 0    // フェードアウト
            smokeCloudScale = 1.4    // 上がりながらふくらむ
        }
        // 噴煙パフ（連続的に上がっていく）
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            puff1Phase = 1.0
            puff2Phase = 1.33
            puff3Phase = 1.66
        }
    }

    // MARK: - 島の地面

    @ViewBuilder
    private func islandGround(w: CGFloat, h: CGFloat) -> some View {
        // 木の数で色を変化（少ないほどくすむ、多いほど豊か）
        let treeCount = plantedTrees.count
        let lushness = min(1.0, Double(treeCount) / 50.0)  // 50本で最大
        // くすんだ茶緑(0本) → 鮮やかな緑(50本+)
        let r1 = 0.55 - 0.10 * lushness  // 0.55→0.45
        let g1 = 0.55 + 0.23 * lushness  // 0.55→0.78
        let b1 = 0.40 - 0.04 * lushness  // 0.40→0.36
        let r2 = 0.45 - 0.10 * lushness
        let g2 = 0.45 + 0.20 * lushness
        let b2 = 0.32 - 0.04 * lushness
        let r3 = 0.38 - 0.10 * lushness
        let g3 = 0.38 + 0.17 * lushness
        let b3 = 0.28 - 0.06 * lushness
        return Ellipse()
            .fill(RadialGradient(
                colors: [
                    Color(red: r1, green: g1, blue: b1),
                    Color(red: r2, green: g2, blue: b2),
                    Color(red: r3, green: g3, blue: b3)
                ],
                center: .center, startRadius: 10, endRadius: w * 0.55
            ))
            .frame(width: w * islandWRatio, height: h * islandHRatio)
            .offset(y: h * islandYRatio)
            .shadow(color: Color(red: 0.2, green: 0.4, blue: 0.15).opacity(0.4), radius: 20, y: 10)
    }

    // MARK: - 宝箱レイヤー

    @ViewBuilder
    private func treasureChestLayer(w: CGFloat, h: CGFloat) -> some View {
        let islandCenterY = h * 0.5 + h * islandYRatio
        let islandH = h * islandHRatio
        if chestVisible && !chestOpened {
            ZStack {
                Text("🎁")
                    .font(.system(size: 42))
                    .scaleEffect(1.0 + chestBounce * 0.1)
                    .shadow(color: .yellow.opacity(0.6), radius: 8)
                    .onTapGesture { handleChestTap() }
                if let text = chestBubbleText {
                    Text(text)
                        .font(.zenMaru(13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                        .offset(y: -40)
                }
            }
            .position(x: w * 0.5 + CGFloat(chestPos.x) * w * 0.35,
                      y: islandCenterY + CGFloat(chestPos.y) * islandH * 0.4)
            .zIndex(150)
        }
    }

    private func handleChestTap() {
        if !DataStore.canOpenTreasureChestToday() {
            // ミッション未達成: ?吹き出し
            chestBubbleText = "?"
            HapticsManager.tap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                chestBubbleText = nil
            }
            return
        }
        if DataStore.isTreasureChestOpenedToday() {
            chestBubbleText = NSLocalizedString("island_chest_already_opened", comment: "")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                chestBubbleText = nil
            }
            return
        }
        // 開封処理
        DataStore.markTreasureChestOpened()
        SoundManager.shared.playCorrect()
        HapticsManager.tap()
        let newCoins = DataStore.loadCoins() + 100
        DataStore.saveCoins(newCoins)
        chestBubbleText = NSLocalizedString("island_chest_reward", comment: "")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            chestBounce = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { chestBounce = 0 }
        }
        // 1.5秒後に宝箱を消す（開封済み）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            chestBubbleText = nil
            chestOpened = true
        }
    }

    // MARK: - 植えた木レイヤー

    @ViewBuilder
    private func plantedTreesLayer(w: CGFloat, h: CGFloat) -> some View {
        let islandCenterY = h * 0.5 + h * islandYRatio
        let islandH = h * islandHRatio
        ForEach(plantedTrees) { tree in
            // 経過日数に応じて少しサイズ変化 (新しいほど小さく)
            let ageRatio = Double(tree.daysSincePlanted) / Double(TreeConfig.lifetimeDays)
            let opacity = 1.0 - max(0, ageRatio - 0.7) * 2.0  // 70%以降は徐々に薄く
            Image("island_tree")
                .resizable().scaledToFit()
                .frame(height: 32 + CGFloat(min(1.0, ageRatio * 1.5)) * 12)  // 32〜44pt
                .opacity(max(0.4, opacity))
                .position(x: w * 0.5 + CGFloat(tree.x) * w * islandWRatio,
                          y: islandCenterY + CGFloat(tree.y) * islandH)
        }

        // 植樹モード時の案内吹き出し（画面上部、ボタン群より上）
        if plantingMode {
            VStack {
                Spacer().frame(height: 110)  // 上部ボタン+デイリーバナー分の余白
                if showPlantBlocked {
                    Text(NSLocalizedString("island_plant_blocked", comment: ""))
                        .font(.zenMaru(14, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.red))
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text(NSLocalizedString("island_plant_prompt", comment: ""))
                        .font(.zenMaru(14, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.green))
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                }
                Spacer()
            }
            .zIndex(310)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showPlantBlocked)
            .allowsHitTesting(false)
        }
    }

    // MARK: - 海

    @ViewBuilder
    private func seaLayer(w: CGFloat, h: CGFloat) -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.25, green: 0.60, blue: 0.85).opacity(0.0),
                Color(red: 0.25, green: 0.60, blue: 0.85).opacity(0.6),
                Color(red: 0.20, green: 0.50, blue: 0.78)
            ],
            startPoint: .top, endPoint: .bottom
        )
        .frame(height: h * 0.18).offset(y: h * 0.42)
    }

    // MARK: - キャラ（左寄せ）

    /// デイリーミッション進捗バッジ
    @ViewBuilder
    private func dailyMissionBadge() -> some View {
        let mission = DataStore.loadDailyMission()
        let count = mission.playCount
        let target = DailyMission.requiredPlays
        let progress = min(1.0, Double(count) / Double(target))
        let isComplete = count >= target

        if isComplete {
            HStack(spacing: 6) {
                Text("✨")
                Text(NSLocalizedString("island_daily_clear", comment: ""))
                    .font(.zenMaru(12, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(LinearGradient(
                colors: [Color.orange, Color.pink],
                startPoint: .leading, endPoint: .trailing
            ))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        } else {
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Text("📅")
                    Text(String(format: NSLocalizedString("island_mission_progress", comment: ""), count, target))
                        .font(.zenMaru(11, weight: .black))
                        .foregroundColor(.white)
                }
                // プログレスバー
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                        Capsule()
                            .fill(LinearGradient(colors: [Color.yellow, Color.orange],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(width: 90, height: 5)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.5)))
            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
        }
    }

    @ViewBuilder
    private func streakBadge() -> some View {
        let player = DataStore.loadPlayerData()
        let streak = player.streakDays
        if streak > 0 {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text(String(format: NSLocalizedString("view_title_streak_days", comment: ""), streak))
                        .font(.zenMaru(11, weight: .black))
                        .foregroundColor(.white)
                }
                if player.bestStreak > streak {
                    Text(String(format: NSLocalizedString("island_best_streak", comment: ""), player.bestStreak))
                        .font(.zenMaru(8, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(
                LinearGradient(colors: [Color.orange, Color.red.opacity(0.8)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
        }
    }

    @ViewBuilder
    private func playsRemainingBadge() -> some View {
        let remaining = PurchaseManager.shared.remainingPlays
        if !PurchaseManager.shared.isPro && remaining < Int.max {
            HStack(spacing: 4) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                Text(String(format: NSLocalizedString("island_plays_remaining", comment: ""), remaining))
                    .font(.zenMaru(11, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(remaining > 0 ? Color.blue.opacity(0.7) : Color.red.opacity(0.7)))
            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
        }
    }

    private var young4BattleChoiceSheet: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("young4_battle_choice_title", comment: ""))
                .font(.zenMaru(20, weight: .black))
                .padding(.top, 20)

            Button {
                showYoung4BattleChoice = false
                gameVM.startGame(difficulty: .easy)
            } label: {
                Text(NSLocalizedString("young4_battle_play", comment: ""))
                    .font(.zenMaru(18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Color(red: 0.30, green: 0.72, blue: 0.49))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button {
                showYoung4BattleChoice = false
                gameVM.showVersus = true
            } label: {
                Text(NSLocalizedString("young4_battle_family", comment: ""))
                    .font(.zenMaru(18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Color(red: 0.48, green: 0.44, blue: 0.86))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func bpRankBadge() -> some View {
        let bp = DataStore.loadVersusBP()
        if bp > 0 {
            let rank = VersusConfig.rank(for: bp)
            HStack(spacing: 4) {
                Text(rank.rawValue)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                Text("\(bp)BP")
                    .font(.zenMaru(9, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color.indigo.opacity(0.7)))
        }
    }

    @ViewBuilder
    private func weeklyChallengeLabel() -> some View {
        let days = DataStore.loadWeeklyPlayDays()
        let goal = DataStore.weeklyGoalDays
        let complete = days >= goal
        HStack(spacing: 4) {
            Text("📆")
            Text(complete
                 ? NSLocalizedString("island_weekly_complete", comment: "")
                 : String(format: NSLocalizedString("island_weekly_progress", comment: ""), days, goal))
                .font(.zenMaru(9, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(complete ? Color.green.opacity(0.7) : Color.purple.opacity(0.6)))
    }

    private var charMood: KennyCharacterView.IdleMood {
        if charSleeping { return .sleepy }
        // body_blueB（Lv1-4の標準ボディ）はデフォルトでテレ顔
        if titleMood == .normal && gameVM.playerAppearance.body == "body_blueB" {
            return .blush
        }
        return titleMood
    }

    /// 吹き出しに表示するテキスト（優先順位: 目サイズ > ショップ > タップ）
    private var bubbleDisplayText: String {
        if showEyeBubble { return NSLocalizedString("title_bubble_eyes", comment: "") }
        if showShopBubble { return shopBubbleText }
        return titleBubbleText
    }

    /// 吹き出しが表示中か
    private var isBubbleVisible: Bool {
        showEyeBubble || showShopBubble || showTitleBubble
    }

    // 吹き出しの位置（キャラの頭からの相対位置、pt単位）
    // X: 正=右、負=左 / Y: 正=下、負=上
    private let bubbleOffsetFromHead: CGSize = CGSize(width: 95, height: -25)

    @ViewBuilder
    private func characterLayer(w: CGFloat, h: CGFloat) -> some View {
        let charSize: CGFloat = 85
        // キャラ全体の高さは size + legSize*0.8 = 約 size * 1.2
        // 頭の位置は概ね上から y = -(size * 0.6) あたり
        let headTopY: CGFloat = -charSize * 0.6

        ZStack {
            // キャラクター（中心）
            // body別moodをベースにtitleEyeScaleだけ上書き
            let baseMood = CharacterPartOffsets.forBody(gameVM.playerAppearance.body).mood
            var titleMoodOverride = baseMood
            let _ = {
                titleMoodOverride.leftEyeScale = titleLeftEye
                titleMoodOverride.rightEyeScale = titleRightEye
            }()
            KennyCharacterView(
                appearance: gameVM.playerAppearance,
                size: charSize,
                idleMood: charMood,
                debugMoodOffsets: titleMoodOverride
            )
            .id(DataStore.loadSelectedBodyColor() + DataStore.loadSelectedDetailType())
            .allowsHitTesting(false)
            .scaleEffect(charTapped ? 1.3 : 1.0)
            .rotationEffect(.degrees(charSleeping ? -5 : 0))
            .contentShape(Rectangle())
            .onTapGesture { handleCharTap() }

            // 吹き出し（キャラの頭の位置からの相対オフセット）
            Text(bubbleDisplayText)
                .font(.zenMaru(13, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2))
                .offset(
                    x: bubbleOffsetFromHead.width,
                    y: headTopY + bubbleOffsetFromHead.height
                )
                .opacity(isBubbleVisible ? 1 : 0)
        }
        // 画面左25%に固定配置
        .position(x: w * 0.25 + charOffsetX, y: h * 0.52)
    }

    private func startCharacterAutonomous() {
        charTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
            // スリープ中は移動しない
            guard !charSleeping else { return }
            let dx = CGFloat.random(in: -20...20)
            let newX = max(-20, min(20, charOffsetX + dx))
            // スプリング物理でスムーズにスライド（2秒程度かけて移動）
            withAnimation(.interpolatingSpring(mass: 1, stiffness: 20, damping: 10)) {
                charOffsetX = newX
            }
        }
    }

    // MARK: - キャラタップ表情

    private func handleCharTap() {
        HapticsManager.tap()
        SoundManager.shared.playTap()
        charTapped = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { charTapped = false }
        randomizeEyeSize()
        titleTapCount += 1
        if titleMood == .sleepy || charSleeping {
            charSleeping = false; titleMood = .normal; titleTapCount = 0
            titleLeftEye = 1.0; titleRightEye = 1.0
            resetTitleIdleTimer(); return
        }
        showRandomBubble()
        if titleTapCount >= 3 {
            titleMood = .squint
            SoundManager.shared.playIncorrect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { titleMood = .normal; titleTapCount = 0 }
        } else {
            titleMood = .blush
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { if titleMood == .blush { titleMood = .normal } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { if titleMood != .squint { titleTapCount = 0 } }
        resetTitleIdleTimer()
    }

    private func randomizeEyeSize() {
        let mn: CGFloat = 0.5, mx: CGFloat = 1.131
        let avgSmall: CGFloat = 0.832, avgBig: CGFloat = 1.087
        let special = Int.random(in: 1...10)
        if special == 1 { titleLeftEye = mx; titleRightEye = mx; titleEyeWasBig = true; return }
        if special == 2 {
            titleLeftEye = mn; titleRightEye = mn; titleEyeWasBig = false
            showEyeBubble = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showEyeBubble = false }; return
        }
        let (b1, b2): (CGFloat, CGFloat)
        if titleEyeWasBig {
            b1 = avgSmall + .random(in: -0.15...0.05); b2 = avgBig + .random(in: -0.05...0.04)
        } else {
            b1 = avgBig + .random(in: -0.05...0.04); b2 = avgSmall + .random(in: -0.15...0.05)
        }
        if Bool.random() {
            titleLeftEye = Swift.min(Swift.max(b1, mn), mx); titleRightEye = Swift.min(Swift.max(b2, mn), mx)
        } else {
            titleLeftEye = Swift.min(Swift.max(b2, mn), mx); titleRightEye = Swift.min(Swift.max(b1, mn), mx)
        }
        titleEyeWasBig.toggle()
    }

    private func resetTitleIdleTimer() {
        titleIdleTimer?.invalidate()
        titleIdleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
            Task { @MainActor in titleMood = .sleepy; charSleeping = true }
        }
    }
    private func startTitleIdleTimer() { titleMood = .normal; titleTapCount = 0; resetTitleIdleTimer() }
    private func showRandomBubble() {
        // ショップ吹き出しをキャンセル
        showShopBubble = false
        let keys = (1...9).map { "title_bubble_\($0)" }
        titleBubbleText = keys.map { NSLocalizedString($0, comment: "") }.randomElement()!
        showTitleBubble = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showTitleBubble = false }
    }

    // MARK: - 未開放吹き出し

    @ViewBuilder
    private var lockedBubbleView: some View {
        Text(lockedBubbleText)
            .font(.zenMaru(14, weight: .bold)).foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.7)))
            .opacity(showLockedBubble ? 1 : 0)
            .scaleEffect(showLockedBubble ? 1 : 0.6)
            .offset(y: -40)
    }

    // MARK: - UIオーバーレイ

    @ViewBuilder
    private func uiOverlayLayer(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            // ホーム画面ではタイトルロゴは控えめに（小さなブランド表示）
            Text(NSLocalizedString("start_screen_title", comment: "")).font(.zenMaru(18, weight: .black)).foregroundColor(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1).padding(.top, 12)

            HStack(alignment: .top) {
                if let profile = DataStore.activeProfile() {
                    Button { HapticsManager.tap(); showProfileSwitcher = true } label: { profileCard(profile: profile) }.buttonStyle(.plain)
                }
                Spacer()
                // 家族ランキング閲覧ボタン（家族構成セットアップ済みの場合のみ表示）
                if DataStore.isFamilySetupDone() {
                    Button {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        gameVM.familyScoreUpdated = false
                        gameVM.showFamilyRanking = true
                    } label: {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.yellow)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                            .contentShape(Rectangle())
                    }
                }
                Button { HapticsManager.tap(); SoundManager.shared.playTap(); showSettings = true } label: {
                    Image(systemName: "gearshape.fill").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 44, height: 44).background(Circle().fill(Color.black.opacity(0.3))).contentShape(Rectangle())
                }
            }.padding(.horizontal, 20).padding(.top, 8)

            // ストリーク + プレイ残数 + デイリーミッション
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    streakBadge()
                    playsRemainingBadge()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    dailyMissionBadge()
                    weeklyChallengeLabel()
                    bpRankBadge()
                }
            }
            .padding(.horizontal, 20).padding(.top, 12)
            .allowsHitTesting(false)

            Spacer()

            #if DEBUG
            if showSphereDebug {
                VStack(spacing: 4) {
                    HStack {
                        Text("球体デバッグ").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        Button("コピー") {
                            print("📋 [Sphere] centerY=\(String(format:"%.2f", dbgCenterYRatio)) yR=\(String(format:"%.2f", dbgYRadius)) xR=\(String(format:"%.2f", dbgXRadius)) xC=\(String(format:"%.2f", dbgXCurve)) sMin=\(String(format:"%.2f", dbgScaleMin)) sPow=\(String(format:"%.1f", dbgScalePow)) 島Y=\(String(format:"%.2f", dbgIslandY)) 島W=\(String(format:"%.2f", dbgIslandW)) 島H=\(String(format:"%.2f", dbgIslandH))")
                        }.font(.system(size: 10)).foregroundColor(.yellow)
                        Button("✕") { showSphereDebug = false }.foregroundColor(.white)
                    }
                    sliderRow("中心Y", $dbgCenterYRatio, 0.4...0.85)
                    sliderRow("Y半径", $dbgYRadius, 0.1...0.5)
                    sliderRow("X半径", $dbgXRadius, 0.0...0.4)
                    sliderRow("X曲率", $dbgXCurve, 0.0...1.0)
                    sliderRow("S最小", $dbgScaleMin, 0.05...0.5)
                    sliderRow("Sカーブ", $dbgScalePow, 0.5...4.0)
                    Divider().background(Color.gray)
                    sliderRow("島Y", $dbgIslandY, 0.0...0.5)
                    sliderRow("島W", $dbgIslandW, 0.5...2.0)
                    sliderRow("島H", $dbgIslandH, 0.2...1.0)
                }
                .padding(10).background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.75)))
                .padding(.horizontal, 16)
            }
            HStack {
                Button("D") { showDebugPanel = true }.font(.zenMaru(12, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    .frame(width: 44, height: 44).contentShape(Rectangle())
                Spacer()
                Button(showMenuDebug ? "📐ON" : "📐") { showMenuDebug.toggle() }
                    .font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }.padding(.horizontal, 16).padding(.bottom, 16)

            if showMenuDebug {
                VStack(spacing: 4) {
                    Text("メニュー位置").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                    HStack {
                        Text("メニューX").font(.system(size: 10)).foregroundColor(.white)
                        Slider(value: $menuOffsetX, in: -1.0...0.1).tint(.purple)
                        Text("\(menuOffsetX, specifier: "%.2f")").font(.system(size: 10, design: .monospaced)).foregroundColor(.white).frame(width: 40)
                    }
                    HStack {
                        Text("メニューY").font(.system(size: 10)).foregroundColor(.white)
                        Slider(value: $menuOffsetY, in: 0.1...0.5).tint(.purple)
                        Text("\(menuOffsetY, specifier: "%.2f")").font(.system(size: 10, design: .monospaced)).foregroundColor(.white).frame(width: 40)
                    }
                    HStack {
                        Text("キャラX").font(.system(size: 10)).foregroundColor(.white)
                        Slider(value: $charOffsetXR, in: -0.2...0.3).tint(.cyan)
                        Text("\(charOffsetXR, specifier: "%.2f")").font(.system(size: 10, design: .monospaced)).foregroundColor(.white).frame(width: 40)
                    }
                    HStack {
                        Text("キャラY").font(.system(size: 10)).foregroundColor(.white)
                        Slider(value: $charOffsetYR, in: -1.0...0.1).tint(.cyan)
                        Text("\(charOffsetYR, specifier: "%.2f")").font(.system(size: 10, design: .monospaced)).foregroundColor(.white).frame(width: 40)
                    }
                }
                .padding(10)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
            }
            #endif
        }
        .frame(width: w, height: h).position(x: w / 2, y: h / 2).zIndex(100)
    }

    #if DEBUG
    @ViewBuilder
    private func sliderRow(_ label: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        HStack(spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.gray).frame(width: 44, alignment: .trailing)
            Slider(value: value, in: range).tint(.cyan)
            Text(String(format: "%.2f", value.wrappedValue)).font(.system(size: 10, design: .monospaced)).foregroundColor(.white).frame(width: 36)
        }.frame(height: 24)
    }
    #endif

    private func profileCard(profile: PlayerProfile) -> some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: profile.avatarColor)).frame(width: 32, height: 32)
                .overlay(Text(String(profile.name.prefix(1))).font(.zenMaru(14, weight: .black)).foregroundColor(.white))
                .scaleEffect(profileIconBounce == 0 ? 1.0 : 1.05)
            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name).font(.zenMaru(12, weight: .bold)).foregroundColor(.white).lineLimit(1)
                let pd = DataStore.loadPlayerData()
                Text("Lv.\(pd.level)").font(.zenMaru(10, weight: .bold)).foregroundColor(.white.opacity(0.8))
            }
        }.padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
        .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { profileIconBounce = 1 } }
    }

    private func showLockedMessage() {
        lockedBubbleText = NSLocalizedString("island_locked_message", comment: "")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showLockedBubble = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.easeOut(duration: 0.3)) { showLockedBubble = false } }
    }
}

// MARK: - 球体アイテムビュー（画像サイズ2倍: 180x180）

private struct MenuItemButton: View {
    let icon: String
    let iconColor: Color
    let label: String
    var locked: Bool = false
    let action: () -> Void

    @State private var bounceScale: CGFloat = 1.0
    @State private var bounceY: CGFloat = 0

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                bounceScale = 1.25
                bounceY = -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    bounceScale = 1.0
                    bounceY = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                action()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(locked ? Color.gray.opacity(0.4) : iconColor)
                        .frame(width: 44, height: 44)
                        .shadow(color: iconColor.opacity(locked ? 0 : 0.4), radius: 6, y: 3)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Text(label)
                    .font(.zenMaru(18, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(bounceScale)
        .offset(y: bounceY)
        .opacity(locked ? 0.6 : 1.0)
    }
}

struct IslandItemView: View {
    let item: IslandItem
    var currentScale: CGFloat = 1.0
    let onTap: () -> Void
    @State private var floatY: CGFloat = 0
    @State private var glowScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0.7
    @State private var neonPulse: CGFloat = 1.0

    /// アイテム別のグロー色（コンテンツに合わせる）
    private var glowColor: Color {
        switch item.id {
        case "battle":  return Color(red: 1.0, green: 0.7, blue: 0.5)   // 戦闘=オレンジ
        case "tree":    return Color(red: 0.6, green: 1.0, blue: 0.5)   // 木=黄緑
        case "bgm":     return Color(red: 0.6, green: 1.0, blue: 0.8)   // BGM=ミント
        case "kisekae": return Color(red: 0.9, green: 0.6, blue: 1.0)   // 着せ替え=紫
        case "koukan":  return Color(red: 1.0, green: 0.85, blue: 0.4)  // 交換所=黄
        default:        return Color.cyan
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // 背後の脈動する光の波紋（解放済みショップのみ表示）
                    // ★ if で消すとアニメが止まるので、常時描画 + opacity で制御
                    Circle()
                        .fill(RadialGradient(colors: [
                            glowColor.opacity(0.6),
                            glowColor.opacity(0.3),
                            glowColor.opacity(0)
                        ], center: .center, startRadius: 20, endRadius: 110))
                        .frame(width: 220, height: 220)
                        .scaleEffect(glowScale)
                        .opacity(item.isLocked ? 0 : glowOpacity)  // ロック中は非表示
                        .blendMode(.plusLighter)
                    if UIImage(named: item.imageName) != nil {
                        Image(item.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                    } else {
                        Image(systemName: item.imageName)
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 180, height: 180)
                            .background(Circle().fill(Color.blue.opacity(0.7)))
                    }
                    if item.isLocked {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.45))
                            .frame(width: 180, height: 180)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        // 「Lv.X で OPEN!」サイン
                        if item.requiredLevel > 0 {
                            VStack(spacing: 2) {
                                Text("Lv.\(item.requiredLevel)で")
                                    .font(.zenMaru(11, weight: .black))
                                Text("OPEN!")
                                    .font(.zenMaru(14, weight: .black))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            .offset(y: 50)
                            .scaleEffect(neonPulse)
                        }
                    }
                    // NEW! バッジ（解放直後のみ）
                    if !item.isLocked && item.isNewlyUnlocked {
                        Text("NEW!")
                            .font(.zenMaru(13, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .clipShape(Capsule())
                            .shadow(color: .yellow.opacity(0.6), radius: 6)
                            .rotationEffect(.degrees(-15))
                            .scaleEffect(neonPulse)
                            .offset(x: 60, y: -65)
                    }
                }
                Text(item.label)
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundStyle(item.isLocked ? .white.opacity(0.6) : .white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
        .accessibilityHint(item.isLocked
            ? NSLocalizedString("accessibility_locked", comment: "")
            : NSLocalizedString("accessibility_tap_to_enter", comment: ""))
        .offset(y: floatY)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { floatY = -4 }
            // 光の波紋（脈動して広がる）
            glowScale = 0.4; glowOpacity = 0.7
            withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)) {
                glowScale = 1.4; glowOpacity = 0
            }
            // ネオンサインの脈動
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                neonPulse = 1.15
            }
        }
    }
}

// MARK: - 雲のShape

private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width; let h = rect.height
        path.addEllipse(in: CGRect(x: 0, y: h * 0.3, width: w * 0.5, height: h * 0.7))
        path.addEllipse(in: CGRect(x: w * 0.2, y: 0, width: w * 0.55, height: h))
        path.addEllipse(in: CGRect(x: w * 0.45, y: h * 0.25, width: w * 0.55, height: h * 0.75))
        return path
    }
}

// MARK: - 火山の山シェイプ（クレーター付き三角形）

private struct VolcanoMountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width; let h = rect.height
        // 左下 → 山頂(クレーターの両端) → 右下 → 戻る
        path.move(to: CGPoint(x: 0, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.05),
            control: CGPoint(x: w * 0.15, y: h * 0.6)
        )
        // クレーターの凹み
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.05),
            control: CGPoint(x: w * 0.5, y: h * 0.20)
        )
        path.addQuadCurve(
            to: CGPoint(x: w, y: h),
            control: CGPoint(x: w * 0.85, y: h * 0.6)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - 火山の噴煙パフ（phase 0〜1で、ふくらみつつ上がり、最後にフェード）

private struct VolcanoPuff: View {
    let phase: Double  // 0 = 始まり、1 = 完全に消える

    var body: some View {
        let p = phase.truncatingRemainder(dividingBy: 1)  // 0..1 でループ
        // ふくらみ: 0で小さく、徐々に大きく
        let scale = 0.3 + p * 1.2
        // 上昇: 上に動く
        let yOffset = -p * 50
        // 透明度: 後半でフェードアウト
        let opacity = p < 0.7 ? 0.85 : 0.85 * (1 - (p - 0.7) / 0.3)
        // 横揺れ
        let xWobble = sin(p * .pi * 2) * 4

        CloudShape()
            .fill(Color.white.opacity(opacity))
            .frame(width: 36, height: 24)
            .scaleEffect(scale, anchor: .bottom)
            .offset(x: xWobble, y: yOffset)
    }
}
