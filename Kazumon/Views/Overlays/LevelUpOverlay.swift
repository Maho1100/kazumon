import SwiftUI

struct LevelUpOverlay: View {
    let newLevel: Int
    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = -10

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉")
                .font(.system(size: 60))

            Text("view_overlay_level_up_title")
                .font(.zenMaru(28, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Lv.\(newLevel)")
                .font(.zenMaru(48, weight: .black))
                .foregroundColor(.white)
        }
        .padding(40)
        .background(Color.purple.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                scale = 1.0
                rotation = 0
            }
        }
    }
}
