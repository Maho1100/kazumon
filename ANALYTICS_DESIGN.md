# かずもん — Analytics 計測設計書

> Firebase Analytics / GA4 で何を測り、どう分析し、どう改善するかの完全設計。

---

## 1. 現状の課題整理

### 現状イベントで分かること
- アプリが起動された（app_open）
- セットアップが完了した（setup_complete）
- バトルが始まった/終わった/中断された（battle_start/complete/quit）
- オンライン対戦が始まった/終わった（online_battle_start/complete）
- 到達フロア、正答率

### 現状イベントで分からないこと

| カテゴリ | 分からないこと |
|---------|-------------|
| **初回離脱** | スタート画面で止まったか、島に行ったか、建物をタップしたか |
| **オンライン導線** | 対戦に興味を持ったか、コース選択で迷ったか、マッチング待ちで離脱したか |
| **満足度** | バトル後に満足したか不満か、リトライしたか島に戻ったか |
| **継続分析** | 何日目に何をしているか、どの体験が継続に効くか |
| **課金分析** | 課金画面を見たか、見て買わなかったか、課金後にどの機能を使っているか |
| **ユーザー紐付け** | Auth UID と Analytics が紐付いていない。個人追跡不可 |

---

## 2. イベント設計（最小構成 × 最大効果）

### 命名規則
```
{動詞}_{対象}
例: view_island, tap_battle_shop, start_matching
```
- 画面表示: `view_*`
- ボタンタップ: `tap_*`
- 処理開始: `start_*`
- 処理完了: `complete_*`
- 離脱/中断: `cancel_*`, `quit_*`
- 結果: `result_*`

### Phase 1: 最小構成（今すぐ入れるべき 12 イベント）

| # | イベント名 | タイミング | 主な用途 |
|---|-----------|----------|---------|
| 1 | `view_start_screen` | スタート画面表示 | 初回到達率 |
| 2 | `view_island` | 島画面表示 | スタート→島の遷移率 |
| 3 | `tap_shop` | 島の建物タップ | どの建物が人気か、タップされないものはどれか |
| 4 | `view_battle_shop` | バトル店内表示 | 建物タップ→入店の遷移率 |
| 5 | `start_battle` | バトル開始（1問目表示） | 既存 battle_start を統合 |
| 6 | `complete_battle` | バトル完了 | 既存 battle_complete を統合 |
| 7 | `quit_battle` | バトル途中離脱 | 既存 battle_quit を統合 |
| 8 | `start_matching` | マッチング開始 | オンライン導線の深さ |
| 9 | `cancel_matching` | マッチング中に離脱 | 待ち時間の離脱 |
| 10 | `complete_online_battle` | オンライン対戦完了 | 対戦完了率 |
| 11 | `view_paywall` | PRO購入画面表示 | 課金導線の到達率 |
| 12 | `result_purchase` | 購入結果（成功/キャンセル/失敗） | 課金ファネル |

### Phase 2: 離脱深掘り（+6 イベント）

| # | イベント名 | タイミング | 主な用途 |
|---|-----------|----------|---------|
| 13 | `view_kisekae_shop` | きせかえショップ表示 | きせかえへの関心度 |
| 14 | `change_color` | 色変更 | きせかえ利用率 |
| 15 | `view_koukan_shop` | 交換所表示 | 交換所への関心度 |
| 16 | `sell_item` | アイテム売却 | 交換所利用率 |
| 17 | `view_bgm_shop` | BGMショップ表示 | BGM関心度 |
| 18 | `tap_online_versus` | バトル店内で対戦選択 | オンライン導線の入口 |

### Phase 3: 課金分析（+4 イベント）

| # | イベント名 | タイミング | 主な用途 |
|---|-----------|----------|---------|
| 19 | `tap_upgrade_pro` | PRO購入ボタンタップ | 購入意思の強さ |
| 20 | `pro_feature_use` | PRO限定機能の利用 | PRO満足度 |
| 21 | `view_pro_plan` | PRO比較画面表示 | どの導線から来たか |
| 22 | `add_profile` | プロフィール追加 | PRO機能の利用状況 |

---

## 3. パラメータ設計

### 全イベント共通（自動付与）
```swift
// AnalyticsManager が自動で付与
"user_tier": "free" or "pro"      // UserProperty で設定
"session_number": 1, 2, 3...       // UserProperty で設定
"age_group": "young4" / "young" / "older"  // UserProperty で設定
```

