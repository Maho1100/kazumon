import SwiftUI

/// コンボ段階に応じた色を返す共通ヘルパー
/// ComboView・FloatingSparkleLayer 等で共用
enum ComboStyle {
    static func color(for combo: Int) -> Color {
        switch combo {
        case 0...4:   return .blue
        case 5...9:   return .orange
        case 10...14: return .red
        case 15...19: return .purple
        default:      return Color(red: 0.93, green: 0.79, blue: 0.30)
        }
    }
}
