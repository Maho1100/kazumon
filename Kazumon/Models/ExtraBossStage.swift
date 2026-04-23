import Foundation

/// エクストラモードで選択可能なBOSSステージ定義
struct ExtraBossStage: Identifiable {
    let id: Int              // ステージ番号（1〜6）
    let floor: Int           // 対応するフロア（5/10/15/20/25/30）
    let timeLimit: Double    // 制限時間（秒）
    let requiredFloor: Int   // 解放に必要な bestFloor

    /// このステージのベスト正解数
    var bestCorrect: Int {
        DataStore.loadExtraRecord().bestCorrectByStage[id] ?? 0
    }

    /// 解放済みかどうか
    func isUnlocked(bestFloor: Int) -> Bool {
        bestFloor >= requiredFloor
    }

    static let allStages: [ExtraBossStage] = [
        ExtraBossStage(id: 1, floor: 5,  timeLimit: 60, requiredFloor: 5),
        ExtraBossStage(id: 2, floor: 10, timeLimit: 60, requiredFloor: 10),
        ExtraBossStage(id: 3, floor: 15, timeLimit: 60, requiredFloor: 15),
        ExtraBossStage(id: 4, floor: 20, timeLimit: 60, requiredFloor: 20),
        ExtraBossStage(id: 5, floor: 25, timeLimit: 60, requiredFloor: 25),
        ExtraBossStage(id: 6, floor: 30, timeLimit: 60, requiredFloor: 30),
    ]
}
