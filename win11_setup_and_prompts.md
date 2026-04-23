# カズモン開発 — Windows 11 セットアップ & Claude Code プロンプト集
# ============================================================================


# ============================================================================
# 【パート1】Windows 11 開発環境セットアップ（約30分）
# ============================================================================
#
# Claude Codeを使うには2つの方法があります：
#
#   方法A: WSL（Windows Subsystem for Linux）を使う ← おすすめ
#   方法B: Git Bashで直接使う（ネイティブWindows）
#
# 安定性と情報の多さから【方法A: WSL】を強く推奨します。
# 以下はすべて方法Aの手順です。
#
# ============================================================================


# ────────────────────────────────────────────
# STEP 1: WSLをインストール（初回のみ、5分）
# ────────────────────────────────────────────
#
# ① PowerShell を「管理者として実行」で開く
#    （スタートボタン右クリック →「ターミナル（管理者）」）
#
# ② 以下のコマンドを実行：

wsl --install

# ③ PCを再起動する（必須）
#
# ④ 再起動後、自動でUbuntuのウィンドウが開く
#    ユーザー名とパスワードを設定する（覚えておく！）
#
# ⚠️ 既にWSLが入っている場合はこのステップはスキップ


# ────────────────────────────────────────────
# STEP 2: WSL内にNode.jsをインストール（5分）
# ────────────────────────────────────────────
#
# ① Ubuntuターミナルを開く
#    （スタートメニューで「Ubuntu」と検索）
#
# ② 以下のコマンドを順番に実行：

# Node.jsのバージョン管理ツール(nvm)をインストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# ターミナルを閉じて開き直す（またはこれを実行）
source ~/.bashrc

# Node.js 22（LTS）をインストール
nvm install 22

# 確認（バージョン番号が出ればOK）
node --version
npm --version


# ────────────────────────────────────────────
# STEP 3: Claude Codeをインストール（5分）
# ────────────────────────────────────────────
#
# Ubuntuターミナルで以下を実行：

# ネイティブインストーラーでインストール（推奨）
curl -fsSL https://claude.ai/install.sh | sh

# 確認
claude --version

# もし上記がうまくいかない場合はnpmで：
# npm install -g @anthropic-ai/claude-code

# ⚠️ sudo は使わないこと！


# ────────────────────────────────────────────
# STEP 4: Gitの初期設定（3分）
# ────────────────────────────────────────────

git config --global user.name "あなたの名前"
git config --global user.email "your-email@example.com"


# ────────────────────────────────────────────
# STEP 5: プロジェクトフォルダを作る（2分）
# ────────────────────────────────────────────
#
# WSL内で作業するのがポイント。
# WindowsのCドライブにアクセスすることもできますが、
# WSL内のホームディレクトリで作業するのが高速です。

# ホームディレクトリに移動
cd ~

# プロジェクトフォルダを作成
mkdir kazumon
cd kazumon

# Git初期化
git init

# ここに先ほどダウンロードしたCLAUDE.mdをコピーする（方法は下記参照）


# ────────────────────────────────────────────
# STEP 6: CLAUDE.mdをWSLにコピーする（2分）
# ────────────────────────────────────────────
#
# 方法1: WindowsのエクスプローラーからWSLにアクセス
#   エクスプローラーのアドレスバーに以下を入力：
#     \\wsl$\Ubuntu\home\（ユーザー名）\kazumon\
#   ここにCLAUDE.mdをドラッグ＆ドロップ
#
# 方法2: コマンドでコピー（CLAUDE.mdがダウンロードフォルダにある場合）

cp /mnt/c/Users/（Windowsのユーザー名）/Downloads/CLAUDE.md ~/kazumon/CLAUDE.md

# ファイルが存在するか確認
cat ~/kazumon/CLAUDE.md | head -5


# ────────────────────────────────────────────
# STEP 7: Claude Codeを起動してログイン（3分）
# ────────────────────────────────────────────

cd ~/kazumon
claude

