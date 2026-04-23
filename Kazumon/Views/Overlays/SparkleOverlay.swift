import SwiftUI

/// 進化直後のキャラクターきらめきエフェクト
struct SparkleOverlay: View {
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.5

    // 8方向にキラキラを配置
    private let positions: [(x: CGFloat, y: CGFloat)] = [
        (0, -55), (39, -39), (55, 0), (39, 39),
        (0, 55), (-39, 39), (-55, 0), (-39, -39)
    ]

    var body: some View {
        ZStack {
            ForEach(positions.indices, id: \.self) { i in
                Text("✨")
                    .font(.system(size: 16))
                    .offset(x: positions[i].x, y: positions[i].y)
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .animation(
                        .easeOut(duration: 0.4)
                        .delay(Double(i) * 0.05),
                        value: opacity
                    )
            }
        }
        .onAppear {
            opacity = 1
            scale = 1
            // 1秒後にフェードアウト
            withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
                opacity = 0
            }
        }
        .allowsHitTesting(false)
    }
}
