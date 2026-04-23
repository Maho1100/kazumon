import Foundation

struct MistakeEntry: Codable, Identifiable, Sendable {
    var id: String { "\(a)+\(b)" }
    let a: Int
    let b: Int
    let answer: Int
    let wrongAnswer: Int
    var reviewCount: Int = 0
    var lastReviewDate: String?
}
