import SwiftUI

struct StreakRewardPopupView: View {
    let milestone: Int
    let onClose: () -> Void

    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8

    private var bonusCount: Int {
        switch milestone {
        case 14: return 2
        case 30: return 3
        default: return 1
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 16) {
                Text("🔥")
                    .font(.system(size: 64))

                Text(String(format: NSLocalizedString("streak_reward_title", comment: ""), milestone))
                    .font(.zenMaru(24, weight: .bold))
                    .foregroundColor(.black)

                Text(String(format: NSLocalizedString("streak_reward_body", comment: ""), bonusCount))
                    .font(.zenMaru(15, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Button {
                    onClose()
                } label: {
                    Text("streak_reward_yay")
                        .font(.zenMaru(18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(duration: 0.4)) {
                    opacity = 1
                    scale = 1
                }
            }
        }
        .zIndex(300)
    }
}
