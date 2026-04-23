import SwiftUI

struct FloorBannerView: View {
    let floor: Int
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0

    var body: some View {
        Text("🏰 \(floor)F")
            .font(.zenMaru(48, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 36)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.85), .blue.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .purple.opacity(0.4), radius: 12, y: 4)
            .scaleEffect(scale)
            .opacity(opacity)
            .allowsHitTesting(false)
            .onAppear {
                // Phase 1: Scale up + fade in
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 1.1
                    opacity = 1.0
                }
                // Phase 2: Settle
                withAnimation(.easeInOut(duration: 0.15).delay(0.3)) {
                    scale = 1.0
                }
                // Phase 3: Fade out
                withAnimation(.easeIn(duration: 0.25).delay(0.55)) {
                    opacity = 0
                }
            }
    }
}