### イベント別パラメータ

| イベント | パラメータ | 例 |
|---------|----------|-----|
| `tap_shop` | `shop_id` | "battle", "bgm", "kisekae", "koukan" |
| `start_battle` | `difficulty`, `problem_type`, `age_group`, `is_first_session` | "easy", "addition", "young4", true |
| `complete_battle` | `floor`, `correct_rate`, `score`, `coins_earned`, `duration_sec` | 5, 85, 42, 60, 180 |
| `quit_battle` | `floor`, `questions_answered`, `duration_sec` | 3, 8, 45 |
| `start_matching` | `is_family`, `addition_only` | false, true |
| `cancel_matching` | `wait_sec`, `reason` | 15, "user_cancel" |
| `complete_online_battle` | `my_score`, `opponent_score`, `result`, `duration_sec` | 85, 72, "win", 120 |
| `view_paywall` | `source` | "profile_add", "play_limit", "settings" |
| `result_purchase` | `state`, `product_id` | "success" / "cancel" / "fail", "info.ohlo.Kazumon.pro" |
| `change_color` | `color`, `coins_spent` | "red", 100 |
| `pro_feature_use` | `feature` | "unlimited_play", "extra_profile", "unlimited_floor" |

---

## 4. User Property 設計

| プロパティ名 | 値 | 更新タイミング |
|------------|-----|-------------|
| `user_tier` | "free" / "pro" | 起動時 + 購入成功時 |
| `login_type` | "anonymous" / "email" | ログイン成功時 |
| `age_group` | "young4" / "young" / "older" | セットアップ完了時 |
| `best_floor` | 数値 | バトル完了時 |
| `player_level` | 数値 | レベルアップ時 |
| `total_play_count` | 数値 | バトル完了時 |

---

## 5. User ID 連携

### 実装方針

```swift
// KazumonApp.init() 内、Firebase 初期化後に呼ぶ
func setupAnalyticsUser() {
    // 1. 既存ユーザーがいれば即設定
    if let user = Auth.auth().currentUser {
        Analytics.setUserID(user.uid)
        Analytics.setUserProperty(
            user.isAnonymous ? "anonymous" : "email",
            forName: "login_type"
        )
    }

    // 2. 匿名ログイン成功時に設定
    if Auth.auth().currentUser == nil {
        Auth.auth().signInAnonymously { result, error in
            if let user = result?.user {
                Analytics.setUserID(user.uid)
                Analytics.setUserProperty("anonymous", forName: "login_type")
            }
        }
    }

    // 3. user_tier を設定
    Analytics.setUserProperty(
        PurchaseManager.shared.isPro ? "pro" : "free",
        forName: "user_tier"
    )

    // 4. age_group を設定
    Analytics.setUserProperty(
        DataStore.loadAgeGroup().rawValue,
        forName: "age_group"
    )
}
```

### ログアウト時
```swift
func clearAnalyticsUser() {
    Analytics.setUserID(nil)
    Analytics.setUserProperty(nil, forName: "login_type")
    Analytics.setUserProperty(nil, forName: "user_tier")
}
```

### 購入成功時
```swift
// PurchaseManager.purchase() 内
Analytics.setUserProperty("pro", forName: "user_tier")
```

---

## 6. Swift 実装コード案

### AnalyticsManager 全体設計