# 初回起動時に聞かれること：
#
# 1. テーマ選択 → お好みで（Darkがおすすめ）
#
# 2. ログイン方法の選択：
#    > 1. Claude account with subscription ← Pro/Maxプランの人はこっち
#    > 2. Anthropic Console account        ← API従量課金の人はこっち
#
#    ブラウザが自動で開くので、Anthropicアカウントでログイン
#
# 3. ディレクトリへのアクセス許可 → 「Yes, proceed」を選択
#
# ✅ これでClaude Codeが使える状態になりました！


# ────────────────────────────────────────────
# STEP 8: VS Codeとの連携（任意、おすすめ）
# ────────────────────────────────────────────
#
# VS Codeを使っている場合、WSL内のファイルを直接編集できます：
#
# ① VS Codeの拡張機能「WSL」をインストール
# ② Ubuntuターミナルでプロジェクトフォルダに移動
# ③ 以下を実行するとVS Codeが開く：

code .

# これでVS Codeで編集しながら、
# 別のターミナルでClaude Codeを動かせます。


# ────────────────────────────────────────────
# STEP 9: ブラウザでの動作確認方法
# ────────────────────────────────────────────
#
# WSL内で作ったHTMLをWindowsのブラウザで確認するには：
#
# 方法1: エクスプローラーから直接開く
#   エクスプローラーで \\wsl$\Ubuntu\home\（ユーザー名）\kazumon\index.html
#   をダブルクリック
#
# 方法2: WSLからWindowsのブラウザを開く

explorer.exe index.html

# 方法3: 簡易HTTPサーバーを立てる（おすすめ。音声やlocalStorageが確実に動く）

npx serve .
# → http://localhost:3000 にアクセス
# ※ Ctrl+C で停止


# ============================================================================
# 【パート2】Claude Code プロンプト集（ステップ0〜10）
# ============================================================================
#
# Claude Codeが起動している状態で、
# 以下のプロンプトを【1つずつ】コピペして実行してください。
#
# 💡 ヒント:
#   - 1つのステップが完了したら、ブラウザで動作確認してから次に進む
#   - うまくいかない場合は「〜が動きません。修正してください」と伝えればOK
#   - /clear で会話をリセットできる（長くなったら使う）
#   - /compact で会話を圧縮できる（トークン節約）
#
# ============================================================================


# ============================================
# ステップ0: プロジェクト初期化（5分）
# ============================================

"""
CLAUDE.mdを読んでプロジェクトの概要を把握してください。
その上で、以下のファイル構成を作成してください：

kazumon/
  index.html
  css/style.css
  js/game.js
  js/sound.js
  js/data.js
  js/animation.js
  img/（空フォルダ。.gitkeepを入れておく）

index.htmlには以下の5つの画面をdivで定義してください：
- #title-screen（タイトル画面）
- #battle-screen（バトル画面）
- #defeat-overlay（撃破演出オーバーレイ）
- #boss-overlay（ボス登場演出オーバーレイ）
- #result-screen（リザルト画面）

最初は #title-screen だけ visible で、他は display:none にしてください。
CSSとJSファイルは中身は空でいいので、正しくリンクしてください。
Google Fonts から "Zen Maru Gothic" をインポートしてください。

viewportメタタグを必ず入れてください：
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
"""

# → 完了したら explorer.exe index.html でブラウザ確認


# ============================================
# ステップ1: タイトル画面（20分）
# ============================================

