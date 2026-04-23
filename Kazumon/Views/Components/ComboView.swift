import SwiftUI

struct ComboView: View {
    let combo: Int
    let multiplier: Int
    let label: String?
    let stageIcon: String
    let gaugeProgress: Double

    @State private var pulseScale: CGFloat = 1.0

    private var gaugeColor: Color { ComboStyle.color(for: combo) }

    private var isLegendary: Bool { combo >= 20 }

    var body: some View {
        VStack(spacing: 4) {
            if combo > 0 {
                // Stage label (NICE!, SUPER!, etc.)
                if let label {
                    Text(label)
                        .font(.zenMaru(24, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                }

                // Combo count + stage icon
                HStack(spacing: 6) {
                    if !stageIcon.isEmpty {
                        Text(stageIcon)
                    }

                    Text(String(format: NSLocalizedString("view_combo_count", comment: ""), combo))
                        .font(.zenMaru(20, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                }
                .scaleEffect(pulseScale)

                // Combo gauge
                comboGauge
            }
        }
        .frame(height: 36)
        .onChange(of: combo) { _, newValue in
            guard newValue > 0 else { return }
            pulseScale = 1.4
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    pulseScale = 1.0
                }
            }
        }
    }

    @ViewBuilder
    private var comboGauge: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: isLegendary
                                ? [.yellow, .orange, .yellow]
                                : [gaugeColor, gaugeColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * gaugeProgress)
            }
        }
        .frame(width: 160, height: 8)
        .animation(.easeInOut(duration: 0.3), value: gaugeProgress)
        .shadow(
            color: isLegendary ? .yellow.opacity(0.6) : .clear,
            radius: isLegendary ? 8 : 0
        )
    }
}

// MARK: - Combo Break Overlay

struct ComboBreakOverlay: View {
    let combo: Int
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 4) {
            Text("💥")
                .font(.system(size: 36))
            Text(String(format: NSLocalizedString("view_combo_break", comment: ""), combo))
                .font(.zenMaru(22, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.red.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
