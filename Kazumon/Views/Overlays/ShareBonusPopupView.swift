import SwiftUI

struct ShareBonusPopupView: View {
    let isPro: Bool
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text("🎁")
                    .font(.system(size: 56))

                Text("share_bonus_thanks")
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(.black)

                if !isPro {
                    VStack(spacing: 4) {
                        Text("share_bonus_play_plus1")
                            .font(.zenMaru(18, weight: .bold))
                            .foregroundColor(.orange)
                        Text("share_bonus_play_more")
                            .font(.zenMaru(14, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                } else {
                    Text("share_bonus_pro_thanks")
                        .font(.zenMaru(14, weight: .regular))
                        .foregroundColor(.gray)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("share_bonus_yay")
                        .font(.zenMaru(18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.orange)
                        )
                }
            }
            .padding(32)
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