"""
CLAUDE.mdの「画面A: タイトル画面」の仕様に従って、タイトル画面を作ってください。

具体的な要素：
1. 「カズモン」のテキストロゴ
   - font-size: 56px、太字
   - 文字色: グラデーション（#FF6B6B → #4ECDC4）
   - text-shadow で影をつける
   - 上下にゆっくり浮遊するアニメーション

2. メインキャラ「カズ」
   - SVG画像がないので、CSSだけで丸いキャラクターを作る
   - 青色(#4299E1)の丸（100×100px）
   - 中に白い目（2つの小さな丸）と口（小さなアーチ）
   - idleアニメーション（上下にゆっくり揺れる、2秒周期）

3. 「スタート」ボタン
   - 200px×70px、背景色 #E53E3E、白文字、font-size: 28px
   - border-radius: 16px
   - box-shadow: 0 4px 15px rgba(229, 62, 62, 0.4)
   - パルスアニメーション（1.5秒周期でscale 1.0→1.05→1.0）
   - タップ時にscale(0.95)のフィードバック

4. 情報表示
   - 右上: 「さいこうきろく：▲ 0F」（font-size: 14px）
   - 左上: 🔥「0にちれんぞく」（font-size: 14px）
   - 右上角: 🔊音声トグルボタン（30×30px）

5. スタイル
   - 背景: linear-gradient(135deg, #E8F4FD 0%, #F0E6FF 100%)
   - フォント: "Zen Maru Gothic", sans-serif
   - max-width: 480px、margin: 0 auto
   - min-height: 100vh（画面いっぱい）
   - 全テキストはひらがな・カタカナのみ。漢字は使わない

「スタート」ボタンをクリックしたら console.log("ゲームかいし") が出るところまで。
"""

# → 完了したら npx serve . でブラウザ確認


# ============================================
# ステップ2: バトル画面のレイアウト（30分）
# ============================================

"""
CLAUDE.mdの「画面B: バトル画面」に従って、バトル画面のHTML/CSSを作ってください。

レイアウト（上から順に）：

1. ステータスバー（上部、横並び）
   - 左: 「▲ 1F」（font-size: 28px、bold、色 #2D3748）
   - 中央: 「スコア: 0」（font-size: 16px）
   - 右: 空（将来のメニュー用）

2. HPバーエリア（2段）
   - 上段: ❤️ プレイヤーHP
     - ハートアイコン + 「HP」ラベル + プログレスバー（緑 #48BB78）
     - 数字表示「3/3」
   - 下段: 👿 モンスターHP
     - モンスター名 + プログレスバー（赤 #F56565）
   - バーはborder-radius: 10px の角丸。背景#E2E8F0、width: 100%

3. バトルフィールド（中央エリア）
   - 左: プレイヤーキャラ（CSSで作った青い丸キャラ 80×80px）
   - 右: モンスター（CSSで作った赤い丸キャラ 100×100px、目が怒っている）
     - idleアニメーション（左右にゆっくり揺れる）
   - 上: コンボ表示エリア（最初は非表示、表示時は「x3 COMBO!」）
   - フィールド背景: 薄い色のグラデーション（戦闘感を出す）

4. 問題表示エリア
   - 白い角丸ボックス（padding: 20px、border-radius: 16px、shadow付き）
   - 「3 + 5 = ?」を font-size: 44px の太字で中央表示
   - 「+」と「=」は薄い色(#718096)、数字は濃い色(#1A202C)

5. 選択肢エリア（下部）
   - display: grid、grid-template-columns: 1fr 1fr（2列）
   - gap: 12px、padding: 0 16px
   - 各ボタン:
     - min-height: 70px
     - background: #4299E1
     - color: white、font-size: 32px、font-weight: bold
     - border-radius: 12px
     - box-shadow: 0 4px 6px rgba(66, 153, 225, 0.3)
     - active時: transform: scale(0.95)、background: #3182CE

全体を max-width: 480px で中央配置。
ダミーデータ（3+5=?, 選択肢: 7, 8, 9, 6）をHTMLに直接書いてOK。
まだJSロジックは不要。見た目だけ完成させてください。
"""


# ============================================
# ステップ3: 問題生成ロジック（30分）
# ============================================

