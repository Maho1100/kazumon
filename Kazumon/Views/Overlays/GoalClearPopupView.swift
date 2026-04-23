import SwiftUI

struct GoalClearPopupView: View {
    let onFinish: () -> Void
    let onContinue: () -> Void

    @State private var scale: CGFloat = 0.7
    @State private var bgOpacity: Double = 0
    @State private var cardOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4 * bgOpacity)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 48))

                Text("goal_clear_title")
                    .font(.zenMaru(24, weight: .black))
                    .multilineTextAlignment(.center)

                Text("goal_clear_subtitle")
                    .font(.zenMaru(16, weight: .bold))
                    .foregroundColor(.secondary)

                VStack(spacing: 10) {
                    Button {
                        HapticsManager.tap()
                        dismiss {
                            onFinish()
                        }
                    } label: {
                        Text("goal_clear_finish")
                            .font(.zenMaru(18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        HapticsManager.tap()
                        dismiss {
                            onContinue()
                        }
                    } label: {
                        Text("goal_continue")
                            .font(.zenMaru(16, weight: .bold))
                            .foregroundColor(.blue)
                            .frame(width: 200, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
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

    private func dismiss(completion: @escaping () -> Void) {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            cardOpacity = 0
            bgOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            completion()
        }
    }
}
