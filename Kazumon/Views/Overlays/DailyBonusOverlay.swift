import SwiftUI

struct DailyBonusOverlay: View {
    let xp: Int
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 20) {
            Text("🌟")
                .font(.system(size: 60))

            Text("view_overlay_daily_bonus")
                .font(.zenMaru(22, weight: .bold))

            Text("+\(xp)XP")
                .font(.zenMaru(36, weight: .black))
                .foregroundColor(.orange)

            Button(action: onDismiss) {
                Text("OK")
                    .font(.zenMaru(17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
}
