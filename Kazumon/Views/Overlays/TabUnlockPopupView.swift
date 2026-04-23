import SwiftUI

struct TabUnlockPopupView: View {
    let tab: KazumonTab
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.7
    @State private var bgOpacity: Double = 0
    @State private var cardOpacity: Double = 0

    var body: some View {
        ZStack {
            // 背景（bgOpacityで制御）
            Color.black.opacity(0.4 * bgOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // カード
            VStack(spacing: 16) {
                Image(systemName: tab.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)

                Text("tab_unlock_title")
                    .font(.zenMaru(20, weight: .black))
                    .multilineTextAlignment(.center)

                Text(tab.label)
                    .font(.zenMaru(28, weight: .black))
                    .foregroundColor(.blue)

                Button {
                    HapticsManager.tap()
                    dismiss()
                } label: {
                    Text("tab_unlock_yay")
                        .font(.zenMaru(18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 180, height: 50)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(cardOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                bgOpacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
                cardOpacity = 1.0
            }
            HapticsManager.correct()
            SoundManager.shared.playLevelUp()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            cardOpacity = 0
            bgOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}
