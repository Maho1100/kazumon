import Foundation

struct PlayerStats {
    let speed: Double        // 平均回答速度スコア（0.0〜1.0・速いほど高い）
    let topFloor: Int        // 今週の最高フロア（生値）
    let maxCombo: Int        // 今週の最大コンボ（生値）
    let playDays: Int        // 今週のプレイ日数（生値）

    // ホーム表示用（0.0〜1.0正規化）
    var speedScore: Double { speed }
    var floorScore: Double { min(Double(topFloor) / 30.0, 1.0) }
    var comboScore: Double { min(Double(maxCombo) / 20.0, 1.0) }
    var daysScore:  Double { min(Double(playDays) / 7.0, 1.0) }

    // パワーレベル（0〜100）
    var powerLevel: Int {
        let floor: Double = 0.15
        let s = max(speedScore, floor)
        let f = max(floorScore, floor)
        let c = max(comboScore, floor)
        let d = max(daysScore, floor)
        let avg = (s + f + c + d) / 4.0
        return Int(avg * 100)
    }

    // 平均回答秒数（表示用）
    var avgSeconds: Double {
        (1.0 - speed) * 10.0
    }

    static func calculate(
        player: PlayerData,
        sessions: [SessionRecord],
        mistakes: [MistakeEntry]
    ) -> (current: PlayerStats, previous: PlayerStats) {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        let now = Date()

        let thisWeek = sessions.filter { s in
            guard let d = f.date(from: s.date) else { return false }
            return now.timeIntervalSince(d) <= 60 * 60 * 24 * 7
        }
        let lastWeek = sessions.filter { s in
            guard let d = f.date(from: s.date) else { return false }
            let interval = now.timeIntervalSince(d)
            return interval > 60 * 60 * 24 * 7 && interval <= 60 * 60 * 24 * 14
        }

        return (
            current:  buildStats(sessions: thisWeek),
            previous: buildStats(sessions: lastWeek)
        )
    }

    private static func buildStats(sessions: [SessionRecord]) -> PlayerStats {
        // 平均回答時間（速いほどスコア高い）
        let allTimes = sessions.flatMap { $0.answerTimeLogs.map { $0.elapsedSeconds } }
        let avgTime = allTimes.isEmpty ? 5.0 : allTimes.reduce(0, +) / Double(allTimes.count)
        let speedScore = max(0, 1.0 - (avgTime / 10.0))

        // 今週最高フロア
        let topFloor = sessions.map { $0.floor }.max() ?? 0

        // 今週最大コンボ
        let maxCombo = sessions.map { $0.maxCombo }.max() ?? 0

        // 今週プレイ日数（重複なし）
        let playDays = Set(sessions.map { $0.date }).count

        return PlayerStats(
            speed:    speedScore,
            topFloor: topFloor,
            maxCombo: maxCombo,
            playDays: playDays
        )
    }
}
