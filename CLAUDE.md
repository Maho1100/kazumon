# カズモン — モンスタータワーバトル

## プロジェクト概要
小学1〜3年生向けの「熱狂型」算数学習ブラウザゲーム。
足し算の答えを選んでモンスターを倒し、タワーを登る「無限クライム型」ゲーム。
子どもが毎日やりたくなる"熱狂型"で、将来的に月額課金サービスに育てる。

## 技術スタック（MVP）
- フロントエンド: 静的HTML + Vanilla JS（フレームワーク不使用）
- スタイル: CSS3（アニメーション含む）
- 音声: Web Audio API（外部ライブラリ不使用）
- データ保存: localStorage
- ホスティング: GitHub Pages / Cloudflare Pages

## ファイル構成
```
kazumon/
  index.html          ... メインHTML（1ファイルで全画面を管理）
  css/
    style.css          ... 全スタイル
  js/
    game.js            ... ゲームロジック（状態管理、問題生成、スコア計算）
    sound.js           ... Web Audio APIの音声生成（正解音、不正解音、コンボ音、BGM）
    data.js            ... localStorage管理（セーブ/ロード）
    animation.js       ... アニメーション制御（攻撃、被弾、撃破、コンボ）
  img/
    （SVG画像：キャラ、モンスター等）
```

## ターゲットユーザー
- 小学1〜3年生（6〜9歳）
- 保護者が横で見ている、またはタブレットを渡して遊ばせる想定

## UI/UXルール（厳守）
- **キーボード不使用**: 全操作をクリック（タップ）のみで完結
- **大きなボタン**: 選択肢ボタンは最低 140px × 70px。小さな手でも誤タップしない
- **大きなフォント**: 最低24px以上。問題表示は48px
- **丸ゴシック体**: font-family は "Rounded Mplus 1c", "Hiragino Maru Gothic ProN", sans-serif
- **パステル背景**: 背景は柔らかい色調。目に優しく
- **原色系アクセント**: ボタンやエフェクトは赤・青・緑・黄の明るい色
- **1画面完結**: 画面遷移なし。全画面をdivの表示/非表示で切り替え
- **画面遷移時のロード待ちゼロ**: 全アセットを初回ロードで読み込む
- **縦画面基本**: モバイルファースト。max-width: 480px でセンタリング
- **ひらがな表示**: 漢字は使わない。すべてひらがな・カタカナで表示

## ゲームルール

### 基本フロー
1. タイトル画面で「スタート」ボタンをタップ
2. フロア1Fから開始。モンスター登場アニメーション
3. 足し算の問題が表示。4択の選択肢からタップで回答
4. 正解→モンスターにダメージ。不正解→モンスターの反撃でプレイヤーHP-1
5. モンスターのHPが0になると「げきは！」演出→次のフロアへ
6. 5フロアごとにボスモンスター（HPが多い）
7. プレイヤーHPが0になるとゲーム終了→リザルト画面

### 重要な設計思想
- **ゲームオーバーは「やさしい」**: 「よくがんばった！」と褒める。「ダメ」「まちがい」は絶対に言わない
- **不正解でも「おしい！」と表示**: ネガティブな言葉は使わない
- **コンボで興奮**: 連続正解でコンボカウンター。コンボ5で「NICE!」、コンボ10で「SUPER!」
- **終わりがない**: 無限クライム。自己ベスト更新が毎日のモチベーション

## 画面構成（5画面）

### 画面A: タイトル画面 (#title-screen)
| 要素 | 位置 | 詳細 |
|------|------|------|
| ロゴ | 上部中央 | 「カズモン」テキストロゴ。ポップなデザイン、影付き |
| メインキャラ | 中央 | 「カズ」のイラスト（SVG）。idle アニメーションで揺れる |
| 「スタート」ボタン | 中央下 | 200px×70px。赤色、角丸16px、パルスアニメーション |
| 「つづきから」ボタン | 「スタート」の下 | 前回到達階層から再開（セーブデータがある場合のみ表示） |
| さいこうきろく | 上部右 | 「さいこうきろく：▲ 23F」のように表示 |
| ストリーク | 上部左 | 🔥 + 「5にちれんぞく」 |
| 音声ON/OFF | 右上 | スピーカーアイコンのトグルボタン |

