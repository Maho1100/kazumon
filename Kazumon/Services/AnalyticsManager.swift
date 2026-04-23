import FirebaseAnalytics

enum AnalyticsManager {

    private static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static func log(_ name: String, parameters: [String: Any]? = nil) {
        guard !isDebug else { return }
        Analytics.logEvent(name, parameters: parameters)
    }

    // MARK: - User Property 更新

    static func setUserID(_ uid: String?) {
        guard !isDebug else { return }
        Analytics.setUserID(uid)
    }

    static func setUserTier(_ tier: String) {
        guard !isDebug else { return }
        Analytics.setUserProperty(tier, forName: "user_tier")
    }

    static func setLoginType(_ type: String) {
        guard !isDebug else { return }
        Analytics.setUserProperty(type, forName: "login_type")
    }

    static func setAgeGroup(_ group: String) {
        guard !isDebug else { return }
        Analytics.setUserProperty(group, forName: "age_group")
    }

    static func updatePlayerStats(level: Int, bestFloor: Int, playCount: Int) {
        guard !isDebug else { return }
        Analytics.setUserProperty(String(level), forName: "player_level")
        Analytics.setUserProperty(String(bestFloor), forName: "best_floor")
        Analytics.setUserProperty(String(playCount), forName: "total_play_count")
    }

    // MARK: - Phase 1: 初回導線

    /// スタート画面表示
    static func logViewStartScreen() {
        log("view_start_screen", parameters: nil)
    }

    /// 島画面表示
    static func logViewIsland() {
        log("view_island", parameters: nil)
    }

    /// 島の建物タップ
    static func logTapShop(shopId: String) {
        log("tap_shop", parameters: [
            "shop_id": shopId
        ])
    }

    /// バトル店内表示
    static func logViewBattleShop() {
        log("view_battle_shop", parameters: nil)
    }

    // MARK: - Phase 1: バトル

    /// バトル開始
    static func logStartBattle(difficulty: String, problemType: String,
                               ageGroup: String, isFirstSession: Bool) {
        log("start_battle", parameters: [
            "difficulty": difficulty,
            "problem_type": problemType,
            "age_group": ageGroup,
            "is_first_session": isFirstSession
        ])
    }

    /// バトル完了
    static func logCompleteBattle(floor: Int, correctRate: Int, score: Int,
                                  coinsEarned: Int, durationSec: Int,
                                  ageGroup: String = "") {
        var params: [String: Any] = [
            "floor": floor,
            "correct_rate": correctRate,
            "score": score,
            "coins_earned": coinsEarned,
            "duration_sec": durationSec
        ]
        if !ageGroup.isEmpty { params["age_group"] = ageGroup }
        log("complete_battle", parameters: params)
    }

    /// バトル途中離脱
    static func logQuitBattle(floor: Int, questionsAnswered: Int, durationSec: Int) {
        log("quit_battle", parameters: [
            "floor": floor,
            "questions_answered": questionsAnswered,
            "duration_sec": durationSec
        ])
    }

    // MARK: - Phase 1: オンライン

    /// マッチング開始
    static func logStartMatching(isFamily: Bool, additionOnly: Bool) {
        log("start_matching", parameters: [
            "is_family": isFamily,
            "addition_only": additionOnly
        ])
    }

    /// マッチング離脱
    static func logCancelMatching(waitSec: Int, reason: String) {
        log("cancel_matching", parameters: [
            "wait_sec": waitSec,
            "reason": reason
        ])
    }

    /// オンライン対戦完了
    static func logCompleteOnlineBattle(myScore: Int, opponentScore: Int,
                                        result: String, durationSec: Int) {
        log("complete_online_battle", parameters: [
            "my_score": myScore,
            "opponent_score": opponentScore,
            "result": result,
            "duration_sec": durationSec
        ])
    }

    // MARK: - Phase 1: 課金

    /// PRO購入画面表示
    static func logViewPaywall(source: String) {
        log("view_paywall", parameters: [
            "source": source
        ])
    }

