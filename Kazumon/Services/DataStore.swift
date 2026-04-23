import Foundation

enum StorageKey: String {
    case playerData = "kazumon_player"
    case items = "kazumon_items"
    case sessions = "kazumon_sessions"
    case mistakes = "kazumon_mistakes"
    case dailyBonusDate = "kazumon_daily_bonus_date"
    case dailyMission = "kazumon_daily_mission"
    case selectedBGM = "kazumon_selected_bgm"
    case extraRecord = "kazumon_extra_record"
    case hasStartedOnce = "kazumon_has_started_once"
    case tappedTabs = "kazumon_tapped_tabs"
    case difficulty = "kazumon_difficulty"
    case shareBonusDate = "kazumon_share_bonus_date"
}

struct DailyMission: Codable, Sendable {
    var date: String
    var playCount: Int = 0
    var claimed: Bool = false

    static let requiredPlays = 3
    static let bonusXP = 50
}

struct DataStore {
    private static let defaults = UserDefaults.standard
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - データバージョン管理
    //
    // アプデでアイテムや見た目を追加した際の引き継ぎルール:
    // 1. Item に新プロパティを追加 → init(from:) でデフォルト値を設定（既存JSONが壊れない）
    // 2. 新アイテムを dropTable に追加 → 既存の保存データに影響なし（idベースで個別管理）
    // 3. 新色を colorItems に追加 → purchasedColors(Set<String>)に影響なし
    // 4. 新ショップを追加 → items配列に追加するだけ、unlockShownKeyで解放演出管理
    // 5. 構造的な破壊変更が必要な場合 → dataVersion を上げて runDataMigration で移行

    private static let dataVersionKey = "kazumon_data_version"
    private static let currentDataVersion = 1

    /// アプリ起動時に呼ぶ。バージョンが上がっていたら移行処理を実行。
    static func runDataMigrationIfNeeded() {
        let stored = defaults.integer(forKey: dataVersionKey)
        if stored < currentDataVersion {
            // v0 → v1: 初回（特に移行処理なし、バージョン記録のみ）
            defaults.set(currentDataVersion, forKey: dataVersionKey)
        }
        // 将来の例:
        // if stored < 2 { migrateV1toV2() }
        // if stored < 3 { migrateV2toV3() }
    }

    // MARK: - マルチプロフィール

    private static let profilesKey = "kazumon_profiles"
    private static let activeProfileIdKey = "kazumon_active_profile_id"

    /// プレフィックス付きキーを返す（プロフィール別データ分離）
    private static func pk(_ key: String) -> String {
        let id = activeProfileId()
        return id.isEmpty ? key : "\(id)_\(key)"
    }

    /// 外部からプレフィックス付きキーを取得（昇格処理等で使用）
    static func prefixedKey(_ key: String) -> String { pk(key) }

    static func activeProfileId() -> String {
        defaults.string(forKey: activeProfileIdKey) ?? ""
    }

    static func loadProfiles() -> [PlayerProfile] {
        guard let data = defaults.data(forKey: profilesKey),
              let profiles = try? decoder.decode([PlayerProfile].self, from: data)
        else { return [] }
        return profiles
    }

    static func saveProfiles(_ profiles: [PlayerProfile]) {
        if let data = try? encoder.encode(profiles) {
            defaults.set(data, forKey: profilesKey)
        }
    }

    static func setActiveProfile(_ id: UUID) {
        defaults.set(id.uuidString, forKey: activeProfileIdKey)
        NotificationCenter.default.post(name: .activeProfileChanged, object: nil)
    }

    static func addProfile(_ profile: PlayerProfile) {
        var profiles = loadProfiles()
        guard profiles.count < 3 else { return }
        profiles.append(profile)
        saveProfiles(profiles)
        setActiveProfile(profile.id)
    }

    static func deleteProfile(_ id: UUID) {
        var profiles = loadProfiles()
        profiles.removeAll { $0.id == id }
        saveProfiles(profiles)
        // プロフィール別データも削除
        let prefix = id.uuidString + "_"
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    static func activeProfile() -> PlayerProfile? {
        let id = activeProfileId()
        return loadProfiles().first { $0.id.uuidString == id }
    }

    /// 既存データ → プロフィール移行（初回1回のみ）
    static func migrateIfNeeded() {
        // 既にプロフィールがあれば移行済み
        guard loadProfiles().isEmpty else { return }
        // playerData が存在しなければ新規ユーザー
        guard defaults.data(forKey: "kazumon_player") != nil else { return }

        // 既存ユーザー: プロフィール作成
        let name = loadPlayerName()
        let age = loadAgeGroup()
        let profile = PlayerProfile.newProfile(name: name, ageGroup: age, colorIndex: 0)

        // 全既存キーをプレフィックス付きでコピー
        let allKeys: [String] = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("kazumon_") }
        let excludeKeys: Set<String> = [profilesKey, activeProfileIdKey, "kazumon_setup_complete"]
        for key in allKeys where !excludeKeys.contains(key) {
            let value = defaults.object(forKey: key)
            defaults.set(value, forKey: "\(profile.id.uuidString)_\(key)")
        }

        // プロフィール保存
        saveProfiles([profile])
        setActiveProfile(profile.id)

        // セットアップ済みとしてマーク
        defaults.set(true, forKey: "kazumon_setup_complete")

        // 元のキーを削除
        for key in allKeys where !excludeKeys.contains(key) {
            defaults.removeObject(forKey: key)
        }
    }