### 画面B: バトル画面 (#battle-screen) ★コア画面
| 要素 | 位置 | 詳細 |
|------|------|------|
| フロア表示 | 上部左 | 「▲ 7F」を大きく表示（32px bold） |
| プレイヤーHPバー | 上部左側 | 緑色バー。ハートアイコン付き。初期HP=3 |
| モンスターHPバー | 上部右側 | 赤色バー。モンスター名付き |
| モンスターイラスト | 中央右 | 150×150px（SVG）。idle アニメーション |
| プレイヤーキャラ | 中央左 | 120×120px（SVG）。攻撃時ジャンプ |
| 問題表示 | 中央 | 「3 + 5 = ?」を48pxフォントで表示 |
| 選択肢ボタン×4 | 下部 | 2×2グリッド。各140px×70px、角丸12px、太字32px |
| コンボ表示 | モンスターの上 | 「x3 COMBO!」連続正解数。コンボ5以上で色が変わる |
| スコア | 上部中央 | 現在の合計スコア |

### 画面C: 撃破演出（バトル画面上にオーバーレイ）
- 「げきは！」テキスト: 画面中央に大きく表示。金色・光るアニメーション
- モンスター消滅エフェクト: パーティクルが飛び散るCSS animation
- +50XP: 浮き上がるアニメーション
- アイテムドロップ: 30%の確率で宝箱が開く演出
- **通常フロア**: オーバーレイ表示後 約800ms で自動的に次のフロアへ進む（ボタン非表示）
- **ボスフロア**: オーバーレイ表示後 約1300ms で「つぎのフロアへ」ボタン表示。オーバーレイのどこをタップしても進める
- 二重遷移防止: advancedガードフラグにより遷移は1回だけ発火

### 画面D: ボス戦演出（5Fごと。バトル画面の特殊演出）
- 「ボスとうじょう！」テキスト: 画面が赤く光り、地震エフェクト（CSS shake）
- ボスモンスター: 通常の2倍のサイズで表示
- ボスのHP: 通常モンスターの3倍
- 撃破報酬: XPが3倍。確定でレアアイテムドロップ

### 画面E: リザルト画面 (#result-screen)
| 要素 | 位置 | 詳細 |
|------|------|------|
| 「よくがんばった！」 | 上部中央 | キャラが褒めるアニメーション |
| 今回のきろく | 中央 | 「▲ 23F」「スコア: 1,280」「コンボさいだい: x12」 |
| ベスト更新演出 | 中央 | 自己ベスト更新時は金色の特別演出 +「しんきろく！」 |
| 「もういちど」ボタン | 下部左 | 大きいボタン（180px×60px）。パルスアニメーション |
| 「おわる」ボタン | 下部右 | 小さめ（120px×50px）。タイトル画面に戻る |
| 獲得アイテム | 中央下 | 今回手に入れたアイテム一覧 |

## 演出設計

### 正解時（全体0.8秒）
1. 正解ボタンが緑に光る + 拡大（0.2秒）
2. 「ピコン！」正解音（Web Audio: 高めのサイン波 880Hz→1760Hz、0.1秒）
3. プレイヤーキャラがジャンプ攻撃（0.3秒）
4. モンスターが揺れる（CSS shake 0.3秒）+ HPバー減少アニメ
5. 「-1」ダメージ数字がモンスター上に浮かび上がる（fadeUp）
6. コンボカウンター+1

### 不正解時（全体1.0秒）
1. 選んだボタンが赤く光る + 正解ボタンが緑で点滅（1秒間正解を見せる）
2. 「ブッ」不正解音（Web Audio: 低めのサイン波 200Hz、0.15秒）
3. モンスターが攻撃アニメーション
4. プレイヤーHPが-1減る + HPバー減少アニメ
5. コンボリセット（0に戻る）
6. 「おしい！」テキスト表示（0.5秒で消える）

### コンボ演出
| コンボ数 | 演出 | 背景色変化 |
|---------|------|-----------|
| 1〜4 | カウンター表示のみ | なし |
| 5 | 「NICE COMBO!」+ 効果音 | 微かにオレンジ |
| 10 | 「SUPER COMBO!」+ 画面が光る | 赤みがかる |
| 15 | 「AMAZING!」+ 画面シェイク | 紫がかる |
| 20+ | 「LEGENDARY!」+ 全画面エフェクト | 金色 |

## レベル設計（難易度曲線）

