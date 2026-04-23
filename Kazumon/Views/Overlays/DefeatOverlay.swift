import SwiftUI

struct DefeatOverlay: View {
    let monsterName: String
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            Text("💥")
                .font(.system(size: 60))

            Text(String(format: NSLocalizedString("view_overlay_defeated", comment: ""), monsterName))
                .font(.zenMaru(22, weight: .bold))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
