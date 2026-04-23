import SwiftUI

struct GachaPullView: View {
    let item: Item
    let onDismiss: () -> Void

    @State private var phase = 0
    @State private var orbScale: CGFloat = 0.3
    @State private var orbGlow: Double = 0
    @State private var crackScale: CGFloat = 1.0
    @State private var itemScale: CGFloat = 0
    @State private var itemOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var sparkles: [SparkleData] = []

    private var rarityColor: Color {
        switch item.rarity {
        case .common:    return .gray
        case .uncommon:  return .green
        case .rare:      return .blue
        case .legendary: return .yellow
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity)
                .ignoresSafeArea()

            if phase >= 0 {
                Circle()
                    .fill(RadialGradient(
                        colors: [rarityColor.opacity(0.8), rarityColor.opacity(0.2), .clear],
                        center: .center, startRadius: 10, endRadius: 120
                    ))
                    .frame(width: 200, height: 200)
                    .scaleEffect(orbScale)
                    .opacity(orbGlow)
            }

            if phase >= 2 {
                ForEach(sparkles) { s in
                    Circle()
                        .fill(rarityColor)
                        .frame(width: s.size, height: s.size)
                        .offset(x: s.x, y: s.y)
                        .opacity(s.opacity)
                }
            }

            if phase >= 2 {
                VStack(spacing: 12) {
                    Text(item.emoji)
                        .font(.system(size: 64))
                    Text(item.localizedName)
                        .font(.zenMaru(22, weight: .black))
                        .foregroundColor(.white)
                    Text(item.rarity.star)
                        .font(.system(size: 16))
                    Text(NSLocalizedString("gacha_got_item", comment: ""))
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .scaleEffect(itemScale)
                .opacity(itemOpacity)
            }

            if phase >= 3 {
                VStack {
                    Spacer()
                    Button {
                        HapticsManager.tap()
                        onDismiss()
                    } label: {
                        Text(NSLocalizedString("gacha_ok", comment: ""))
                            .font(.zenMaru(18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 50)
                            .background(rarityColor.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear { runAnimation() }
        .onTapGesture {
            if phase < 3 {
                phase = 3
                itemScale = 1
                itemOpacity = 1
                bgOpacity = 0.7
            }
        }
    }

    private func runAnimation() {
        withAnimation(.easeOut(duration: 0.4)) { bgOpacity = 0.7 }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            orbScale = 1.2
            orbGlow = 1
        }
        HapticsManager.tap()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            phase = 1
            withAnimation(.easeIn(duration: 0.3)) {
                orbScale = 0.5
                orbGlow = 1.5
            }
            HapticsManager.incorrect()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            phase = 2
            SoundManager.shared.playCorrect()
            HapticsManager.correct()
            spawnSparkles()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                orbScale = 2.0
                orbGlow = 0
                itemScale = 1.0
                itemOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            phase = 3
        }
    }

    private func spawnSparkles() {
        sparkles = (0..<12).map { _ in
            SparkleData(
                x: CGFloat.random(in: -120...120),
                y: CGFloat.random(in: -120...120),
                size: CGFloat.random(in: 4...10),
                opacity: 1
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                for i in sparkles.indices {
                    sparkles[i].opacity = 0
                    sparkles[i].x *= 2
                    sparkles[i].y *= 2
                }
            }
        }
    }
}

private struct SparkleData: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}