```swift
import FirebaseAnalytics

enum AnalyticsManager {

    // MARK: - User Property 更新

    static func setUserTier(_ tier: String) {
        Analytics.setUserProperty(tier, forName: "user_tier")
    }

    static func setAgeGroup(_ group: String) {
        Analytics.setUserProperty(group, forName: "age_group")
    }

    static func updatePlayerStats(level: Int, bestFloor: Int, playCount: Int) {
        Analytics.setUserProperty(String(level), forName: "player_level")
        Analytics.setUserProperty(String(bestFloor), forName: "best_floor")
        Analytics.setUserProperty(String(playCount), forName: "total_play_count")
    }

    // MARK: - Phase 1: 初回導線

    static func logViewStartScreen() {
        Analytics.logEvent("view_start_screen", parameters: nil)
    }

    static func logViewIsland() {
        Analytics.logEvent("view_island", parameters: nil)
    }

    static func logTapShop(shopId: String) {
        Analytics.logEvent("tap_shop", parameters: [
            "shop_id": shopId
        ])
    }

    static func logViewBattleShop() {
        Analytics.logEvent("view_battle_shop", parameters: nil)
    }

    // MARK: - Phase 1: バトル

    static func logStartBattle(difficulty: String, problemType: String,
                               ageGroup: String, isFirstSession: Bool) {
        Analytics.logEvent("start_battle", parameters: [
            "difficulty": difficulty,
            "problem_type": problemType,
            "age_group": ageGroup,
            "is_first_session": isFirstSession
        ])
    }

    static func logCompleteBattle(floor: Int, correctRate: Int, score: Int,
                                  coinsEarned: Int, durationSec: Int) {
        Analytics.logEvent("complete_battle", parameters: [
            "floor": floor,
            "correct_rate": correctRate,
            "score": score,
            "coins_earned": coinsEarned,
            "duration_sec": durationSec
        ])
    }

    static func logQuitBattle(floor: Int, questionsAnswered: Int, durationSec: Int) {
        Analytics.logEvent("quit_battle", parameters: [
            "floor": floor,
            "questions_answered": questionsAnswered,
            "duration_sec": durationSec
        ])
    }

    // MARK: - Phase 1: オンライン

    static func logStartMatching(isFamily: Bool, additionOnly: Bool) {
        Analytics.logEvent("start_matching", parameters: [
            "is_family": isFamily,
            "addition_only": additionOnly
        ])
    }

    static func logCancelMatching(waitSec: Int, reason: String) {
        Analytics.logEvent("cancel_matching", parameters: [
            "wait_sec": waitSec,
            "reason": reason  // "user_cancel", "timeout", "error"
        ])
    }

    static func logCompleteOnlineBattle(myScore: Int, opponentScore: Int,
                                        result: String, durationSec: Int) {
        Analytics.logEvent("complete_online_battle", parameters: [
            "my_score": myScore,
            "opponent_score": opponentScore,
            "result": result,  // "win", "lose", "draw"
            "duration_sec": durationSec
        ])
    }

    // MARK: - Phase 1: 課金

    static func logViewPaywall(source: String) {
        Analytics.logEvent("view_paywall", parameters: [
            "source": source  // "profile_add", "play_limit", "settings"
        ])
    }

    static func logResultPurchase(state: String, productId: String) {
        Analytics.logEvent("result_purchase", parameters: [
            "state": state,  // "success", "cancel", "fail", "pending"
            "product_id": productId
        ])
    }

    // MARK: - Phase 2: ショップ

    static func logViewKisekaeShop() {
        Analytics.logEvent("view_kisekae_shop", parameters: nil)
    }

    static func logChangeColor(color: String, coinsSpent: Int) {
        Analytics.logEvent("change_color", parameters: [
            "color": color,
            "coins_spent": coinsSpent
        ])
    }

    static func logViewKoukanShop() {
        Analytics.logEvent("view_koukan_shop", parameters: nil)
    }

    static func logSellItem(itemId: String, rarity: String, coinGained: Int) {
        Analytics.logEvent("sell_item", parameters: [
            "item_id": itemId,
            "rarity": rarity,
            "coin_gained": coinGained
        ])
    }

    // MARK: - Phase 3: PRO

    static func logTapUpgradePro(source: String) {
        Analytics.logEvent("tap_upgrade_pro", parameters: [
            "source": source
        ])
    }

    static func logProFeatureUse(feature: String) {
        Analytics.logEvent("pro_feature_use", parameters: [
            "feature": feature
            // "unlimited_play", "extra_profile", "unlimited_floor"
        ])
    }
}
```

---

## 7. GA4 分析例

### ファネル1: 初回ユーザー離脱
```
Step 1: view_start_screen
Step 2: view_island
Step 3: tap_shop (shop_id = "battle")
Step 4: view_battle_shop
Step 5: start_battle
Step 6: complete_battle
```
→ 各ステップ間の離脱率で「どこで止まったか」が分かる

### ファネル2: オンライン導線離脱
```
Step 1: tap_shop (shop_id = "battle")
Step 2: view_battle_shop
Step 3: tap_online_versus
Step 4: start_matching
Step 5: complete_online_battle
```
→ マッチング前 vs 待ち中 vs 対戦中の離脱を分離

### ファネル3: 課金ファネル
```
Step 1: view_paywall
Step 2: tap_upgrade_pro
Step 3: result_purchase (state = "success")
```
→ 課金画面到達率 × 購入率 × source別の比較

