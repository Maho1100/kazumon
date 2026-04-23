import Foundation

/// 島に植えた木
struct PlantedTree: Codable, Identifiable, Sendable {
    let id: UUID
    let plantedDate: Date
    var x: Double  // -0.5 〜 0.5 (島の幅比率)
    var y: Double  // -0.5 〜 0.5 (島の高さ比率)

    init(id: UUID = UUID(), plantedDate: Date = Date(), x: Double, y: Double) {
        self.id = id
        self.plantedDate = plantedDate
        self.x = x
        self.y = y
    }

    /// 経過日数
    var daysSincePlanted: Int {
        Calendar.current.dateComponents([.day], from: plantedDate, to: Date()).day ?? 0
    }

    /// 枯れた? (7日経過)
    var isWithered: Bool {
        daysSincePlanted >= 7
    }
}

/// 島の木システム設定
enum TreeConfig {
    static let lifetimeDays = 7        // 木の寿命(日)
    static let shopRefillDays = 3      // 補充間隔(日)
    static let shopMaxStock = 3        // 在庫上限
    static let islandMaxTrees = 100    // 島の最大本数
    static let costPerTree = 50        // 1本のコスト
    static let baseSlimeCount = 2      // ベースのスライム最大数
    static let slimePerTrees = 3       // X本ごとにスライム+1
    static let maxSlimeCount = 10      // スライム最大数
}