| フロア | 問題範囲 | モンスターHP | 問題数/階 | 制限時間 |
|--------|---------|------------|----------|---------|
| 1F〜5F | 1+1 〜 5+4（答≤10） | 1 | 1問 | なし |
| 5F BOSS | 上記ランダム | 3 | 3問 | なし |
| 6F〜10F | 1+1 〜 9+9（答≤18） | 1 | 1問 | なし |
| 10F BOSS | 上記ランダム | 4 | 4問 | なし |
| 11F〜15F | くり上がりあり（5+6〜9+9） | 2 | 2問 | なし |
| 15F BOSS | くり上がりミックス | 5 | 5問 | なし |
| 16F〜20F | 繰り上がりあり（10以上+1桁） | 2 | 2問 | 15秒 |
| 20F BOSS | 繰り上がりミックス | 6 | 6問 | 15秒 |
| 21F〜30F | 2桁+2桁（10〜50の範囲） | 2 | 2問 | 12秒 |
| 30F BOSS | 総合ミックス | 8 | 8問 | 12秒 |
| 31F+ | 全範囲ランダム。段階的に難化 | +1/5F | +1/5F | -1秒/5F |

## 問題生成ロジック

### 難易度コンフィグ
```javascript
const DIFFICULTY_CONFIG = {
  // [minA, maxA, minB, maxB, errorRange]
  'easy':      [1, 5, 1, 4, 2],    // 1F-5F
  'normal':    [1, 9, 1, 9, 3],    // 6F-10F
  'carry':     [5, 9, 6, 9, 4],    // 11F-15F
  'carryUp':   [10, 50, 1, 9, 5],  // 16F-20F
  'double':    [10, 50, 10, 50, 8],// 21F-30F
  'mix':       [1, 99, 1, 99, 10]  // 31F+
};
```

### 選択肢生成ルール
1. 正解を含めて4つの選択肢を生成
2. 誤答は正解±errorRange の範囲からランダム生成
3. 負の数は除外（最小値は1）
4. 同じ数字の重複なし
5. 毎回シャッフルしてランダム配置
6. 間隔反復: 過去に間違えた問題を20%の確率で優先出題

## 報酬設計

### XP計算
- 正解: 基本10XP × コンボ倍率
- コンボ倍率: 1〜4=×1、5〜9=×2、10〜14=×3、15〜19=×4、20+=×5
- ボス撃破: +100XP
- デイリーログイン: +50XP

### レベルアップ
| レベル | 必要累計XP | 解放要素 |
|--------|-----------|---------|
| Lv.1→2 | 100 | なし（初回プレイで到達） |
| Lv.5 | 800 | キャラ色変更 |
| Lv.10 | 2,500 | 新キャラアバター |
| Lv.20 | 8,000 | 特殊エフェクト |
| Lv.50 | 50,000 | 伝説の称号 |
| Lv.100 | 200,000 | 「カズモンマスター」の称号 |

### アイテムシステム
- ボス撃破時に30%の確率でアイテムドロップ
- レア度: common(60%), rare(25%), epic(10%), legendary(5%)
- アイテムは図鑑に登録される（コレクション要素）

## localStorage データ構造

### ユーザーデータ (key: "kazumon_user")
```json
{
  "playerName": "カズ",
  "level": 1,
  "totalXP": 0,
  "bestFloor": 0,
  "bestScore": 0,
  "streakDays": 0,
  "lastPlayDate": "2026-02-12",
  "totalPlayCount": 0,
  "totalCorrect": 0,
  "totalAnswered": 0,
  "soundEnabled": true
}
```

### アイテムデータ (key: "kazumon_items")
```json
[
  {
    "id": "item_001",
    "name": "ほのおのけん",
    "rarity": "rare",
    "obtainedAt": "2026-02-12T10:30:00"
  }
]
```

### セッション履歴 (key: "kazumon_sessions")
```json
[
  {
    "maxFloor": 23,
    "score": 1280,
    "maxCombo": 12,
    "correctRate": 0.85,
    "playedAt": "2026-02-12T10:30:00",
    "duration": 420
  }
]
```
最大100件保持。古いものから削除。

### 間違いログ (key: "kazumon_mistakes")
```json
[
  {
    "a": 7,
    "b": 8,
    "wrongAnswer": 14,
    "count": 3,
    "lastMistake": "2026-02-12T10:30:00",
    "nextReview": "2026-02-13T10:30:00"
  }
]
```

## パフォーマンス要件
- 初回ロード: 3秒以内
- タップから演出開始: 50ms以内
- 60fps維持（CSS animationを優先、JSはrequestAnimationFrame）
- 全アセット合計: 500KB以下

## 対応デバイス
- iPad / iPad mini（メインターゲット）
- iPhone / Androidスマホ
- PCブラウザ（Chrome, Safari, Edge）
- 縦画面基本。横画面でも崩れない

