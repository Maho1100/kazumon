import Foundation

/// エクストラモードのステージごとベストスコア
struct ExtraRecord: Codable {
    var bestCorrectByStage: [Int: Int] = [:]
    // key: ExtraBossStage.id / value: 最高正解数
}
