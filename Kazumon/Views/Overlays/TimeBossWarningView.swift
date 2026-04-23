import SwiftUI

/// じかんどろぼう予告フルスクリーン演出（Day10クリア後）
struct TimeBossWarningView: View {
    let onDismiss: () -> Void

    @State private var bgOpacity: Double = 0
    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0
    @State private var line3Opacity: Double = 0
    @State private var dismissed = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .opacity(bgOpacity)

            VStack(spacing: 20) {
                Text("time_boss_warning_1")
                    .font(.zenMaru(20, weight: .bold))
                    .foregroundStyle(.cyan)
                    .multilineTextAlignment(.center)
                    .opacity(line1Opacity)

                Text("time_boss_warning_2")
                    .font(.zenMaru(20, weight: .bold))
                    .foregroundStyle(.cyan.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(line2Opacity)

                Text("time_boss_warning_3")
                    .font(.zenMaru(22, weight: .black))
                    .foregroundStyle(.white)
                    .opacity(line3Opacity)
            }
            .padding(.horizontal, 32)
        }
        .onTapGesture { dismiss() }
        .onAppear {
            SoundManager.shared.fadeOutBGM(duration: 0.5)

            withAnimation(.easeIn(duration: 0.5)) { bgOpacity = 1 }
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) { line1Opacity = 1 }
            withAnimation(.easeIn(duration: 0.5).delay(2.5)) { line2Opacity = 1 }
            withAnimation(.easeIn(duration: 0.5).delay(3.5)) { line3Opacity = 1 }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { dismiss() }
        }
    }

    private func dismiss() {
        guard !dismissed else { return }
        dismissed = true
        withAnimation(.easeOut(duration: 0.5)) {
            bgOpacity = 0; line1Opacity = 0; line2Opacity = 0; line3Opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDismiss() }
    }
}
