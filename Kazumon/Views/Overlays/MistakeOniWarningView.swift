import SwiftUI

struct MistakeOniWarningView: View {
    let onDismiss: () -> Void

    @State private var bgOpacity: Double = 0
    @State private var lineOpacities: [Double] = []
    @State private var allLinesShown = false
    @State private var dismissed = false
    @State private var eyeOpacity: Double = 0
    @State private var eyeScale: CGFloat = 0.8
    @State private var eyeOffsetX: CGFloat = 0
    @State private var eyeBlinkPhase = false

    private let warnings: [String] = [
        NSLocalizedString("mistake_boss_warning_1", comment: ""),
        NSLocalizedString("mistake_boss_warning_2", comment: ""),
        NSLocalizedString("mistake_boss_warning_3", comment: ""),
        NSLocalizedString("mistake_boss_warning_4", comment: ""),
        NSLocalizedString("mistake_boss_warning_5", comment: ""),
    ]

    @State private var lines: [String] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea().opacity(bgOpacity)

            // 赤い目（上部でゆらゆら）
            HStack(spacing: 28) {
                eyeShape.scaleEffect(x: -1)
                eyeShape
            }
            .scaleEffect(eyeScale)
            .opacity(eyeOpacity * (eyeBlinkPhase ? 0.1 : 1.0))
            .offset(x: eyeOffsetX, y: -180)

            VStack(spacing: 14) {
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    Text(line)
                        .font(.zenMaru(20, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(i < lineOpacities.count ? lineOpacities[i] : 0)
                }
            }
            .padding(.horizontal, 32)

            if allLinesShown {
                VStack {
                    Spacer()
                    Text("tap_to_continue")
                        .font(.zenMaru(13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.bottom, 60)
                }
            }
        }
        .onTapGesture {
            if allLinesShown { dismiss() }
        }
        .onAppear {
            SoundManager.shared.fadeOutBGM(duration: 0.5)

            let text = warnings.randomElement() ?? warnings[0]
            lines = text.components(separatedBy: "\n")
            lineOpacities = Array(repeating: 0.0, count: lines.count)

            withAnimation(.easeIn(duration: 0.8)) { bgOpacity = 1 }

            // 赤い目を1秒後にフェードイン
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 1.0)) {
                    eyeOpacity = 0.9
                    eyeScale = 1.0
                }
                // ゆらゆら揺れる
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    eyeOffsetX = 8
                }
                // まばたき
                startBlinking()
            }

            for i in lines.indices {
                let delay = 1.0 + Double(i) * 1.5
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    guard !dismissed else { return }
                    withAnimation(.easeIn(duration: 0.6)) {
                        if i < lineOpacities.count { lineOpacities[i] = 1.0 }
                    }
                    if i == lines.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            allLinesShown = true
                        }
                    }
                }
            }
        }
    }

    private var eyeShape: some View {
        ZStack {
            // 吊り上がった目（三角形に近い楕円）
            Ellipse()
                .fill(Color.red)
                .frame(width: 32, height: 14)
                .shadow(color: .red.opacity(0.8), radius: 12)
                .shadow(color: .red.opacity(0.4), radius: 24)
            // 瞳
            Circle()
                .fill(Color(red: 0.3, green: 0, blue: 0))
                .frame(width: 8, height: 8)
                .offset(y: 1)
        }
        .rotationEffect(.degrees(-15))
    }

    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.5...8.0), repeats: true) { _ in
            guard !dismissed else { return }
            withAnimation(.easeIn(duration: 0.1)) { eyeBlinkPhase = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.1)) { eyeBlinkPhase = false }
            }
        }
    }

    private func dismiss() {
        guard !dismissed else { return }
        dismissed = true
        withAnimation(.easeOut(duration: 0.5)) {
            bgOpacity = 0; eyeOpacity = 0
            for i in lineOpacities.indices { lineOpacities[i] = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDismiss() }
    }
}