"""
js/game.js に問題生成ロジックを実装してください。
CLAUDE.mdの「問題生成ロジック」と「レベル設計」に従います。

実装する関数：

1. getDifficultyConfig(floor)
   - フロアに応じた [minA, maxA, minB, maxB, errorRange] を返す
   - 1-5F: [1,5,1,4,2]
   - 6-10F: [1,9,1,9,3]
   - 11-15F: [5,9,6,9,4]
   - 16-20F: [10,50,1,9,5]
   - 21-30F: [10,50,10,50,8]
   - 31F+: [1,99,1,99,10]
   - ボスフロア（5の倍数）はそのフロア帯の設定をそのまま使う

2. generateProblem(floor, mistakeLog)
   - 20%の確率で mistakeLog から復習問題を出す（あれば）
   - それ以外はフロアに応じた新問題を生成
   - 戻り値: { a, b, answer, choices, isReview }

3. generateChoices(answer, errorRange)
   - 正解を含む4つの選択肢を配列で返す
   - 誤答は answer±errorRange の範囲でランダム生成
   - 最小値は0以上（足し算の答えなので負にはならない）
   - 重複なし。正解と同じ値になったら再生成
   - Fisher-Yatesでシャッフル

4. getFloorConfig(floor)
   - 戻り値: { monsterHP, problemsNeeded, timeLimit, isBoss, monsterName }
   - monsterHP: 通常フロアは1（11F以降は2）、ボスは通常の3倍
   - problemsNeeded: monsterHPと同じ
   - timeLimit: 15F以下はnull、16-20Fは15秒、21-30Fは12秒、31F+はさらに短縮
   - isBoss: フロアが5の倍数ならtrue
   - monsterName: 「スライム」「ゴブリン」「ゴーレム」等をフロア帯で変える

テスト用に、以下をコンソールに出力してください：
- generateProblem(1) の結果
- generateProblem(10) の結果
- generateProblem(25) の結果
- getFloorConfig(5) の結果（ボス）
- getFloorConfig(7) の結果（通常）
"""


# ============================================
# ステップ4: ゲーム状態管理と中心ロジック（30分）
# ============================================

"""
js/game.js にゲームの状態管理とメインのバトルロジックを実装してください。

1. GameState オブジェクト:
   currentFloor, playerHP(3), playerMaxHP(3), monsterHP, monsterMaxHP,
   score, combo, maxCombo, correctCount, totalCount, currentProblem,
   startTime, isPlaying, isBossFloor, timeLimit, timerInterval,
   problemsInFloor, problemsNeeded, itemsObtained(配列)

2. 画面遷移:
   - showScreen(screenId): 指定画面をdisplay:flex、他をdisplay:none
   - 画面IDは 'title-screen', 'battle-screen', 'result-screen'

3. ゲームフロー関数:
   - startGame(): GameState初期化 → バトル画面表示 → startBattle()
   - startBattle(): フロアの設定を取得 → 問題生成 → UI更新
   - showProblem(): currentProblemの内容をバトル画面のDOMに反映
   - handleAnswer(selectedAnswer):
     正解の場合:
       - monsterHP -= 1
       - score += 10 × getComboMultiplier(combo)
       - combo += 1
       - maxCombo = Math.max(maxCombo, combo)
       - correctCount += 1
       - totalCount += 1
       - monsterHP <= 0 ならdefeatMonster()、そうでなければ次の問題
     不正解の場合:
       - playerHP -= 1
       - combo = 0
       - totalCount += 1
       - playerHP <= 0 ならgameOver()、そうでなければ次の問題
   - defeatMonster(): 撃破演出 → XP加算 → nextFloor()
   - nextFloor(): currentFloor++ → ボスチェック → startBattle()
   - gameOver(): プレイ時間計算 → リザルト画面に結果表示 → showScreen('result-screen')

4. コンボ倍率:
   function getComboMultiplier(combo):
   - 0-4: ×1
   - 5-9: ×2
   - 10-14: ×3
   - 15-19: ×4
   - 20+: ×5

5. イベントリスナー:
   - 「スタート」ボタン → startGame()
   - 選択肢ボタン4つ → handleAnswer(そのボタンの数字)
   - 「もういちど」ボタン → startGame()
   - 「おわる」ボタン → showScreen('title-screen')

6. UIの更新:
   - updateHP(): HPバーのwidthを更新（%で計算）
   - updateFloor(): フロア表示を更新
   - updateScore(): スコア表示を更新
   - updateCombo(): コンボ表示を更新

ここまでで、タイトル→バトル→選択肢クリック→正解/不正解判定→
モンスター撃破→次のフロア→HP0でリザルト の一連のフローが
console.logベースで確認できるようにしてください。
演出はまだ不要ですが、UIの数値（HP、スコア、フロア）は画面に反映してください。
"""


