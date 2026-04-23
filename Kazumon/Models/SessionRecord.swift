import Foundation

struct AnswerTimeLog: Codable, Sendable {
    let problemIndex: Int
    let isCorrect: Bool
    let elapsedSeconds: Double
}

struct SessionRecord: Codable, Identifiable, Sendable {
    let id: String
    let date: String
    let floor: Int
    let score: Int
    let correctCount: Int
    let totalCount: Int
    let maxCombo: Int
    let playTimeSeconds: Int
    let itemsEarned: [String]
    var answerTimeLogs: [AnswerTimeLog] = []

    init(
        date: String,
        floor: Int,
        score: Int,
        correctCount: Int,
        totalCount: Int,
        maxCombo: Int,
        playTimeSeconds: Int,
        itemsEarned: [String],
        answerTimeLogs: [AnswerTimeLog] = []
    ) {
        self.id = UUID().uuidString
        self.date = date
        self.floor = floor
        self.score = score
        self.correctCount = correctCount
        self.totalCount = totalCount
        self.maxCombo = maxCombo
        self.playTimeSeconds = playTimeSeconds
        self.itemsEarned = itemsEarned
        self.answerTimeLogs = answerTimeLogs
    }

    var accuracy: Int {
        guard totalCount > 0 else { return 0 }
        return Int(Double(correctCount) / Double(totalCount) * 100)
    }

    var playTimeFormatted: String {
        let m = playTimeSeconds / 60
        let s = playTimeSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
