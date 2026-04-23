import Foundation

enum GameScreen {
    case title
    case island        // 島ホームワールド
    case battle
    case result
    case collection
    case extraSelect   // BOSS選択画面
    case extraBattle   // エクストラバトル
    case extraResult   // エクストラリザルト
}

enum BattlePhase {
    case answering
    case correct
    case incorrect
    case confirmCorrect   // 不正解後、正解タップ待ち
    case defeating
    case evolving         // バトル中進化演出
    case bossAppearing
    case gameOver
    case levelUp
}