# ============================================
# ステップ5: 音声実装（20分）
# ============================================

"""
js/sound.js にWeb Audio APIで効果音を実装してください。
外部ファイルは使わず、すべてプログラムで音を生成します。

重要：AudioContextはユーザーの最初のタップイベントで初期化してください。
（ブラウザのautoplay policy対策）

let audioCtx = null;
function initAudio() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
}
→ 最初のボタンクリック時にinitAudio()を呼ぶ

実装する関数：

1. playCorrectSound()
   - サイン波。880Hz→1760Hzにスライドアップ。duration: 0.12秒。gain: 0.3
   - 「ピコン！」という気持ちいい音

2. playWrongSound()
   - サイン波。300Hz→200Hzにスライドダウン。duration: 0.15秒。gain: 0.2
   - 「ブッ」という低い音。不快ではなく「惜しい」感

3. playComboSound(comboCount)
   - 基本周波数: 440 + (comboCount × 40) Hz
   - duration: 0.1秒
   - コンボ5以上でオクターブ上の音を重ねる（ハーモニクス）

4. playDefeatSound()
   - ドミソの3音を順番に（523Hz, 659Hz, 784Hz）
   - 各音0.15秒、0.05秒間隔
   - gain: 0.3

5. playBossAppearSound()
   - 200Hz のスクエア波を4回繰り返し
   - 各音0.15秒、0.05秒間隔
   - gain: 0.25

6. playLevelUpSound()
   - ドレミファソ（523, 587, 659, 698, 784 Hz）を0.1秒間隔で
   - gain: 0.3

7. playTapSound()
   - 1000Hz、duration: 0.03秒、gain: 0.1
   - 軽いクリック感

8. isSoundEnabled() / toggleSound()
   - data.jsのsoundEnabled設定を見る
   - 全関数の先頭で !isSoundEnabled() なら即return

game.jsのhandleAnswer()、defeatMonster()等から適切な音を呼び出してください。
「スタート」ボタンのクリック時にinitAudio()を必ず呼んでください。
"""


# ============================================
# ステップ6: アニメーション実装（40分）
# ============================================

"""
js/animation.js と css/style.css にアニメーションを実装してください。
CLAUDE.mdの「演出設計」に準拠します。

すべてCSSクラスの追加/削除 + setTimeout で制御。
アニメーション中は選択肢ボタンに .disabled クラスを追加して
pointer-events: none にしてください。

1. playCorrectAnimation(buttonIndex, callback)
   全体0.8秒:
   - 選んだボタンに .correct クラス追加（背景#48BB78、scale(1.1)、0.2秒）
   - プレイヤーキャラに .attack クラス（translateY(-30px)→戻る、0.3秒）
   - モンスターに .hit クラス（shake: translateX(±5px)を3回、0.3秒）
   - HPバーのwidth をトランジションで更新
   - ダメージ数字「-1」をモンスター上に生成→fadeUpで消える
   - 0.8秒後にcallback()を呼ぶ（次の問題表示用）
   - 全クラスを0.8秒後に除去

2. playWrongAnimation(buttonIndex, correctIndex, callback)
   全体1.2秒:
   - 選んだボタンに .wrong クラス（背景#F56565、0.3秒）
   - 正解ボタンに .show-correct クラス（背景#48BB78で点滅、1秒）
   - モンスターに .monster-attack クラス（translateX(-20px)→戻る、0.3秒）
   - プレイヤーHPバーのwidth をトランジション更新
   - 「おしい！」テキストを画面中央に表示→0.5秒で消える
   - 1.2秒後にcallback()

3. updateComboDisplay(combo)
   - combo 0: コンボ要素を非表示
   - combo 1-4: 「x{combo}」を表示（普通のサイズ）
   - combo 5: 「x{combo} NICE!」+ .combo-nice クラス（オレンジ色、バウンス）
   - combo 10: 「x{combo} SUPER!」+ .combo-super（赤色、画面フラッシュ）
   - combo 15+: 「x{combo} AMAZING!」+ .combo-amazing（紫色、画面シェイク）

4. playDefeatAnimation(callback)
   全体2.0秒:
   - モンスターに .defeated クラス（scale 1→0、opacity 1→0、0.5秒）
   - パーティクル: 8個の小さな丸(.particle)を生成、
     CSSアニメーションで放射状に飛び散って消える
   - 「げきは！」テキストが中央にズームイン（scale 0→1、0.5秒、金色）
   - 「+{xp} XP」が浮き上がって消える
   - 1.5秒後に「つぎのフロアへ」ボタンをfadeInで表示
   - ボタンクリックでcallback()

5. playBossAppearAnimation(callback)
   全体1.5秒:
   - 画面にオーバーレイ（rgba(255,0,0,0.3)）がflash
   - 画面全体に .screen-shake クラス（0.5秒）
   - 「ボスとうじょう！」テキストがスライドイン（左から右）
   - 1.5秒後にcallback()

6. playGameOverAnimation()
   - 画面がゆっくり暗くなるオーバーレイ（0.5秒）
   - 「よくがんばった！」テキストがfadeIn
   - プレイヤーキャラに .wave クラス（手を振るような左右揺れ）

game.jsのhandleAnswer()から:
  正解→playCorrectAnimation→callback内で次の問題or撃破判定
  不正解→playWrongAnimation→callback内で次の問題orゲームオーバー判定
のように連携してください。
"""


