import Foundation

@Observable
final class TitleViewModel {
    var playerData: PlayerData = DataStore.loadPlayerData()
    var dailyMission: DailyMission = DataStore.loadDailyMission()
    var showPulse: Bool = false
    var currentTab: KazumonTab = .home
    var newlyUnlockedTab: KazumonTab? = nil
    var tappedTabs: Set<String> = DataStore.loadTappedTabs()
    private var unlockQueue: [KazumonTab] = []
    private var lastKnownXP: Int = -1

    var xpProgress: Double {
        LevelTable.xpProgress(totalXP: playerData.totalXP, level: playerData.level)
    }

    var missionRemainingPlays: Int {
        max(0, DailyMission.requiredPlays - dailyMission.playCount)
    }

    var isMissionComplete: Bool {
        dailyMission.playCount >= DailyMission.requiredPlays
    }

    var isMissionClaimed: Bool {
        dailyMission.claimed
    }

    // MARK: - プレイ制限
    // ⚠️ canPlay / remainingPlays は自身の stored property (dailyMission) から算出する。
    // PurchaseManager.shared.canPlay に委譲すると DataStore (UserDefaults) への
    // 非追跡アクセスとなり、@Observable の変更通知が届かずUIが不整合になる。

    var isPro: Bool {
        PurchaseManager.shared.isPro
    }

    var canPlay: Bool {
        PurchaseManager.shared.isPro
            || dailyMission.playCount < PurchaseManager.maxFreePlayCount
    }

    var remainingPlays: Int {
        PurchaseManager.shared.isPro
            ? .max
            : max(0, PurchaseManager.maxFreePlayCount - dailyMission.playCount)
    }

    func refresh() {
        let oldXP = lastKnownXP
        playerData = DataStore.loadPlayerData()
        dailyMission = DataStore.loadDailyMission()
        let newXP = playerData.totalXP
        print("🎮 [TitleVM.refresh] playCount=\(dailyMission.playCount), XP=\(newXP)")

        // タブ解放チェック（初回refresh＝oldXP -1 のときは通知しない）
        if oldXP >= 0 {
            let newlyUnlocked = KazumonTab.allCases.filter { tab in
                tab.requiredXP > 0
                && oldXP < tab.requiredXP
                && newXP >= tab.requiredXP
            }
            if !newlyUnlocked.isEmpty {
                unlockQueue.append(contentsOf: newlyUnlocked)
                if newlyUnlockedTab == nil {
                    newlyUnlockedTab = unlockQueue.removeFirst()
                }
            }
        }
        lastKnownXP = newXP
    }

    func markTabTapped(_ tab: KazumonTab) {
        DataStore.saveTappedTab(tab)
        tappedTabs = DataStore.loadTappedTabs()
    }

    func isTabPulsing(_ tab: KazumonTab) -> Bool {
        // 解放済み かつ 未タップ かつ home/settings 以外
        tab.requiredXP > 0
        && tab.isUnlocked(totalXP: playerData.totalXP)
        && !tappedTabs.contains(tab.rawValue)
    }

    // ポップアップを閉じる → キューに次があれば続けて表示
    func dismissUnlockPopup() {
        if unlockQueue.isEmpty {
            newlyUnlockedTab = nil
        } else {
            newlyUnlockedTab = unlockQueue.removeFirst()
        }
    }

    #if DEBUG
    func setDebugLevel(_ level: Int) {
        let index = min(max(level - 1, 0), LevelTable.xpRequired.count - 1)
        playerData.totalXP = LevelTable.xpRequired[index]
        playerData.level = level
        playerData.bestFloor = 0
        playerData.bestScore = 0
        playerData.totalPlayCount = 0
        playerData.totalCorrect = 0
        playerData.totalAnswered = 0
        playerData.streakDays = 0
        playerData.lastPlayDate = nil
        DataStore.savePlayerData(playerData)
        refresh()
        print("🎮 [DEBUG] setLevel → Lv.\(level), XP=\(playerData.totalXP) (all stats reset)")
    }
    #endif
}
