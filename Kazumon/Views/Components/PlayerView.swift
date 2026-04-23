import SwiftUI

struct PlayerView: View {
    let appearance: CharacterAppearance
    let isAttacking: Bool
    let isHurt: Bool
    var level: Int = 1
    var isJoyPose: Bool = false

    // ★ レベルに応じた表示サイズ
    private var displaySize: CGFloat {
        switch level {
        case 1...4:   return 40   // 40%
        case 5...9:   return 60   // 60%
        case 10...19: return 80   // 80%
        default:      return 100  // 100%
        }
    }
    // ★ 内部では常に designSize で描画し、scaleEffect で縮小
    private let designSize: CGFloat = 100

    var body: some View {
        KennyCharacterView(
            appearance: appearance,
            size: designSize,
            isAttacking: isAttacking,
            isHurt: isHurt,
            isJoyPose: isJoyPose
        )
        .scaleEffect(displaySize / designSize)  // ← 0.8倍に縮小
        // scaleEffect は見た目だけ縮小し、レイアウトサイズは変わらないので
        // frame で実際の表示サイズに合わせる
        .frame(
            width: (designSize + designSize * 0.38) * (displaySize / designSize),
            height: (designSize + designSize * 0.32 * 0.8) * (displaySize / designSize)
        )
        // .border(.blue) // デバッグ
    }
}