# ============================================
# ステップ7: データ保存と間隔反復（20分）
# ============================================

"""
js/data.js にlocalStorageを使ったデータ管理を実装してください。
CLAUDE.mdの「localStorageデータ構造」に従います。

全関数をtry-catchで囲み、localStorageが使えなくてもクラッシュしないようにしてください。

1. saveUserData(data) / loadUserData()
   - key: "kazumon_user"
   - デフォルト値: { playerName:"", level:1, totalXP:0, bestFloor:0,
     bestScore:0, streakDays:0, lastPlayDate:"", totalPlayCount:0,
     totalCorrect:0, totalAnswered:0, soundEnabled:true }

2. saveItems(items) / loadItems()
   - key: "kazumon_items"
   - デフォルト: []

3. saveSessionHistory(session) / loadSessionHistory()
   - key: "kazumon_sessions"
   - 追加時に100件超えたら古いものを削除

4. saveMistakeLog(log) / loadMistakeLog()
   - key: "kazumon_mistakes"

5. updateStreak()
   - 今日の日付をYYYY-MM-DD形式で取得
   - lastPlayDateが昨日→streakDays+1
   - lastPlayDateが今日→そのまま
   - それ以外→streakDays=1にリセット
   - lastPlayDateを今日に更新

6. addMistake(a, b, wrongAnswer)
   - 既に同じ(a,b)の問題があればcount+1、nextReviewを更新
   - 新しければ追加
   - nextReview計算: count1=2分後、count2=翌日、count3+=3日後

7. getReviewProblems()
   - nextReviewが現在時刻より前のものをフィルタして返す

8. addXP(amount)
   - totalXP += amount
   - レベルアップ判定（累計XPに基づく）
   - 戻り値: { newLevel, leveledUp }
   - レベルテーブル: Lv2=100, Lv5=800, Lv10=2500, Lv20=8000, Lv50=50000, Lv100=200000
     （間のレベルは線形補間）

game.jsと連携:
- startGame()時: loadUserData()でストリーク・ベスト記録をタイトル画面に表示、updateStreak()
- handleAnswer()不正解時: addMistake()
- generateProblem()時: 20%でgetReviewProblems()から出題
- gameOver()時: saveUserData()（ベスト更新判定含む）、saveSessionHistory()
"""


# ============================================
# ステップ8: リザルト画面（20分）
# ============================================

