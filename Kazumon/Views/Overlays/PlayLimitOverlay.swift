import SwiftUI

struct PlayLimitOverlay: View {
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🌙")
                    .font(.system(size: 56))

                Text(NSLocalizedString("overlay_play_limit_title", comment: ""))
                    .font(.zenMaru(22, weight: .black))
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("overlay_play_limit_body", comment: ""))
                    .font(.zenMaru(15, weight: .bold))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onUpgrade) {
                    VStack(spacing: 2) {
                        Text(NSLocalizedString("overlay_play_limit_upgrade", comment: ""))
                            .font(.zenMaru(18, weight: .bold))
                        if !PurchaseManager.shared.proDisplayPrice.isEmpty {
                            Text(PurchaseManager.shared.proDisplayPrice)
                                .font(.zenMaru(13, weight: .bold))
                                .opacity(0.8)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
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
                    Text(NSLocalizedString("overlay_play_limit_dismiss", comment: ""))
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
            AnalyticsManager.logPaywallView(source: "play_limit")
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
}