    private static var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }

    // MARK: - Player Name

    static func isNameSet() -> Bool {
        // Existing users have saved player data but no name_set flag;
        // treat them as already set so they don't see the name prompt.
        if defaults.data(forKey: pk(StorageKey.playerData.rawValue)) != nil {
            return true
        }
        return defaults.bool(forKey: pk("kazumon_name_set"))
    }

    static func loadPlayerName() -> String {
        let player = loadPlayerData()
        return player.playerName
    }

    static func savePlayerName(_ name: String) {
        var player = loadPlayerData()
        player.playerName = name
        savePlayerData(player)
        defaults.set(true, forKey: pk("kazumon_name_set"))
    }

    // MARK: - PlayerData

    static func loadPlayerData() -> PlayerData {
        guard let data = defaults.data(forKey: pk(StorageKey.playerData.rawValue)),
              let player = try? decoder.decode(PlayerData.self, from: data) else {
            var newPlayer = PlayerData()
            newPlayer.playerName = NSLocalizedString("default_player_name", comment: "")
            return newPlayer
        }
        return player
    }

    static func savePlayerData(_ player: PlayerData) {
        if let data = try? encoder.encode(player) {
            defaults.set(data, forKey: pk(StorageKey.playerData.rawValue))
        }
    }

    // MARK: - Items

    static func loadItems() -> [Item] {
        guard let data = defaults.data(forKey: pk(StorageKey.items.rawValue)),
              let items = try? decoder.decode([Item].self, from: data) else {
            return []
        }
        return items
    }

    static func saveItems(_ items: [Item]) {
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: pk(StorageKey.items.rawValue))
        }
    }

    static func addItem(_ item: Item) {
        var items = loadItems()
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = Item(
                id: items[index].id,
                name: items[index].name,
                rarity: items[index].rarity,
                emoji: items[index].emoji,
                count: items[index].count + 1
            )
        } else {
            items.append(item)
        }
        saveItems(items)
    }

    // MARK: - Session History

    static func loadSessionHistory() -> [SessionRecord] {
        guard let data = defaults.data(forKey: pk(StorageKey.sessions.rawValue)),
              let sessions = try? decoder.decode([SessionRecord].self, from: data) else {
            return []
        }
        return sessions
    }

    static func saveSession(_ record: SessionRecord) {
        var sessions = loadSessionHistory()
        sessions.insert(record, at: 0)
        if sessions.count > 50 { sessions = Array(sessions.prefix(50)) }
        if let data = try? encoder.encode(sessions) {
            defaults.set(data, forKey: pk(StorageKey.sessions.rawValue))
        }
    }

    // MARK: - Mistake Log

    static func loadMistakeLog() -> [MistakeEntry] {
        guard let data = defaults.data(forKey: pk(StorageKey.mistakes.rawValue)),
              let log = try? decoder.decode([MistakeEntry].self, from: data) else {
            return []
        }
        return log
    }

    static func saveMistakeLog(_ log: [MistakeEntry]) {
        if let data = try? encoder.encode(log) {
            defaults.set(data, forKey: pk(StorageKey.mistakes.rawValue))
        }
    }

    static func addMistake(a: Int, b: Int, answer: Int, wrongAnswer: Int) {
        var log = loadMistakeLog()
        let key = "\(a)+\(b)"
        if log.contains(where: { $0.id == key }) {
            return // already logged
        }
        let entry = MistakeEntry(
            a: a, b: b, answer: answer, wrongAnswer: wrongAnswer,
            reviewCount: 0, lastReviewDate: nil
        )
        log.append(entry)
        if log.count > 100 { log = Array(log.suffix(100)) }
        saveMistakeLog(log)
    }

    static func removeMistake(a: Int, b: Int) {
        var log = loadMistakeLog()
        log.removeAll { $0.a == a && $0.b == b }
        saveMistakeLog(log)
    }

    static func markReviewed(a: Int, b: Int) {
        var log = loadMistakeLog()
        if let idx = log.firstIndex(where: { $0.a == a && $0.b == b }) {
            var entry = log[idx]
            entry = MistakeEntry(
                a: entry.a, b: entry.b, answer: entry.answer,
                wrongAnswer: entry.wrongAnswer,
                reviewCount: entry.reviewCount + 1,
                lastReviewDate: todayString
            )
            if entry.reviewCount >= 3 {
                log.remove(at: idx) // mastered
            } else {
                log[idx] = entry
            }
            saveMistakeLog(log)
        }
    }

    // MARK: - Streak

    /// ストリーク更新。戻り値：達成したマイルストーン日数（なければnil）
    static func updateStreak(_ player: inout PlayerData) -> Int? {
        let today = todayString

        // 当日すでに更新済みならスキップ
        if player.lastPlayDate == today {
            return nil
        }

        // 48時間以上経過していたらリセット
        if let lastStr = player.lastPlayDate {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "en_US_POSIX")
            if let lastDate = f.date(from: lastStr) {
                let hours = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
                if hours >= 48 {
                    player.streakDays = 0
                }
            }
        }

        player.streakDays += 1
        player.lastPlayDate = today
        if player.streakDays > player.bestStreak {
            player.bestStreak = player.streakDays
        }

        // マイルストーンチェック
        let milestones = [3, 7, 14, 30]
        if milestones.contains(player.streakDays) {
            return player.streakDays
        }
        return nil
    }

    /// マイルストーン報酬付与（プレイ回数を増やす）
    static func grantStreakReward(milestone: Int) {
        var mission = loadDailyMission()
        let bonus: Int
        switch milestone {
        case 14: bonus = 2
        case 30: bonus = 3
        default: bonus = 1
        }
        mission.playCount = max(0, mission.playCount - bonus)
        saveDailyMission(mission)
    }

    // MARK: - Comeback Bonus

    static func checkComebackBonus() -> Int {
        let key = pk("lastComebackDate")
        let today = todayString
        guard UserDefaults.standard.string(forKey: key) != today else { return 0 }

        let player = loadPlayerData()
        guard let lastStr = player.lastPlayDate else { return 0 }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        guard let lastDate = f.date(from: lastStr) else { return 0 }

        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        guard days >= 3 else { return 0 }

        UserDefaults.standard.set(today, forKey: key)
        let bonus = min(days * 20, 200)
        addCoins(bonus)
        return bonus
    }

    // MARK: - Daily Versus Bonus

    static func canClaimDailyVersusBonus() -> Bool {
        let key = pk("dailyVersusDate")
        return UserDefaults.standard.string(forKey: key) != todayString
    }

    static func claimDailyVersusBonus() -> Int {
        let key = pk("dailyVersusDate")
        guard UserDefaults.standard.string(forKey: key) != todayString else { return 0 }
        UserDefaults.standard.set(todayString, forKey: key)
        let bonusBP = 10
        addVersusBP(bonusBP)
        return bonusBP
    }

    // MARK: - Gacha

    static func loadGachaCredits() -> Int {
        UserDefaults.standard.integer(forKey: pk("gachaCredits"))
    }

    static func addGachaCredits(_ count: Int) {
        let current = loadGachaCredits()
        UserDefaults.standard.set(current + count, forKey: pk("gachaCredits"))
    }

    static func consumeGachaPull() -> Bool {
        let credits = loadGachaCredits()
        guard credits >= 10 else { return false }
        UserDefaults.standard.set(credits - 10, forKey: pk("gachaCredits"))
        return true
    }

    // MARK: - Weekly Challenge

    static func loadWeeklyPlayDays() -> Int {
        let sessions = loadSessionHistory()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        let now = Date()
        let cal = Calendar.current
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let dates = Set(sessions.compactMap { s -> String? in
            guard let d = f.date(from: s.date), d >= weekStart else { return nil }
            return s.date
        })
        return dates.count
    }

    static let weeklyGoalDays = 5

    static func isWeeklyChallengeComplete() -> Bool {
        loadWeeklyPlayDays() >= weeklyGoalDays
    }

    static func claimWeeklyChallengeReward() -> Bool {
        let key = pk("weeklyChallengeClaimed")
        let cal = Calendar.current
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        let weekStr = f.string(from: weekStart)
        guard UserDefaults.standard.string(forKey: key) != weekStr else { return false }
        guard isWeeklyChallengeComplete() else { return false }
        UserDefaults.standard.set(weekStr, forKey: key)
        addCoins(200)
        return true
    }

    // MARK: - XP

    static func addXP(_ amount: Int, to player: inout PlayerData) -> Bool {
        player.totalXP += amount
        let newLevel = LevelTable.calcLevel(totalXP: player.totalXP)
        let didLevelUp = newLevel > player.level
        player.level = newLevel
        return didLevelUp
    }

    // MARK: - Daily Bonus

    static func checkDailyBonus() -> Bool {
        let today = todayString
        let lastDate = defaults.string(forKey: pk(StorageKey.dailyBonusDate.rawValue))
        return lastDate != today
    }

    static func claimDailyBonus() -> Int {
        let today = todayString
        defaults.set(today, forKey: pk(StorageKey.dailyBonusDate.rawValue))
        return 20 // +20 XP
    }

    // MARK: - Daily Mission

    static func loadDailyMission() -> DailyMission {
        let today = todayString
        guard let data = defaults.data(forKey: pk(StorageKey.dailyMission.rawValue)),
              var mission = try? decoder.decode(DailyMission.self, from: data) else {
            return DailyMission(date: today)
        }
        if mission.date != today {
            mission = DailyMission(date: today)
            saveDailyMission(mission)
        }
        return mission
    }

    static func saveDailyMission(_ mission: DailyMission) {
        if let data = try? encoder.encode(mission) {
            defaults.set(data, forKey: pk(StorageKey.dailyMission.rawValue))
        }
    }

    static func incrementDailyMissionPlay() {
        var mission = loadDailyMission()
        mission.playCount += 1
        saveDailyMission(mission)
        print("🎮 [DataStore] incrementDailyMissionPlay → playCount=\(mission.playCount)")
    }

    static func claimDailyMissionBonus() -> Int? {
        var mission = loadDailyMission()
        guard mission.playCount >= DailyMission.requiredPlays && !mission.claimed else {
            return nil
        }
        mission.claimed = true
        saveDailyMission(mission)
        return DailyMission.bonusXP
    }

    // MARK: - Selected BGM

    static func loadSelectedBGM() -> String {
        return UserDefaults.standard.string(forKey: pk(StorageKey.selectedBGM.rawValue)) ?? "bgm_battle"
    }

    static func saveSelectedBGM(_ name: String) {
        UserDefaults.standard.set(name, forKey: pk(StorageKey.selectedBGM.rawValue))
    }

    // MARK: - Today Play Count

    static func todayPlayCount() -> Int {
        loadDailyMission().playCount
    }

    // MARK: - Extra Record

    static func loadExtraRecord() -> ExtraRecord {
        guard let data = defaults.data(forKey: pk(StorageKey.extraRecord.rawValue)),
              let record = try? decoder.decode(ExtraRecord.self, from: data) else {
            return ExtraRecord()
        }
        return record
    }

    static func saveExtraRecord(_ record: ExtraRecord) {
        if let data = try? encoder.encode(record) {
            defaults.set(data, forKey: pk(StorageKey.extraRecord.rawValue))
        }
    }

    // MARK: - Has Started Once

    static func hasStartedOnce() -> Bool {
        defaults.bool(forKey: pk(StorageKey.hasStartedOnce.rawValue))
    }

    static func setHasStartedOnce() {
        defaults.set(true, forKey: pk(StorageKey.hasStartedOnce.rawValue))
    }

    // MARK: - Tapped Tabs

    static func loadTappedTabs() -> Set<String> {
        let array = defaults.stringArray(forKey: pk(StorageKey.tappedTabs.rawValue)) ?? []
        return Set(array)
    }

    static func saveTappedTab(_ tab: KazumonTab) {
        var tapped = loadTappedTabs()
        tapped.insert(tab.rawValue)
        defaults.set(Array(tapped), forKey: pk(StorageKey.tappedTabs.rawValue))
    }

    // MARK: - Difficulty

    static func loadDifficulty() -> Difficulty {
        guard let raw = defaults.string(forKey: pk(StorageKey.difficulty.rawValue)),
              let difficulty = Difficulty(rawValue: raw) else {
            return .normal
        }
        return difficulty
    }

    static func saveDifficulty(_ difficulty: Difficulty) {
        defaults.set(difficulty.rawValue, forKey: pk(StorageKey.difficulty.rawValue))
    }

    // MARK: - Share Bonus

    static func hasReceivedShareBonusToday() -> Bool {
        let saved = defaults.string(forKey: pk(StorageKey.shareBonusDate.rawValue)) ?? ""
        return saved == todayString
    }

    static func markShareBonusReceived() {
        defaults.set(todayString, forKey: pk(StorageKey.shareBonusDate.rawValue))
    }

    // MARK: - Power Level

    private static let lastPowerLevelKey = "kazumon_last_power_level"

    static func loadLastPowerLevel() -> Int {
        defaults.integer(forKey: pk(lastPowerLevelKey))
    }

    static func saveLastPowerLevel(_ level: Int) {
        defaults.set(level, forKey: pk(lastPowerLevelKey))
    }

    // MARK: - Age Group

    private static let ageGroupKey = "kazumon_age_group"

    static func loadAgeGroup() -> AgeGroup {
        guard let raw = defaults.string(forKey: pk(ageGroupKey)),
              let group = AgeGroup(rawValue: raw)
        else { return .young }
        return group
    }

    static func saveAgeGroup(_ group: AgeGroup) {
        defaults.set(group.rawValue, forKey: pk(ageGroupKey))
    }

    static func isAgeGroupSet() -> Bool {
        defaults.string(forKey: pk(ageGroupKey)) != nil
    }

    // MARK: - 30日チャレンジ

    private static let challengeKey = "kazumon_challenge"

    struct ChallengeData: Codable {
        var startDate: String?
        var currentDay: Int = 1
        var completedDays: [Int] = []
        var isActive: Bool = false
    }

    static func loadChallenge() -> ChallengeData {
        guard let data = defaults.data(forKey: pk(challengeKey)),
              let challenge = try? decoder.decode(ChallengeData.self, from: data)
        else { return ChallengeData() }
        return challenge
    }

    static func saveChallenge(_ challenge: ChallengeData) {
        if let data = try? encoder.encode(challenge) {
            defaults.set(data, forKey: pk(challengeKey))
        }
    }

    static func startChallenge() -> ChallengeData {
        var challenge = ChallengeData()
        challenge.startDate = todayString
        challenge.currentDay = 1
        challenge.completedDays = []
        challenge.isActive = true
        saveChallenge(challenge)
        return challenge
    }

    static func completeDay(_ day: Int) {
        var challenge = loadChallenge()
        if !challenge.completedDays.contains(day) {
            challenge.completedDays.append(day)
        }
        if day < 30 {
            challenge.currentDay = day + 1
        }
        saveChallenge(challenge)
    }

    static func resetChallenge() {
        saveChallenge(ChallengeData())
    }

    // MARK: - まちがいおに予告

    // MARK: - ショップ解放バナー (NEW! 表示用)

    private static let unlockBannerKey = "kazumon_unlock_banner_shown"

    static func hasShownUnlockBanner(shop: String) -> Bool {
        let shown = defaults.stringArray(forKey: pk(unlockBannerKey)) ?? []
        return shown.contains(shop)
    }

    static func markUnlockBannerShown(shop: String) {
        var shown = defaults.stringArray(forKey: pk(unlockBannerKey)) ?? []
        if !shown.contains(shop) {
            shown.append(shop)
            defaults.set(shown, forKey: pk(unlockBannerKey))
        }
    }

    // MARK: - 宝箱システム

    private static let treasureChestDateKey = "kazumon_treasure_chest_date"
    private static let treasureChestPositionKey = "kazumon_treasure_chest_pos"
    private static let treasureChestOpenedTodayKey = "kazumon_treasure_chest_opened"

    /// 宝箱の今日の位置 (x, y) -0.4〜0.4 (ショップ・キャラと被らない位置)
    static func loadTreasureChestPosition() -> (x: Double, y: Double) {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        let today = f.string(from: Date())
        let savedDate = defaults.string(forKey: pk(treasureChestDateKey))

        if savedDate == today, let data = defaults.data(forKey: pk(treasureChestPositionKey)),
           let pos = try? decoder.decode([Double].self, from: data), pos.count == 2 {
            return (pos[0], pos[1])
        }
        let pos = randomChestPosition()
        if let data = try? encoder.encode([pos.0, pos.1]) {
            defaults.set(data, forKey: pk(treasureChestPositionKey))
        }
        defaults.set(today, forKey: pk(treasureChestDateKey))
        defaults.set(false, forKey: pk(treasureChestOpenedTodayKey))
        return (pos.0, pos.1)
    }

    /// 宝箱の位置を新しいランダム位置に変更（開けた後）
    static func relocateTreasureChest() {
        let pos = randomChestPosition()
        if let data = try? encoder.encode([pos.0, pos.1]) {
            defaults.set(data, forKey: pk(treasureChestPositionKey))
        }
    }

    /// ショップ・キャラタップ範囲を避けた位置
    private static func randomChestPosition() -> (Double, Double) {
        let avoidAreas: [(Double, Double, Double)] = [
            (0.30, -0.05, 0.30),   // battle/くもゲート (右) — 半径拡大
            (0.0, 0.30, 0.25),     // bgm (下)
            (-0.30, -0.05, 0.25),  // kisekae (左)
            (0.0, -0.25, 0.25),    // koukan (上)
            (-0.40, 0.0, 0.25),    // キャラ位置 (画面左)
            (0.0, 0.0, 0.15),      // 中央（木ボタン付近）
        ]
        for _ in 0..<30 {
            let x = Double.random(in: -0.42 ... 0.42)
            let y = Double.random(in: -0.32 ... 0.32)
            let conflict = avoidAreas.contains { ax, ay, r in
                hypot(x - ax, y - ay) < r
            }
            if !conflict { return (x, y) }
        }
        // フォールバック: 中央付近
        return (0, 0)
    }

    static func isTreasureChestOpenedToday() -> Bool {
        defaults.bool(forKey: pk(treasureChestOpenedTodayKey))
    }

    static func markTreasureChestOpened() {
        defaults.set(true, forKey: pk(treasureChestOpenedTodayKey))
    }

    /// デイリーミッションで何プレイ達成したか（宝箱条件: 1プレイ以上）
    static func canOpenTreasureChestToday() -> Bool {
        loadDailyMission().playCount >= 1
    }

    /// デイリーミッション全クリア (3プレイ達成)
    static func isDailyMissionFullyComplete() -> Bool {
        loadDailyMission().playCount >= DailyMission.requiredPlays
    }

    // MARK: - 島の木システム

    private static let plantedTreesKey = "kazumon_planted_trees"
    private static let treeShopStockKey = "kazumon_tree_shop_stock"
    private static let treeShopLastRefillKey = "kazumon_tree_shop_last_refill"

    /// 植えた木一覧（枯れた木を自動削除）
    static func loadPlantedTrees() -> [PlantedTree] {
        guard let data = defaults.data(forKey: pk(plantedTreesKey)),
              let trees = try? decoder.decode([PlantedTree].self, from: data) else {
            return []
        }
        // 枯れた木を除外
        let alive = trees.filter { !$0.isWithered }
        if alive.count != trees.count {
            // 死んだ木があれば保存し直す
            savePlantedTrees(alive)
        }
        return alive
    }

    static func savePlantedTrees(_ trees: [PlantedTree]) {
        guard let data = try? encoder.encode(trees) else { return }
        defaults.set(data, forKey: pk(plantedTreesKey))
    }

    static func plantTree(at x: Double, y: Double) -> Bool {
        var trees = loadPlantedTrees()
        guard trees.count < TreeConfig.islandMaxTrees else { return false }
        trees.append(PlantedTree(x: x, y: y))
        savePlantedTrees(trees)
        return true
    }

    /// 木ショップの現在の在庫（補充チェック付き）
    static func loadTreeShopStock() -> Int {
        refillTreeShopIfNeeded()
        return defaults.integer(forKey: pk(treeShopStockKey))
    }

    /// 在庫を1減らす（購入時）
    static func decrementTreeShopStock() {
        let current = loadTreeShopStock()
        defaults.set(max(0, current - 1), forKey: pk(treeShopStockKey))
    }

    /// 経過日数に応じて在庫を補充
    private static func refillTreeShopIfNeeded() {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        let lastStr = defaults.string(forKey: pk(treeShopLastRefillKey))

        // 初回: 在庫MAX + 今日を記録
        guard let lastStr = lastStr,
              let lastDate = f.date(from: lastStr) else {
            defaults.set(TreeConfig.shopMaxStock, forKey: pk(treeShopStockKey))
            defaults.set(f.string(from: Date()), forKey: pk(treeShopLastRefillKey))
            return
        }

        // 経過日数から補充数計算
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        let refills = days / TreeConfig.shopRefillDays
        if refills > 0 {
            let current = defaults.integer(forKey: pk(treeShopStockKey))
            let newStock = min(TreeConfig.shopMaxStock, current + refills)
            defaults.set(newStock, forKey: pk(treeShopStockKey))
            // 補充した日付を進める（端数日数は次回に持ち越す）
            let advancedDays = refills * TreeConfig.shopRefillDays
            if let newLast = Calendar.current.date(byAdding: .day, value: advancedDays, to: lastDate) {
                defaults.set(f.string(from: newLast), forKey: pk(treeShopLastRefillKey))
            }
        }
    }

    /// 次の補充までの日数
    static func daysUntilNextTreeRefill() -> Int {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        guard let lastStr = defaults.string(forKey: pk(treeShopLastRefillKey)),
              let lastDate = f.date(from: lastStr) else { return TreeConfig.shopRefillDays }
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return max(0, TreeConfig.shopRefillDays - (days % TreeConfig.shopRefillDays))
    }

    private static let mistakeBossDateKey = "kazumon_mistake_boss_date"

    /// まちがいおにの出現予定日を翌日にセット
    static func scheduleMistakeBoss() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        defaults.set(f.string(from: tomorrow), forKey: pk(mistakeBossDateKey))
    }

    /// まちがいおにの出現予定日が今日かどうか
    static func isMistakeBossScheduledToday() -> Bool {
        guard let scheduled = defaults.string(forKey: pk(mistakeBossDateKey)) else { return false }
        return scheduled == todayString
    }

    /// まちがいおにの予告がセットされたか（今日バトル終了後にセット済み）
    static func hasMistakeBossWarning() -> Bool {
        defaults.string(forKey: pk(mistakeBossDateKey)) != nil
    }

    /// まちがいおにの予告をクリア
    static func clearMistakeBossSchedule() {
        defaults.removeObject(forKey: pk(mistakeBossDateKey))
    }

    // MARK: - まちがいおに累計カウンター

    private static let totalMistakeCountKey = "kazumon_total_mistake_count"

    static func loadTotalMistakeCount() -> Int {
        defaults.integer(forKey: pk(totalMistakeCountKey))
    }

    static func incrementTotalMistakeCount() {
        defaults.set(loadTotalMistakeCount() + 1, forKey: pk(totalMistakeCountKey))
    }

    static func resetTotalMistakeCount() {
        defaults.set(0, forKey: pk(totalMistakeCountKey))
    }

    // MARK: - じかんどろぼうスケジュール

    private static let timeBossDateKey = "kazumon_time_boss_date"
    private static let timeBossDefeatedKey = "kazumon_time_boss_defeated"

    static func scheduleTimeBoss() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        defaults.set(f.string(from: tomorrow), forKey: pk(timeBossDateKey))
    }

    static func isTimeBossScheduledToday() -> Bool {
        guard let scheduled = defaults.string(forKey: pk(timeBossDateKey)) else { return false }
        return scheduled == todayString
    }

    static func clearTimeBossSchedule() {
        defaults.removeObject(forKey: pk(timeBossDateKey))
    }

    static func isTimeBossDefeated() -> Bool {
        defaults.bool(forKey: pk(timeBossDefeatedKey))
    }

    static func markTimeBossDefeated() {
        defaults.set(true, forKey: pk(timeBossDefeatedKey))
    }

    static func resetTimeBossDefeated() {
        defaults.set(false, forKey: pk(timeBossDefeatedKey))
    }

    // MARK: - 初回セットアップ

    private static let setupCompleteKey = "kazumon_setup_complete"

    static func hasCompletedSetup() -> Bool {
        defaults.bool(forKey: setupCompleteKey)
    }

    static func markSetupComplete() {
        defaults.set(true, forKey: setupCompleteKey)
    }

    // MARK: - ビフォーテスト

    private static let beforeTestScoreKey = "kazumon_before_test_score"
    private static let beforeTestLevelKey = "kazumon_before_test_level"
    private static let beforeTestDateKey  = "kazumon_before_test_date"
    private static let afterTestScoreKey  = "kazumon_after_test_score"
    private static let afterTestLevelKey  = "kazumon_after_test_level"
    private static let afterTestDateKey   = "kazumon_after_test_date"

    static func hasCompletedBeforeTest() -> Bool {
        defaults.object(forKey: pk(beforeTestScoreKey)) != nil
    }

    static func saveBeforeTestResult(score: Int, total: Int, level: Int = 1) {
        defaults.set(score, forKey: pk(beforeTestScoreKey))
        defaults.set(level, forKey: pk(beforeTestLevelKey))
        defaults.set(todayString, forKey: pk(beforeTestDateKey))
    }

    static func loadBeforeTestLevel() -> Int {
        defaults.integer(forKey: pk(beforeTestLevelKey))
    }

    static func loadBeforeTestScore() -> Int {
        defaults.integer(forKey: pk(beforeTestScoreKey))
    }

    static func loadBeforeTestDate() -> String? {
        defaults.string(forKey: pk(beforeTestDateKey))
    }

    static func hasCompletedAfterTest() -> Bool {
        defaults.object(forKey: pk(afterTestScoreKey)) != nil
    }

    static func saveAfterTestResult(score: Int, total: Int, level: Int) {
        defaults.set(score, forKey: pk(afterTestScoreKey))
        defaults.set(level, forKey: pk(afterTestLevelKey))
        defaults.set(todayString, forKey: pk(afterTestDateKey))
    }

    static func loadAfterTestScore() -> Int {
        defaults.integer(forKey: pk(afterTestScoreKey))
    }

    static func loadAfterTestLevel() -> Int {
        defaults.integer(forKey: pk(afterTestLevelKey))
    }

    // MARK: - まほうのじかん

    private static let magicStartKey    = "kazumon_magic_time_start"
    private static let magicPlayKey     = "kazumon_magic_time_day_count"
    private static let magicLastDateKey = "kazumon_magic_time_last_date"
    private static let magicChangedKey  = "kazumon_magic_time_changed_at"

    static func loadMagicTimeStart() -> Int {
        let v = defaults.object(forKey: pk(magicStartKey)) as? Int
        return v ?? MagicTimeConfig.defaultStartHour
    }

    /// 終了時間は開始+1（固定1時間）
    static func loadMagicTimeEnd() -> Int {
        let start = loadMagicTimeStart()
        return (start + 1) % 24
    }

    static func saveMagicTimeStart(_ hour: Int) {
        defaults.set(hour, forKey: pk(magicStartKey))
        // 変更ロック: 現在時刻を記録
        defaults.set(Date().timeIntervalSince1970, forKey: pk(magicChangedKey))
    }

    /// 設定変更がロック中か（変更後12時間はロック）
    static func isMagicTimeChangeLocked() -> Bool {
        let ts = defaults.double(forKey: pk(magicChangedKey))
        guard ts > 0 else { return false }
        let elapsed = Date().timeIntervalSince1970 - ts
        return elapsed < 12 * 60 * 60  // 12時間
    }

    /// ロック解除までの残り時間（秒）
    static func magicTimeChangeLockRemaining() -> TimeInterval {
        let ts = defaults.double(forKey: pk(magicChangedKey))
        guard ts > 0 else { return 0 }
        let remaining = (12 * 60 * 60) - (Date().timeIntervalSince1970 - ts)
        return max(0, remaining)
    }

    static func loadMagicTimeDayCount() -> Int {
        defaults.integer(forKey: pk(magicPlayKey))
    }

    /// 今日初めてのまほうのじかんプレイなら日数+1（1日1カウント）
    static func incrementMagicTimeDayCount() {
        if let last = defaults.string(forKey: pk(magicLastDateKey)), last == todayString {
            return  // 今日すでにカウント済み
        }
        defaults.set(loadMagicTimeDayCount() + 1, forKey: pk(magicPlayKey))
        defaults.set(todayString, forKey: pk(magicLastDateKey))
    }

    static func resetMagicTimeDayCount() {
        defaults.set(0, forKey: pk(magicPlayKey))
        defaults.removeObject(forKey: pk(magicLastDateKey))
    }

    // MARK: - マスター度（カテゴリ別ユニーク正解）

    private static let masteryKey = "kazumon_mastered_problems"

    static func loadMasteredProblems() -> [String: [String]] {
        guard let data = defaults.data(forKey: pk(masteryKey)),
              let dict = try? decoder.decode([String: [String]].self, from: data)
        else { return [:] }
        return dict
    }

    static func recordCorrectProblem(a: Int, b: Int, operatorSymbol: String) {
        let category = MathCategory.classify(a: a, b: b, operatorSymbol: operatorSymbol)
        let problemKey = "\(a)\(operatorSymbol)\(b)"
        var dict = loadMasteredProblems()
        var set = Set(dict[category.rawValue] ?? [])
        set.insert(problemKey)
        dict[category.rawValue] = Array(set)
        if let data = try? encoder.encode(dict) {
            defaults.set(data, forKey: pk(masteryKey))
        }
    }

    static func masteryCount(for category: MathCategory) -> Int {
        let dict = loadMasteredProblems()
        return dict[category.rawValue]?.count ?? 0
    }

    static func masteryPercent(for category: MathCategory) -> Int {
        min(100, Int(Double(masteryCount(for: category)) / Double(MathCategory.masteryThreshold) * 100))
    }

    static func totalMasteryPercent() -> Int {
        let total = MathCategory.allCases.reduce(0) { $0 + masteryPercent(for: $1) }
        return total / MathCategory.allCases.count
    }

    // MARK: - 対戦BP

    private static let versusBPKey = "kazumon_versus_bp"

    static func loadVersusBP() -> Int {
        defaults.integer(forKey: pk(versusBPKey))
    }

    static func addVersusBP(_ delta: Int) {
        let bp = max(0, loadVersusBP() + delta)
        defaults.set(bp, forKey: pk(versusBPKey))
    }

    // MARK: - たす1確認テスト

    private static let additionCheckRoundKey = "kazumon_addition_check_round"
    private static let plusExplanationKey = "kazumon_has_seen_plus_explanation"

    /// 合格済みの最後のラウンド（0=未実施）
    static func additionCheckLastPassedRound() -> Int {
        defaults.integer(forKey: pk(additionCheckRoundKey))
    }

    static func saveAdditionCheckRound(_ round: Int) {
        defaults.set(round, forKey: pk(additionCheckRoundKey))
    }

    static func hasSeenPlusExplanation() -> Bool {
        defaults.bool(forKey: pk(plusExplanationKey))
    }

    static func markPlusExplanationSeen() {
        defaults.set(true, forKey: pk(plusExplanationKey))
    }

    // MARK: - おうえんボイス（3スロット）

    private static let parentVoiceCountKey = "kazumon_parent_voice_count"

    static func parentVoiceCount() -> Int {
        defaults.integer(forKey: pk(parentVoiceCountKey))
    }

    static func setParentVoiceCount(_ count: Int) {
        defaults.set(count, forKey: pk(parentVoiceCountKey))
    }

    static func hasParentVoiceRecording() -> Bool {
        parentVoiceCount() > 0
    }

    /// おうえんボイスのファイルURL（プロフィール別・スロット番号）
    static func parentVoiceURL(index: Int = 0) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let id = activeProfileId()
        let filename = id.isEmpty ? "parentVoice_\(index).m4a" : "\(id)_parentVoice_\(index).m4a"
        return dir.appendingPathComponent(filename)
    }

    static func deleteParentVoice(index: Int) {
        try? FileManager.default.removeItem(at: parentVoiceURL(index: index))
    }

    static func deleteAllParentVoices() {
        for i in 0..<3 {
            try? FileManager.default.removeItem(at: parentVoiceURL(index: i))
        }
        setParentVoiceCount(0)
    }

    /// 旧ファイル互換: 既存の単一ファイルをスロット0に移行
    static func migrateParentVoiceIfNeeded() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let id = activeProfileId()
        let oldFilename = id.isEmpty ? "parentVoice.m4a" : "\(id)_parentVoice.m4a"
        let oldURL = dir.appendingPathComponent(oldFilename)
        if FileManager.default.fileExists(atPath: oldURL.path) {
            let newURL = parentVoiceURL(index: 0)
            try? FileManager.default.moveItem(at: oldURL, to: newURL)
            if parentVoiceCount() == 0 { setParentVoiceCount(1) }
            // 旧フラグ削除
            defaults.removeObject(forKey: pk("kazumon_has_parent_voice"))
        }
    }

    // MARK: - 4さいモード レベルアンロック

    private static let young4UnlockedKey = "kazumon_young4_unlocked_level"

    /// アンロック済みの最大レベル（デフォルト1）
    static func young4UnlockedLevel() -> Int {
        let v = defaults.integer(forKey: pk(young4UnlockedKey))
        return v > 0 ? v : 1
    }

    /// レベルをアンロック（現在より高い場合のみ更新）
    static func young4UnlockLevel(_ level: Int) {
        if level > young4UnlockedLevel() {
            defaults.set(level, forKey: pk(young4UnlockedKey))
        }
    }

    // MARK: - 島ホームワールド

    private static let islandStateKey = "kazumon_island_state"

    static func loadIslandState() -> IslandState {
        guard let data = defaults.data(forKey: pk(islandStateKey)),
              let state = try? JSONDecoder().decode(IslandState.self, from: data) else {
            return IslandState()
        }
        return state
    }

    static func saveIslandState(_ state: IslandState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: pk(islandStateKey))
        }
    }

    // MARK: - コイン

    private static let coinsKey = "kazumon_coins"

    static func loadCoins() -> Int {
        defaults.integer(forKey: pk(coinsKey))
    }

    static func saveCoins(_ coins: Int) {
        defaults.set(coins, forKey: pk(coinsKey))
    }

    static func addCoins(_ amount: Int) {
        saveCoins(loadCoins() + amount)
    }

    static func spendCoins(_ amount: Int) -> Bool {
        let current = loadCoins()
        guard current >= amount else { return false }
        saveCoins(current - amount)
        return true
    }

    // MARK: - きせかえ（ボディカラー）

    private static let bodyColorKey = "kazumon_body_color"
    private static let purchasedColorsKey = "kazumon_purchased_colors"

    static func loadSelectedBodyColor() -> String {
        defaults.string(forKey: pk(bodyColorKey)) ?? "blue"
    }

    static func saveSelectedBodyColor(_ color: String) {
        defaults.set(color, forKey: pk(bodyColorKey))
    }

    static func loadPurchasedColors() -> Set<String> {
        let arr = defaults.stringArray(forKey: pk(purchasedColorsKey)) ?? ["blue"]
        return Set(arr)
    }

    static func savePurchasedColors(_ colors: Set<String>) {
        defaults.set(Array(colors), forKey: pk(purchasedColorsKey))
    }

    // MARK: - きせかえ（ツノ）

    private static let detailTypeKey = "kazumon_detail_type"
    private static let purchasedDetailsKey = "kazumon_purchased_details"

    /// 選択中のツノ種類（"none" / "horn_large" / "antenna_large" 等）
    static func loadSelectedDetailType() -> String {
        defaults.string(forKey: pk(detailTypeKey)) ?? "none"
    }

    static func saveSelectedDetailType(_ type: String) {
        defaults.set(type, forKey: pk(detailTypeKey))
    }

    static func loadPurchasedDetails() -> Set<String> {
        let arr = defaults.stringArray(forKey: pk(purchasedDetailsKey)) ?? ["none"]
        return Set(arr)
    }

    static func savePurchasedDetails(_ details: Set<String>) {
        defaults.set(Array(details), forKey: pk(purchasedDetailsKey))
    }

    // MARK: - 家族モード（家族構成 + 家族ベストスコア）

    private static let familyMembersKey = "kazumon_family_members"
    private static let familyScoresKey = "kazumon_family_scores"
    private static let familySetupDoneKey = "kazumon_family_setup_done"

    /// 設定済みの家族メンバー一覧を取得（未設定なら空配列）
    static func loadFamilyMembers() -> [FamilyMember] {
        guard let raw = defaults.stringArray(forKey: pk(familyMembersKey)) else { return [] }
        return raw.compactMap { FamilyMember(rawValue: $0) }
    }

    /// 家族メンバー一覧を保存
    static func saveFamilyMembers(_ members: [FamilyMember]) {
        defaults.set(members.map { $0.rawValue }, forKey: pk(familyMembersKey))
    }

    /// 家族構成セットアップ済みフラグ
    static func isFamilySetupDone() -> Bool {
        defaults.bool(forKey: pk(familySetupDoneKey))
    }

    static func markFamilySetupDone() {
        defaults.set(true, forKey: pk(familySetupDoneKey))
    }

    /// 家族スコア辞書を読み込み（key: FamilyMember.rawValue）
    static func loadFamilyScores() -> [String: FamilyScore] {
        guard let data = defaults.data(forKey: pk(familyScoresKey)),
              let scores = try? decoder.decode([String: FamilyScore].self, from: data)
        else { return [:] }
        return scores
    }

    /// 家族スコア辞書を保存
    static func saveFamilyScores(_ scores: [String: FamilyScore]) {
        if let data = try? encoder.encode(scores) {
            defaults.set(data, forKey: pk(familyScoresKey))
        }
    }

    /// 家族メンバーのベストスコアを更新（既存より高ければ更新、戻り値は更新したか）
    @discardableResult
    static func updateFamilyBestScore(_ member: FamilyMember, score: Int) -> Bool {
        var scores = loadFamilyScores()
        var current = scores[member.rawValue] ?? FamilyScore()
        let updated = score > current.bestScore
        if updated {
            current.bestScore = score
        }
        current.lastPlayedAt = Date()
        current.playCount += 1
        scores[member.rawValue] = current
        saveFamilyScores(scores)
        return updated
    }

    /// 「じぶん」のベストスコアは playerData.bestScore と同期して取得する
    static func loadFamilyScore(for member: FamilyMember) -> FamilyScore {
        if member == .self_ {
            let player = loadPlayerData()
            let stored = loadFamilyScores()[member.rawValue] ?? FamilyScore()
            // playerData の bestScore と高い方を返す
            return FamilyScore(
                bestScore: max(stored.bestScore, player.bestScore),
                lastPlayedAt: stored.lastPlayedAt,
                playCount: stored.playCount
            )
        }
        return loadFamilyScores()[member.rawValue] ?? FamilyScore()
    }
}
