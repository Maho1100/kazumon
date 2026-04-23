import SwiftUI

/// バトル中専用の軽い進化演出オーバーレイ
struct EvolutionBattleOverlay: View {
    let newStage: CharacterEvolutionStage

    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8
    @State private var ripple1: Double = 0
    @State private var ripple2: Double = 0

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3 * opacity)
                .ignoresSafeArea()

            // 光の波紋1
            Circle()
                .stroke(Color.yellow.opacity(0.6 * (1 - ripple1)), lineWidth: 3)
                .scaleEffect(1 + ripple1 * 2)
                .frame(width: 80, height: 80)

            // 光の波紋2（遅延）
            Circle()
                .stroke(Color.orange.opacity(0.4 * (1 - ripple2)), lineWidth: 2)
                .scaleEffect(1 + ripple2 * 2)
                .frame(width: 80, height: 80)

            // メインテキスト
            VStack(spacing: 4) {
                Text("battle_evolution")
                    .font(.zenMaru(24, weight: .black))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 4)
                Text(newStage.displayName)
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
                scale = 1
            }
            // 波紋1
            withAnimation(.easeOut(duration: 1.2)) {
                ripple1 = 1
            }
            // 波紋2（少し遅延）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 1.2)) {
                    ripple2 = 1
                }
            }
        }
    }
}
