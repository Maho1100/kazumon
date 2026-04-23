import SwiftUI

struct TimerBarView: View {
    let remaining: Double
    let total: Double
    var pulseHighlight: Bool = false   // チュートリアル中の色パルス
    var stolenFlash: Bool = false      // 時間が奪われた瞬間の色変え

    @State private var pulseOn = false

    private var progress: Double {
        guard total > 0 else { return 0 }
        return remaining / total
    }

    private var barColor: Color {
        if stolenFlash {
            return Color(red: 0.8, green: 0, blue: 0.8) // 紫フラッシュ
        }
        if progress > 0.5 { return .green }
        if progress > 0.25 { return .yellow }
        return .red
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: geo.size.width * max(0, progress))
                    .animation(.linear(duration: 0.05), value: progress)
            }
        }
        .frame(height: 10)
        .padding(.horizontal)
        .overlay(
            // パルス点滅（色変化）
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .opacity(pulseHighlight && pulseOn ? 0.4 : 0)
                .padding(.horizontal)
                .frame(height: 10)
                .allowsHitTesting(false)
        )
        .onChange(of: pulseHighlight) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    pulseOn = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    pulseOn = false
                }
            }
        }
        .onAppear {
            if pulseHighlight {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    pulseOn = true
                }
            }
        }
    }
}
