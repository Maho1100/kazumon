import Foundation

struct IslandState: Codable {
    var unlockedShops: Set<String> = ["bgm"]
    var islandLevel: Int = 1
}
