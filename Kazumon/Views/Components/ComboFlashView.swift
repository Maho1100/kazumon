import SwiftUI

/// コンボ5・10・15・20到達時に画面全体を一瞬光らせるフラッシュ演出
struct ComboFlashView: View {
    let combo: Int

    @State private var opacity: Double = 0
    @State private var lastFlashedCombo: Int = 0

    private static let milestones: Set<Int> = [5, 10, 15, 20]

    var body: some View {
        Color(ComboStyle.color(for: combo))
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onChange(of: combo) { _, new in
                guard Self.milestones.contains(new), new != lastFlashedCombo else { return }
                lastFlashedCombo = new
                let peak = new >= 20 ? 0.35 : 0.2
                // フェードイン 0.08秒
                withAnimation(.easeIn(duration: 0.08)) {
                    opacity = peak
                }
                // フェードアウト 0.25秒
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        opacity = 0
                    }
                }
            }
    }
}
