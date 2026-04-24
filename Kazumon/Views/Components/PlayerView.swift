import SwiftUI

struct PlayerView: View {
    let appearance: CharacterAppearance
    let isAttacking: Bool
    let isHurt: Bool
    var level: Int = 1
    var playEntrance: Bool = false
    var isRunning: Bool = false
    var isJoyPose: Bool = false
    var facing: KennyCharacterView.Facing = .front

    private var displaySize: CGFloat {
        switch level {
        case 1...4:   return 40
        case 5...9:   return 60
        case 10...19: return 80
        default:      return 100
        }
    }
    private let designSize: CGFloat = 100

    var body: some View {
        KennyCharacterView(
            appearance: appearance,
            size: designSize,
            isAttacking: isAttacking,
            isHurt: isHurt,
            playEntrance: playEntrance,
            isRunning: isRunning,
            isJoyPose: isJoyPose,
            facing: facing
        )
        .scaleEffect(displaySize / designSize)
        .frame(
            width: (designSize + designSize * 0.38) * (displaySize / designSize),
            height: (designSize + designSize * 0.32 * 0.8) * (displaySize / designSize)
        )
    }
}
