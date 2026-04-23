import SwiftUI

// MARK: - Particle types

enum ParticleShape { case square, triangle }

struct RippleParticle: Identifiable {
    let id = UUID()
    let angle: Double
    let shape: ParticleShape
    let size: CGFloat
    let speed: CGFloat
    var offset: CGSize = .zero
    var opacity: Double = 0.9
    var rotation: Double = 0
    var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat)
}

// MARK: - ChoiceButton

struct ChoiceButton: View {
    let number: Int
    let correctAnswer: Int
    let selectedAnswer: Int?
    let combo: Int
    let isDisabled: Bool
    var showCorrectHighlight: Bool = false
    var isMistakeBossMode: Bool = false
    var isTimeBossMode: Bool = false
    let action: () -> Void

    @State private var flashOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var rippleScale: CGFloat = 0.3
    @State private var rippleOpacity: Double = 0
    @State private var rippleScale2: CGFloat = 0.3
    @State private var rippleOpacity2: Double = 0
    @State private var particles: [RippleParticle] = []

    private var defaultColor: Color {
        if isMistakeBossMode { return Color(red: 0.6, green: 0, blue: 0) }
        if isTimeBossMode { return Color(red: 0, green: 0, blue: 0.6) }
        return Color.blue.opacity(0.85)
    }

    private var backgroundColor: Color {
        if showCorrectHighlight {
            return number == correctAnswer
                ? Color.green
                : Color.gray.opacity(0.3)
        }
        guard let selected = selectedAnswer else {
            return defaultColor
        }
        if number == correctAnswer {
            return Color.green
        }
        if number == selected {
            return Color.red
        }
        return defaultColor.opacity(0.5)
    }

    private var scale: CGFloat {
        guard let selected = selectedAnswer else { return 1.0 }
        if number == selected { return 0.95 }
        return 1.0
    }

    private var particleCount: Int {
        switch combo {
        case 0...4:   return 8
        case 5...9:   return 10
        case 10...14: return 12
        default:      return 16
        }
    }

    var body: some View {
        Button {
            HapticsManager.tap()
            playRipple()
            playParticles()
            action()
        } label: {
            ZStack {
                Text("\(number)")
                    .font(.zenMaru(28, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: backgroundColor.opacity(0.4), radius: 4, y: 3)
                    .overlay(alignment: .topTrailing) {
                        if selectedAnswer == number {
                            Text(number == correctAnswer ? "✓" : "✗")
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(6)
                        }
                    }
                    .overlay {
                        if selectedAnswer == number && number == correctAnswer {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(flashOpacity)
                                .allowsHitTesting(false)
                                .onAppear {
                                    flashOpacity = 0.7
                                    withAnimation(.easeOut(duration: 0.35)) {
                                        flashOpacity = 0
                                    }
                                }
                        }
                    }

                // 波紋エフェクト（1本目）
                Circle()
                    .fill(rippleColor(for: combo).opacity(0.3))
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .allowsHitTesting(false)
                Circle()
                    .stroke(rippleColor(for: combo), lineWidth: 2.5)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .allowsHitTesting(false)

                // 波紋エフェクト（2本目）
                Circle()
                    .fill(rippleColor(for: combo).opacity(0.3))
                    .scaleEffect(rippleScale2)
                    .opacity(rippleOpacity2)
                    .allowsHitTesting(false)
                Circle()
                    .stroke(rippleColor(for: combo), lineWidth: 2.5)
                    .scaleEffect(rippleScale2)
                    .opacity(rippleOpacity2)
                    .allowsHitTesting(false)

                // パーティクル（ボタン範囲内にクリップ）
                ZStack {
                    ForEach(particles) { particle in
                        particleView(particle)
                            .frame(width: particle.size, height: particle.size)
                            .offset(particle.offset)
                            .opacity(particle.opacity)
                            .rotation3DEffect(
                                .degrees(particle.rotation),
                                axis: (
                                    x: particle.rotationAxis.x,
                                    y: particle.rotationAxis.y,
                                    z: particle.rotationAxis.z
                                )
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .clipped()
                .allowsHitTesting(false)
            }
        }
        .disabled(isDisabled || (showCorrectHighlight && number != correctAnswer))
        .scaleEffect(scale * pulseScale)
        .shadow(
            color: Color.yellow.opacity(glowOpacity),
            radius: 16
        )
        .accessibilityLabel(NSLocalizedString("accessibility_answer", comment: "") + " \(number)")
        .animation(.easeInOut(duration: 0.2), value: selectedAnswer)
        .onChange(of: showCorrectHighlight) { _, newValue in
            if newValue && number == correctAnswer {
                withAnimation(
                    .easeInOut(duration: 0.55)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseScale = 1.12
                    glowOpacity = 0.9
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    pulseScale = 1.0
                    glowOpacity = 0.0
                }
            }
        }
    }

    // MARK: - Particle shape view

    @ViewBuilder
    private func particleView(_ particle: RippleParticle) -> some View {
        let color = rippleColor(for: combo)
        switch particle.shape {
        case .square:
            Rectangle()
                .fill(color)
        case .triangle:
            Triangle()
                .fill(color)
        }
    }

    // MARK: - Helpers

    private func rippleColor(for combo: Int) -> Color {
        switch combo {
        case 0...4:   return Color.white.opacity(0.6)
        case 5...9:   return Color.orange.opacity(0.5)
        case 10...14: return Color.red.opacity(0.5)
        case 15...19: return Color.purple.opacity(0.5)
        default:      return Color.yellow.opacity(0.6)
        }
    }

    private func playRipple() {
        // 1本目
        rippleScale = 0.3
        rippleOpacity = 0.7
        withAnimation(.easeOut(duration: 1.0)) {
            rippleScale = 1.8
            rippleOpacity = 0
        }
        // 2本目（少し遅れて）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            rippleScale2 = 0.3
            rippleOpacity2 = 0.5
            withAnimation(.easeOut(duration: 1.0)) {
                rippleScale2 = 1.8
                rippleOpacity2 = 0
            }
        }
    }

    private func playParticles() {
        let count = particleCount
        let angleStep = 360.0 / Double(count)
        particles = (0..<count).map { i in
            RippleParticle(
                angle: Double(i) * angleStep,
                shape: i % 2 == 0 ? .square : .triangle,
                size: CGFloat.random(in: 2...5),
                speed: CGFloat.random(in: 35...55),
                rotationAxis: (
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    z: CGFloat.random(in: 0...1)
                )
            )
        }
        withAnimation(.easeOut(duration: 1.5)) {
            for i in particles.indices {
                let rad = particles[i].angle * .pi / 180
                particles[i].offset = CGSize(
                    width: cos(rad) * particles[i].speed,
                    height: sin(rad) * particles[i].speed
                )
                particles[i].opacity = 0
                particles[i].rotation = Double.random(in: 180...360)
            }
        }
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