    /// 購入結果
    static func logResultPurchase(state: String, productId: String) {
        log("result_purchase", parameters: [
            "state": state,
            "product_id": productId
        ])
    }

    // MARK: - Phase 2: ショップ

    static func logViewKisekaeShop() {
        log("view_kisekae_shop", parameters: nil)
    }

    static func logChangeColor(color: String, coinsSpent: Int) {
        log("change_color", parameters: [
            "color": color,
            "coins_spent": coinsSpent
        ])
    }

    static func logViewKoukanShop() {
        log("view_koukan_shop", parameters: nil)
    }

    static func logSellItem(itemId: String, rarity: String, coinGained: Int) {
        log("sell_item", parameters: [
            "item_id": itemId,
            "rarity": rarity,
            "coin_gained": coinGained
        ])
    }

    static func logViewBGMShop() {
        log("view_bgm_shop", parameters: nil)
    }

    static func logTapOnlineVersus() {
        log("tap_online_versus", parameters: nil)
    }

    // MARK: - 家族モード（NPC/パス&プレイ）

    static func logViewBattleModeSelect() {
        log("view_battle_mode_select", parameters: nil)
    }

    static func logViewFamilySelect() {
        log("view_family_select", parameters: nil)
    }

    static func logFamilySetupComplete(memberCount: Int) {
        log("family_setup_complete", parameters: [
            "member_count": memberCount
        ])
    }

    static func logFamilyMemberSelected(member: String) {
        log("family_member_selected", parameters: [
            "member": member
        ])
    }

    static func logFamilyBattleStart(member: String, additionOnly: Bool) {
        log("family_battle_start", parameters: [
            "member": member,
            "addition_only": additionOnly
        ])
    }

    static func logViewFamilyRanking(didUpdateBest: Bool) {
        log("view_family_ranking", parameters: [
            "did_update_best": didUpdateBest
        ])
    }

    // MARK: - Phase 3: PRO

    static func logTapUpgradePro(source: String) {
        log("tap_upgrade_pro", parameters: [
            "source": source
        ])
    }

    static func logProFeatureUse(feature: String) {
        log("pro_feature_use", parameters: [
            "feature": feature
        ])
    }

    // MARK: - 旧イベント互換（既存コードからの呼び出し用）

    static func logAppOpen() {
        log("app_open", parameters: nil)
    }

    static func logSetupStart() {
        log("setup_start", parameters: nil)
    }

    static func logAgeSelected(ageGroup: String) {
        log("age_selected", parameters: ["age_group": ageGroup])
    }

    static func logSetupComplete(ageGroup: String) {
        log("setup_complete", parameters: ["age_group": ageGroup])
        setAgeGroup(ageGroup)
    }

    static func logTitleShown(ageGroup: String) {
        log("title_shown", parameters: ["age_group": ageGroup])
    }

    static func logStartTapped(mode: String) {
        log("start_tapped", parameters: ["mode": mode])
    }

    static func logBattleStart(ageGroup: String, difficulty: String) {
        logStartBattle(difficulty: difficulty, problemType: "mixed",
                       ageGroup: ageGroup, isFirstSession: false)
    }

    static func logBattleComplete(floor: Int, correctCount: Int, totalCount: Int, isPro: Bool) {
        let rate = totalCount > 0 ? Int(Double(correctCount) / Double(totalCount) * 100) : 0
        logCompleteBattle(floor: floor, correctRate: rate, score: 0, coinsEarned: 0, durationSec: 0)
    }

    static func logBattleQuit(floor: Int, questionsAnswered: Int) {
        logQuitBattle(floor: floor, questionsAnswered: questionsAnswered, durationSec: 0)
    }

    static func logOnlineBattleStart(isFamily: Bool) {
        logStartMatching(isFamily: isFamily, additionOnly: false)
    }

    static func logOnlineBattleComplete(myScore: Int, opponentScore: Int) {
        let result = myScore > opponentScore ? "win" : (myScore < opponentScore ? "lose" : "draw")
        logCompleteOnlineBattle(myScore: myScore, opponentScore: opponentScore,
                                result: result, durationSec: 0)
    }

