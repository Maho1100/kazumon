import SwiftUI

struct PowerRingView: View {
    var powerLevel: Int
    var diff: Int = 0
    var animated: Bool = false
    var size: CGFloat = 80

    private let ringColor = Color(red: 0.50, green: 0.47, blue: 0.87)
    private let trackColor = Color(red: 0.93, green: 0.93, blue: 0.996)
    private let textColor = Color(red: 0.33, green: 0.29, blue: 0.72)
    private let upColor = Color(red: 0.114, green: 0.616, blue: 0.459)

    @State private var ringProgress: Double = 0
    @State private var displayNumber: Int = 0
    @State private var showDiff: Bool = false
    @State private var diffScale: CGFloat = 0
    @State private var numberScale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .stroke(trackColor, lineWidth: size * 0.1)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(displayNumber)")
                        .font(.zenMaru(size * 0.27, weight: .bold))
                        .foregroundColor(textColor)
                        .scaleEffect(numberScale)
                    Text("power_label")
                        .font(.zenMaru(size * 0.11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: size, height: size)

            // diff 表示（右上にオーバーレイ・ポップアップアニメ）
            if showDiff && diff > 0 {
                VStack(spacing: 0) {
                    Text("▲\(diff)")
                        .font(.zenMaru(16, weight: .bold))
                        .foregroundColor(upColor)
                    Text("power_up")
                        .font(.zenMaru(11, weight: .bold))
                        .foregroundColor(upColor)
                }
                .scaleEffect(diffScale)
                .offset(x: size * 0.5 + 8, y: -6)
            } else if showDiff && diff < 0 {
                Text("▼\(abs(diff))")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.secondary)
                    .scaleEffect(diffScale)
                    .offset(x: size * 0.5 + 8, y: -6)
            }
        }
        .frame(width: size + 40, height: size)
        .onChange(of: animated) { _, isAnimated in
            guard isAnimated else { return }
            showDiff = false
            diffScale = 0
            numberScale = 1.0
            withAnimation(.easeOut(duration: 1.2)) {
                ringProgress = Double(powerLevel) / 100.0
            }
            let target = powerLevel
            let steps = 40
            let duration = 1.2
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration / Double(steps) * Double(i)) {
                    displayNumber = Int(Double(target) * Double(i) / Double(steps))
                }
            }
            // カウントアップ完了後に数字ポップ
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    numberScale = 2.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        numberScale = 1.0
                    }
                }
            }
            if diff != 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    showDiff = true
                    // ポップアップ: 大きく登場 → 通常サイズに縮む
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        diffScale = 1.4
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            diffScale = 1.0
                        }
                    }
                }
            }
        }
    }
}
