# Kazumon — Claude Code 開発ルール

> コードを書く前に必ず読むこと。

---

## プロジェクト概要
- **アプリ名:** かずもん (Kazumon)
- **対象:** 4-8歳の算数学習RPG
- **ミッション:** 1日5分、30日で1年生の算数をマスター
- **プラットフォーム:** iOS 17.6+, SwiftUI, SpriteKit不使用

---

## 設計ドキュメント（この順序で参照）

| 順序 | ファイル | いつ読む | 何が書いてある |
|------|---------|---------|-------------|
| 1 | `GAME_VISION.md` | 判断に迷った時 | ミッション・やらないこと・判断基準3つ |
| 2 | `PLAYER_EXPERIENCE.md` | 体験を設計する時 | 年齢別体験・感情マップ・離脱対策 |
| 3 | `GAME_DESIGN_CHECKLIST.md` | 機能を評価する時 | 心理要素8つ・NGパターン10個・現状チェック表 |
| 4 | `FEATURE_TEMPLATE.md` | 新機能を追加する時 | やらない判断→設計チェック→技術チェック→実装 |
| 5 | `CLAUDE.md`（このファイル） | コードを書く時 | 技術制約・ファイル構成・既知の制約 |
| - | `ART_DIRECTION.md` | デザイン・UI追加時 | アートスタイル・キャラルール・UI規格・カラーパレット |
| - | `ANALYTICS_DESIGN.md` | 計測追加時 | イベント設計・パラメータ・GA4分析例・実装タスク |

**ルール:** 新機能追加時は必ず FEATURE_TEMPLATE.md を埋めてから実装する。機能追加後は GAME_DESIGN_CHECKLIST.md の現状チェック表を更新する。

## 必須チェックリスト（修正前に確認）

### 1. KennyCharacterView アニメーション
- [ ] `if let` 分岐禁止 → 常在ビュー + `.opacity()` で表示制御
- [ ] faceLayer は detailLayer / eyeLayer / noseAndMouthLayer に分割済み（TupleView 10要素上限）
- [ ] 各サブレイヤーのビュー数が10以下か確認
- [ ] KennyCharacterView の外側で `withAnimation` / `.animation(value:)` を使わない
- [ ] `.drawingGroup()` を使わない（クリッピング問題）
- [ ] 値変更は即時（charTapped, charOffsetX 等）

### 2. SpriteView
- [ ] 常在 Image + `.opacity()` パターン（overlay内のif letはOK）
- [ ] `if let` でビューツリーを変えない

### 3. 多言語対応
- [ ] UI に表示する日本語テキストは全て `NSLocalizedString()` で囲む
- [ ] `en.lproj/Localizable.strings` と `ja.lproj/Localizable.strings` 両方に追加
- [ ] DEBUGブロック内のテキストは対応不要

### 4. IslandWorldView レイアウト
- [ ] オーバーレイ系ビューは `.frame(width: w, height: h).position(x: w/2, y: h/2)` で配置
- [ ] `.safeAreaPadding()` は使わない（幅が膨らむ）
- [ ] 球体パラメータはDEBUGスライダーで調整可能に保つ

### 5. データ保存
- [ ] DataStore の `pk()` プレフィックスでプロファイル別保存
- [ ] Item に新プロパティ追加時は `init(from decoder:)` で `decodeIfPresent` + デフォルト値
- [ ] 新アイテム/色/ショップ追加時は既存データに影響しないことを確認

### 6. きせかえ
- [ ] 色変更は `DataStore.saveSelectedBodyColor()` で保存
- [ ] `CharacterAppearanceFactory` が `loadSelectedBodyColor()` + `loadSelectedDetailType()` を参照
- [ ] IslandWorldView のキャラに `.id(DataStore.loadSelectedBodyColor() + DataStore.loadSelectedDetailType())` 付き
- [ ] ショップ内で `gameVM.refreshTrigger += 1` は戻るボタン時のみ（色選択時は不要）

### 7. タップフィードバック
- [ ] 新しいボタンや選択肢には必ず `HapticsManager.tap(); SoundManager.shared.playTap()` を追加
- [ ] 正解時は `HapticsManager.correct(); SoundManager.shared.playCorrect()`
- [ ] 不正解時は `HapticsManager.incorrect(); SoundManager.shared.play("sfx_wrong", volume: 0.5)`

### 8. ビルド確認
- [ ] `xcodebuild` でBUILD SUCCEEDEDを確認してから報告

---

## ファイル構成（主要）

```
Kazumon/
├── Views/
│   ├── IslandWorldView.swift      # 島ホーム（球体回転マップ）
│   ├── StartScreenView.swift      # スタート画面
│   ├── BattleShopView.swift       # バトル店内
│   ├── KisekaeShopView.swift      # きせかえショップ
│   ├── KoukanShopView.swift       # 交換所
│   ├── BattleView.swift           # バトル画面
│   ├── Young4BattleView.swift     # 4歳モードバトル
│   ├── TitleView.swift            # 旧タイトル（olderHomeView等）
│   └── Components/
│       ├── KennyCharacterView.swift  # キャラ描画（アニメ注意）
│       ├── SpriteView.swift          # スプライト描画
│       └── CharacterEyeView.swift    # 目描画
├── Models/
│   ├── CharacterAppearanceFactory.swift  # レベル+色→外見
│   ├── CharacterPartOffsets.swift        # ボディ別パーツ位置
│   ├── CharacterAppearance.swift         # 外見データ
│   ├── IslandState.swift                 # 島状態
│   ├── Item.swift                        # アイテム（Codable互換注意）
│   └── GameState.swift                   # 画面遷移enum
├── ViewModels/
│   └── GameViewModel.swift        # ゲームロジック
├── Services/
│   ├── DataStore.swift            # データ保存（pk()プレフィックス）
│   └── AnalyticsManager.swift     # Firebase Analytics
└── Debug/
    └── DebugPanelView.swift       # デバッグ画面
```

---

## 画面遷移

```
.title (StartScreenView)
  ↓ 「ぼうけんにいく！」
.island (IslandWorldView)
  ↓ バトル建物タップ → 入店演出
  BattleShopView (fullScreenCover)
    → モード選択 → 難易度 → 問題タイプ → startGame()
  ↓
.battle (BattleView / Young4BattleView)
  ↓ endGame()
.result (ResultView / YoungResultView)
  ↓ returnToTitle()
.island
```

---

## 既知の制約

- KennyCharacterView の外からの `withAnimation` は内部 `repeatForever` を殺す
- GeometryReader は `.offset()` のアニメーション値を読めない
- `.ignoresSafeArea()` 環境では ZStack の中心がスクリーン中心とずれる
- 4歳モードはバトル選択をスキップして直接 `startGame(difficulty: .easy)`
- コイン報酬: バトル終了時に `(floor-1) × 10 + score ÷ 10`

---

## ストーリー設定（未実装・参照用）

- 概要: `GAME_VISION.md` → 世界観セクション
- 詳細: `memory/project_story_draft.md`
- テーマ: 「さんすうは、きみの ちょうのうりょくだ。」
