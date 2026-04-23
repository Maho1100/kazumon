import Foundation

struct MagicTimeConfig {
    static let defaultStartHour = 18
    static let timeBossTriggerCount = 7  // この回数プレイでじかんどろぼう出現

    static func isMagicTime(start: Int = defaultStartHour, end: Int = (defaultStartHour + 1) % 24) -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        if start < end {
            return hour >= start && hour < end
        } else {
            // 例: 22:00〜2:00 のような日跨ぎ
            return hour >= start || hour < end
        }
    }

    static let speeches: [String] = [
        NSLocalizedString("magic_time_speech_1", comment: ""),
        NSLocalizedString("magic_time_speech_2", comment: ""),
        NSLocalizedString("magic_time_speech_3", comment: ""),
        NSLocalizedString("magic_time_speech_4", comment: ""),
        NSLocalizedString("magic_time_speech_5", comment: ""),
    ]
}
