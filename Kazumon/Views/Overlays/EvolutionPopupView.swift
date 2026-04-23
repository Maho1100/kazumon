import SwiftUI

struct EvolutionPopupView: View {
    let stage: CharacterEvolutionStage
    let appearance: CharacterAppearance
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5

    private let textDark  = Color(red: 0.18, green: 0.22, blue: 0.28)
    private let goldColor = Color(red: 0.93, green: 0.79, blue: 0.30)

    var body: some View {
        ZStack {
            // 半透明オーバーレイ
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            // 進化カード
            VStack(spacing: 14) {
                Text("view_overlay_evolved")
                    .font(.zenMaru(26, weight: .black))
                    .foregroundColor(goldColor)

                Text(stage.displayName)
                    .font(.zenMaru(15, weight: .bold))
                    .foregroundColor(.secondary)

                // 進化後のキャラ
                KennyCharacterView(
                    appearance: appearance,
                    size: 100,
                    playEntrance: true
                )
                .padding(.vertical, 4)

                Text("view_overlay_evolved_stronger")
                    .font(.zenMaru(15, weight: .bold))
                    .foregroundColor(textDark)

                Button(action: dismiss) {
                    Text("OK")
                        .font(.zenMaru(18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 140, height: 48)
                        .background(goldColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
            .scaleEffect(scale)
        }
        .onAppear {
            HapticsManager.correct()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.01
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}
