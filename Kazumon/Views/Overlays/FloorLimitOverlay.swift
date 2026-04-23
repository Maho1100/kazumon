import SwiftUI

struct FloorLimitOverlay: View {
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 56))

                Text("overlay_floor_limit_title")
                    .font(.zenMaru(22, weight: .black))
                    .multilineTextAlignment(.center)

                Text("overlay_floor_limit_body")
                    .font(.zenMaru(15, weight: .bold))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onUpgrade) {
                    Text("overlay_floor_limit_upgrade")
                        .font(.zenMaru(18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button(action: onDismiss) {
                    Text("overlay_floor_limit_result")
                        .font(.zenMaru(15, weight: .bold))
                        .foregroundColor(.secondary)
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
}