"""
リザルト画面（#result-screen）を完成させてください。

デザイン:
- 背景: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
- max-width: 480px、中央配置

表示要素（上から順に）:
1. 「よくがんばった！」（白文字、32px）+ プレイヤーキャラのアニメーション

2. 記録カード（白い角丸ボックス、padding: 24px）:
   - 「▲ {maxFloor}F」を大きく表示（48px、太字）
   - 「スコア: {score}」（24px）
   - 「コンボさいだい: x{maxCombo}」（20px）
   - 「せいかいりつ: {correctRate}%」（20px）
   - 「プレイじかん: {minutes}ふん{seconds}びょう」（16px）

3. ベスト更新時のみ:
   - 「🎉 しんきろく！」（金色、パルスアニメーション）
   - 前回との差分「+{diff}F!」

4. 獲得アイテム（あれば）:
   - 「📦 ゲットしたアイテム」ヘッダー
   - アイテム名 + レア度バッジ
   - レア度の色: common=#A0AEC0, rare=#4299E1, epic=#9F7AEA, legendary=#ECC94B

5. ボタンエリア:
   - 「もういちど」: 180×60px、#E53E3E、白文字、パルスアニメーション
   - 「おわる」: 120×50px、白背景、灰色文字、小さめ

gameOver()から呼ばれた時に:
- リザルトデータをDOMに反映
- ベスト更新判定＆保存
- セッション履歴保存
- XP加算＆レベルアップ判定

「もういちど」→ startGame()
「おわる」→ showScreen('title-screen') + タイトル画面の記録表示を更新
"""


# ============================================
# ステップ9: アイテム・ボス・タイマーの統合（30分）
# ============================================

"""
以下の仕上げ機能を実装してください：

1. アイテムドロップシステム:
   ITEM_LIST を定義（20種類）:
   common(60%): ほのおのたま, みずのたま, かぜのたま, つちのたま, ひかりのたま,
                 きのえだ, いしころ, はっぱ, きのみ, ほしのかけら
   rare(25%): ほのおのけん, こおりのたて, いかずちのつえ, かぜのマント, だいちのゆびわ
   epic(10%): りゅうのうろこ, てんしのはね, まおうのかぎ
   legendary(5%): でんせつのけん, カズモンのたまご

   dropItem()関数: レア度を確率で決定→そのレア度からランダムに1つ選ぶ
   ボス撃破時に30%の確率で呼ぶ。通常ボスは30%、レア以上の確率UP
   ドロップ時は撃破演出内で宝箱アイコン+アイテム名を表示

2. ボス戦の完全実装:
   - 5の倍数フロアでplayBossAppearAnimation()を実行してからstartBattle()
   - ボスの見た目: モンスターのCSSキャラの色を変える
     5F=緑, 10F=青, 15F=紫, 20F=赤, 25F=黒, 30F=金
   - ボスはサイズ1.5倍（transform: scale(1.5)）
   - ボス撃破XPは通常の3倍

3. タイマー（16F以降）:
   - 問題表示と同時にカウントダウン開始
   - タイマーバーを問題表示エリアの下に追加
     （横長のプログレスバー、緑→黄→赤に色が変わる）
   - 残り3秒で赤色 + 点滅
   - 時間切れ = 不正解として handleAnswer(null) を呼ぶ
   - 回答したらタイマーをクリア

4. レベルアップ演出:
   - data.jsのaddXP()でleveledUp=trueが返ったら
   - playLevelUpSound()
   - 「レベルアップ！ Lv.{level}」を画面中央に1.5秒表示（金色、バウンス）

5. タイトル画面にレベル表示を追加:
   - キャラの下に「Lv.{level}」を表示
   - ストリーク、ベスト記録も保存データから反映

実装したら、1Fから10Fまで実際にプレイして全フローを確認してください。
バグがあれば修正してください。
"""


# ============================================
# ステップ10: 最終調整とデプロイ準備（20分）
# ============================================

