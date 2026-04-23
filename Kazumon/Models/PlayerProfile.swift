import Foundation

/// マルチアカウント用プロフィール（最小データ）
struct PlayerProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var ageGroup: AgeGroup
    var avatarColor: String

    static let avatarColors = [
        "#5DCAA5", "#F0997B", "#85B7EB", "#EF9F27", "#AFA9EC", "#E24B4A"
    ]

    static func newProfile(name: String, ageGroup: AgeGroup, colorIndex: Int) -> PlayerProfile {
        PlayerProfile(
            id: UUID(),
            name: name,
            ageGroup: ageGroup,
            avatarColor: avatarColors[colorIndex % avatarColors.count]
        )
    }
}