### セグメント例
- **継続ユーザー:** total_play_count ≥ 10
- **Pro ユーザー:** user_tier = "pro"
- **オンライン好き:** complete_online_battle を3回以上
- **きせかえ好き:** change_color を1回以上

### 課金前後の行動変化
1. user_tier = "pro" のユーザーを抽出
2. result_purchase (state = "success") の日時を基準に前後7日を比較
3. 比較軸: バトル回数、オンライン率、きせかえ利用、継続日数

---

## 8. 実装優先順位

### Phase 1（今すぐ・半日）
- User ID 連携（Auth UID → Analytics）
- User Property 設定（user_tier, age_group, login_type）
- 初回導線イベント 4つ（view_start_screen, view_island, tap_shop, view_battle_shop）
- バトルイベント 3つ（start_battle, complete_battle, quit_battle）→ 既存を統合
- 課金イベント 2つ（view_paywall, result_purchase）
- マッチングイベント 2つ（start_matching, cancel_matching）
- complete_online_battle

### Phase 2（1週間以内）
- ショップイベント（view_kisekae_shop, change_color, view_koukan_shop, sell_item, view_bgm_shop）
- tap_online_versus
- updatePlayerStats の定期更新

### Phase 3（課金改善時）
- tap_upgrade_pro（source別）
- pro_feature_use
- view_pro_plan
- add_profile

### Phase 4（高度分析）
- セッション番号の自動カウント
- A/Bテスト用パラメータ
- プッシュ通知の効果測定

---

## 9. 実装タスクチェックリスト

### Phase 1

- [ ] KazumonApp.init() で Auth 成功後に `Analytics.setUserID(user.uid)` を設定
- [ ] KazumonApp.init() で `user_tier`, `age_group`, `login_type` を設定
- [ ] AnalyticsManager.swift を新イベント設計に書き換え（旧イベントも互換維持）
- [ ] StartScreenView.onAppear で `logViewStartScreen()` 追加
- [ ] IslandWorldView.onAppear で `logViewIsland()` 追加
- [ ] IslandWorldView.handleItemTap で `logTapShop(shopId:)` 追加
- [ ] BattleShopView.onAppear で `logViewBattleShop()` 追加
- [ ] GameViewModel.startGame() の `logBattleStart` を `logStartBattle` に統合
- [ ] GameViewModel.endGame() の `logBattleComplete` を `logCompleteBattle` に統合（coins_earned, duration_sec 追加）
- [ ] GameViewModel.quitGame() の `logBattleQuit` を `logQuitBattle` に統合（duration_sec 追加）
- [ ] ContentView のオンライン導線で `logStartMatching`, `logCancelMatching` 追加
- [ ] ContentView のオンライン完了で `logCompleteOnlineBattle` に統合（result, duration_sec 追加）
- [ ] ProfileSwitcherView で `logViewPaywall(source: "profile_add")` 追加
- [ ] PurchaseManager.purchase() で `logResultPurchase` 追加（success/cancel/fail 分岐）
- [ ] PurchaseManager.purchase() 成功時に `setUserTier("pro")` 追加
- [ ] DebugView で `-FIRAnalyticsDebugEnabled` の説明追加

### Phase 2

- [ ] KisekaeShopView.onAppear で `logViewKisekaeShop()` 追加
- [ ] KisekaeShopView の色変更時に `logChangeColor()` 追加
- [ ] KoukanShopView.onAppear で `logViewKoukanShop()` 追加
- [ ] KoukanShopView の売却時に `logSellItem()` 追加
- [ ] BGMTabView 表示時に `logViewBGMShop()` 追加（IslandWorldView から）
- [ ] GameViewModel.endGame() で `updatePlayerStats()` 追加

---

## まとめ: 最低限入れるべきイベント一覧

**Phase 1 の 12 イベントだけで以下が全て分析可能になる:**

| 分析したいこと | 使うイベント |
|-------------|-----------|
| 初回どこで離脱？ | view_start_screen → view_island → tap_shop → start_battle のファネル |
| オンラインに興味ある？ | tap_shop(shop_id="battle") → start_matching の遷移率 |
| マッチングで離脱？ | start_matching → cancel_matching の reason |
| バトルに満足？ | complete_battle の correct_rate + quit_battle の floor |
| 課金画面に来た？ | view_paywall の source |
| 買った？買わなかった？ | result_purchase の state |
| Pro は継続する？ | user_tier="pro" × complete_battle の頻度 |
| 個人追跡 | Analytics.setUserID(Auth UID) で GA4 Explore で可能 |