## 注意事項
- 漢字は使わない。すべてひらがな・カタカナ
- ネガティブな言葉は使わない（「まちがい」→「おしい！」）
- 音声は必ず実装する（継続率に直結）
- モンスターのデザインは「かわいい」寄り。怖くしない
- 色覚多様性に配慮（赤緑だけで判断させない。形やテキストも併用）

## アイテム表示ルール（★表記）

UIでアイテムのレア度を表示するときは、英語ラベル（common/rare等）を使わず **★の数** で統一する。

| 内部レア度 | UI表記 | 表示色 |
|-----------|--------|--------|
| common    | ★      | グレー (#A0AEC0) |
| rare      | ★★     | 青 (#4299E1) |
| epic      | ★★★    | 紫 (#9F7AEA) |
| legendary | ★★★★   | 金 (#D69E2E) |

- 表示例: `★★ ほのおのけん`、`★★★★ せかいじゅのしずく`
- 共通関数 `formatItemDisplay(item)` を通して表示文字列を生成する（game.js内）
- `RARITY_STARS` マップで内部レア度→★文字列を変換する
- 保存データ（localStorage）の `rarity` フィールドは英語のまま変更しない
- CSSクラス名（`.rarity-common` 等）も内部用なのでそのまま残す

## ずかん（アイテムコレクション）

タイトル画面から所持アイテム一覧を閲覧できるモーダル機能。

### DOM構造
- `#collection-btn` — タイトル画面の「ずかん」ボタン
- `#collection-overlay` — 半透明背景のモーダルオーバーレイ（z-index: 150）
  - `.collection-card` — 白背景の中央カード（max-width: 440px, max-height: 80vh, スクロール可）
    - `#collection-close` — 「×」閉じるボタン
    - `#collection-body` — JS で動的に描画される一覧エリア

### 表示ルール
- データソース: `loadItems()`（localStorage の kazumon_items）
- レア度ごとにセクション分け（legendary → epic → rare → common の順）
- 同名アイテムはまとめて「×N」表示（例: `★ ほのおのけん ×3`）
- 各アイテムは「★表記 + 名前」で表示（`RARITY_STARS` を使用）
- 所持が0件のときは「まだ ないよ / あそぶと ふえるよ！」を表示

### 開閉
- 開く: `#collection-btn` クリック → `openCollection()`
- 閉じる: `#collection-close` クリック、またはカード外の背景タップ → `closeCollection()`
- `showScreen()` には影響しない（タイトル画面上にオーバーレイ表示）

### JS関数（game.js）
- `renderCollection()` — loadItems → 集計 → セクション生成 → `#collection-body` に描画
- `openCollection()` — renderCollection + overlay表示
- `closeCollection()` — overlay非表示

## デイリーボーナス

1日1回、タイトル画面表示時に「きょうのごほうび！」オーバーレイを出して +20 XP を付与する。

### 多重付与防止
- localStorage キー `kazumon_daily_bonus_date` に付与済み日付（YYYY-MM-DD）を保存
- `maybeShowDailyBonus()` 呼び出し時に今日の日付と比較し、一致すれば何もしない
- 付与直前に `setDailyBonusDate(today)` を呼ぶため、同日中はリロード・画面遷移しても2回目は発火しない

### 呼び出しタイミング
- `DOMContentLoaded` の `applyUserDataToTitle()` 直後（初回ロード）
- `showScreen('title-screen')` 内（ゲーム終了→タイトル帰還時の日またぎ対応）

### DOM
- `#daily-bonus-overlay` — 半透明背景（`.collection-overlay` を流用）
  - `.daily-bonus-card` — 白背景の中央カード
  - `.daily-bonus-icon` — 🎁
  - `.daily-bonus-title` — 「きょうのごほうび！」
  - `.daily-bonus-xp` — 「+20 XP」
  - `#daily-bonus-ok` — 「OK」ボタン

### 閉じ方
- `#daily-bonus-ok` クリック → `closeDailyBonus()`
- カード外の背景タップ → `closeDailyBonus()`

### JS関数
- `maybeShowDailyBonus()` (game.js) — 日付判定 → XP付与 → Lv表示更新 → overlay表示
- `closeDailyBonus()` (game.js) — overlay非表示
- `getDailyBonusDate()` / `setDailyBonusDate(dateStr)` (data.js) — localStorage の読み書き

## ストリーク報酬

連続ログインのマイルストーン達成時に特別なアイテムを付与する。

### マイルストーン表
| 日数 | 報酬ルール | 説明 |
|------|-----------|------|
| 7日 | epic以上確定 | ITEM_POOLからepic+legendaryで抽選 |
| 30日 | legendary確定 | ITEM_POOLからlegendaryのみ抽選 |

### ルール
- 各マイルストーンの報酬付与は **1回だけ**（多重付与禁止）
- 判定タイミング: `applyUserDataToTitle()` 内の `updateStreak()` 直後
- 付与時にゴールド枠の演出オーバーレイを表示

### localStorage
- キー: `kazumon_streak_rewards` (Array型、例: `[7]` or `[7, 30]`)
- 付与済みマイルストーンの数値配列を保存
- 既存の `kazumon_user.streakDays` を参照して判定（変更なし）

### 変更ファイル
- `data.js` — `KEYS.STREAK_REWARDS`、`loadStreakRewards()`、`markStreakRewardClaimed(milestone)`、`getUnclaimedStreakReward(streakDays)`
- `game.js` — `generateStreakRewardItem(milestone)`、`maybeShowStreakReward()`、`closeStreakReward()`、イベントリスナー追加
- `index.html` — `#streak-reward-overlay` DOM追加
- `css/style.css` — `.streak-reward-*` スタイル追加

## 間隔反復（復習20%）

間違えた問題を自動で再出題し、学習効果を高める仕組み。

### 基本動作
- 問題生成時に 20%の確率で `getReviewProblems()` から復習問題を出す
- `nextReview <= now` の問題のみが出題対象
- 復習問題には問題ボックス右上に「🔁 ふくしゅう」バッジを表示

### 復習間隔（calcNextReview）
| ミス回数 | 次回復習 |
|---------|---------|
| 1回目 | 2分後 |
| 2回目 | 翌日（24時間後） |
| 3回目以降 | 3日後 |

### 正解時の動作
- 復習問題を正解 → `removeMistake(a, b)` で localStorage の mistakeLog から削除
- 通常問題を正解 → 何もしない（削除しない）

### 不正解時の動作
- `addMistake(a, b, wrongAnswer)` で count++ と nextReview 更新（既存処理）

### 変更ファイル
- `data.js` — `removeMistake(a, b)` 追加
- `game.js` — `showProblem()` にバッジ表示切り替え追加、`onCorrectAnswer()` に復習正解時の削除追加
- `index.html` — `#review-badge` DOM追加
- `css/style.css` — `.review-badge` スタイル追加、`.question-box` に `position: relative` 追加

## デイリーミッション

1日1つの固定ミッション。達成で報酬、翌日リセット。

### localStorage
- キー: `kazumon_daily_mission`
- JSON: `{ date: "YYYY-MM-DD", claimed: true/false, attempts: number }`
- 日付が変わると `attempts=0, claimed=false` に自動リセット（`loadDailyMission()` 内で判定）

### 達成条件
- 当日中にバトルで **回答を5回** 行う（正解・不正解を問わない。タイムアウトは含まない）

### 報酬
- +50 XP（`addXP(50)` で付与）
- `claimed=true` 後は同日中に再付与しない（多重付与禁止）

### UI
- タイトル画面: `#daily-mission-display` にミッション内容と進捗を常時表示（例: `📋 きょうのミッション：もんだいを 5もん とく（3/5）`）
- 達成時: `#daily-mission-overlay`（`collection-overlay` 流用）で「デイリーミッションたっせい！ +50 XP」を表示
- 閉じ方: `#daily-mission-ok` クリック、またはカード外の背景タップ

### 呼び出しタイミング
- 回答フック: `handleAnswer()` 内の `gameState.totalAnswered++` 直後に `trackDailyMissionAttempt()` を呼ぶ
- タイトル表示: `applyUserDataToTitle()` 内で `renderDailyMissionTitle()` を呼ぶ

### JS関数
- `loadDailyMission()` / `saveDailyMission(data)` (data.js) — localStorage の読み書き（日付不一致時に自動リセット）
- `renderDailyMissionTitle()` (game.js) — タイトル画面のミッション表示更新
- `trackDailyMissionAttempt()` (game.js) — attempts++ → 達成判定 → XP付与 → オーバーレイ表示
- `closeDailyMissionOverlay()` (game.js) — オーバーレイ非表示

### 変更ファイル
- `data.js` — `KEYS.DAILY_MISSION`、`loadDailyMission()`、`saveDailyMission()`
- `game.js` — `renderDailyMissionTitle()`、`trackDailyMissionAttempt()`、`closeDailyMissionOverlay()`、イベントリスナー追加
- `index.html` — `#daily-mission-display` DOM追加、`#daily-mission-overlay` DOM追加
- `css/style.css` — `.daily-mission-*` スタイル追加