    static func logProPurchased() {
        logResultPurchase(state: "success", productId: "info.ohlo.Kazumon.pro")
        setUserTier("pro")
    }

    static func logFloorReached(floor: Int) {
        log("floor_reached", parameters: ["floor": floor])
    }

    static func logShareTapped() {
        log("share_tapped", parameters: nil)
    }

    static func logDifficultySelected(difficulty: String) {
        log("difficulty_selected", parameters: ["difficulty": difficulty])
    }

    static func logTutorialCompleted() {
        log("tutorial_completed", parameters: nil)
    }

    static func logReturnSession(daysSinceInstall: Int) {
        log("return_session", parameters: ["days_since_install": daysSinceInstall])
    }

    // MARK: - Paywall Events

    static func logPaywallView(source: String, ageGroup: String = "") {
        var params: [String: Any] = ["source": source]
        if !ageGroup.isEmpty { params["age_group"] = ageGroup }
        log("paywall_view", parameters: params)
    }

    static func logPaywallDismiss(source: String) {
        log("paywall_dismiss", parameters: ["source": source])
    }

    static func logFreePlayLimitHit(playCount: Int) {
        log("free_play_limit_hit", parameters: ["play_count": playCount])
    }

    static func logComebackBonus(coins: Int, daysAbsent: Int) {
        log("comeback_bonus", parameters: ["coins": coins, "days_absent": daysAbsent])
    }

    // MARK: - Screen Flow Tracking

    private static var screenEntryTimes: [String: Date] = [:]
    private static var currentScreen: String = ""
    private static var sessionScreenSequence: [String] = []
    private static var isFirstSession: Bool = {
        !UserDefaults.standard.bool(forKey: "analytics_has_tracked_session")
    }()

    static func trackScreenEnter(_ screen: String) {
        let prevScreen = currentScreen
        let prevDwell = dwellTime(for: prevScreen)

        if !prevScreen.isEmpty && prevDwell > 0 {
            log("screen_exit", parameters: [
                "scr_name": prevScreen,
                "dwell_seconds": Int(prevDwell),
                "scr_next": screen
            ])
        }

        currentScreen = screen
        screenEntryTimes[screen] = Date()
        sessionScreenSequence.append(screen)

        var params: [String: Any] = [
            "scr_name": screen,
            "scr_prev": prevScreen.isEmpty ? "none" : prevScreen,
            "session_step": sessionScreenSequence.count
        ]
        params["is_first_session"] = isFirstSession ? "true" : "false"
        log("screen_enter", parameters: params)
    }

    static func trackAppBackground() {
        guard !currentScreen.isEmpty else { return }
        let dwell = dwellTime(for: currentScreen)
        log("screen_exit", parameters: [
            "scr_name": currentScreen,
            "dwell_seconds": Int(dwell),
            "scr_next": "app_background"
        ])
    }

    static func trackScreenAction(_ screen: String, action: String) {
        let dwell = dwellTime(for: screen)
        log("screen_action", parameters: [
            "scr_name": screen,
            "action": action,
            "seconds_before_action": Int(dwell)
        ])
    }

    static func trackScreenIdle(_ screen: String, idleSeconds: Int) {
        log("screen_idle", parameters: [
            "scr_name": screen,
            "idle_seconds": idleSeconds
        ])
    }

    static func trackFunnelStep(funnel: String, step: String, stepIndex: Int) {
        log("funnel_step", parameters: [
            "funnel_name": funnel,
            "step_name": step,
            "step_index": stepIndex
        ])
    }

    static func markSessionTracked() {
        UserDefaults.standard.set(true, forKey: "analytics_has_tracked_session")
        isFirstSession = false
    }

    private static func dwellTime(for screen: String) -> TimeInterval {
        guard let entry = screenEntryTimes[screen] else { return 0 }
        return Date().timeIntervalSince(entry)
    }
}
