import SwiftUI

struct GameOverOverlay: View {
    var reason: ExtraFinishReason = .timeUp
    @State private var opacity: Double = 0

    private var title: String {
        switch reason {
        case .timeUp:   return NSLocalizedString("overlay_gameover_timeup", comment: "")
        case .lifeZero: return NSLocalizedString("overlay_gameover_goodjob", comment: "")
        case .quit:     return NSLocalizedString("overlay_gameover_quit", comment: "")
        }
    }

    private var subtitle: String {
        switch reason {
        case .timeUp:   return NSLocalizedString("overlay_gameover_timeup_sub", comment: "")
        case .lifeZero: return NSLocalizedString("overlay_gameover_life_sub", comment: "")
        case .quit:     return ""
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            KennyCharacterView(appearance: .kazu, size: 90, isHurt: reason == .lifeZero)

            Text(title)
                .font(.zenMaru(28, weight: .black))
                .foregroundColor(reason == .lifeZero ? .orange : .yellow)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.zenMaru(16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .foregroundColor(.white)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
        }
    }
}