"""
以下の最終調整を行ってください：

1. ビジュアル磨き:
   - 全ボタンに box-shadow を追加して立体感を出す
   - バトル画面の背景に微妙なグラデーション
   - モンスターの色をフロア帯で変える（1-5F=緑, 6-10F=青, 11-15F=紫, 16-20F=オレンジ, 21-30F=赤, 31F+=ダークグレー）
   - 正解時に画面全体が微かにフラッシュ（白いオーバーレイが0.1秒）
   - フロア移動時にスライドトランジション

2. バグ修正:
   - アニメーション中の連打防止（isAnimating フラグ）
   - HPが0以下にならないようにMath.max(0, hp)
   - localStorageのtry-catchが全箇所にあるか確認
   - AudioContext未初期化時のエラー防止
   - 0問目表示のバグ（startBattleの呼び出し順序）

3. UX改善:
   - 初回起動時に「なまえをいれてね」のプロンプト（シンプルなinput画面）
   - 名前は3〜8文字のひらがな・カタカナ
   - フロア移動時に「▲ 8F → ▲ 9F」のカウントアップ演出

4. アクセシビリティ:
   - 全ボタンにaria-label追加
   - 正解/不正解を色だけでなく「✓」「✗」アイコンでも表示
   - フォーカス時のアウトライン表示

5. パフォーマンス:
   - console.logをすべて削除（または if(DEBUG) で囲む）
   - CSSアニメーション要素にwill-change: transform, opacity追加

6. デプロイ準備:
   - .gitignore を作成（node_modules, .DS_Store等）
   - README.md を作成:
     「カズモン — 小学生向け算数タワーバトルゲーム」
     概要、遊び方、技術スタック、ライセンスを記載
   - git add -A && git commit -m "v1.0.0 カズモン MVP かんせい"

最後に npx serve . で起動して、以下を確認してください：
- タイトル画面が正しく表示されること
- スタート→バトル→5F(ボス)→撃破→リザルト の全フロー
- 音声が正しく鳴ること
- リザルト画面でスコアが表示されること
- 「もういちど」で再プレイできること
- タイトル画面にベスト記録が反映されること
"""


# ============================================================================
# 【パート3】トラブルシューティング
# ============================================================================

# ── WSLが起動しない ──
# PowerShell（管理者）で：
# wsl --update
# wsl --shutdown
# 再度 wsl と入力

# ── Claude Codeが起動しない ──
# Node.jsのバージョン確認:
# node --version （18以上が必要）
# Claude Codeの再インストール:
# npm uninstall -g @anthropic-ai/claude-code
# npm install -g @anthropic-ai/claude-code

# ── ブラウザで音が鳴らない ──
"""
音声が鳴りません。以下を確認・修正してください：
1. AudioContextがユーザーの最初のクリックイベント内でnew AudioContext()されているか
2. audioCtx.resume() が呼ばれているか
3. isSoundEnabled()がtrueを返しているか
4. gainノードのvalueが0になっていないか
Chrome DevToolsのConsoleにエラーが出ていないか確認してください。
"""

# ── レイアウトがスマホで崩れる ──
"""
スマホ（375px幅）でレイアウトが崩れます。以下を修正してください：
1. <meta name="viewport" content="width=device-width, initial-scale=1.0"> があるか
2. max-width: 480pxのコンテナ内に全要素が収まっているか
3. 選択肢ボタンが画面外にはみ出していないか（padding含めて幅計算）
4. font-sizeが小さすぎないか（最低でも16px）
5. touch-action: manipulation をボタンに追加（300msの遅延防止）
"""

# ── アニメーションがカクつく ──
"""
アニメーションがカクつきます。修正してください：
1. CSS animationのプロパティにwill-change: transform, opacityを追加
2. top/leftの変更をtranslateに置き換える
3. box-shadowのアニメーションを避ける（重い）
4. 大量のDOM要素の同時更新を避ける
"""

# ── ゲームバランスが悪い ──
"""
フロア{X}あたりで急に難しくなりすぎます。
getDifficultyConfig()を見直して、フロア{X-2}から{X+2}の範囲で
徐々に難易度が上がるように線形補間で調整してください。
具体的には、maxA, maxB の値をフロアに応じて
Math.floor(lerp(prevMax, nextMax, (floor - prevFloor) / (nextFloor - prevFloor)))
のように計算してください。
"""

# ── データが保存されない ──
"""
データが保存されません。以下を確認してください：
1. gameOver()でsaveUserData()とsaveSessionHistory()が呼ばれているか
2. DevToolsのApplication→Local Storageでkazumon_のキーがあるか
3. try-catchでエラーが握りつぶされていないか（catchでconsole.errorを出す）
4. シークレットモードで動かしていないか
"""
