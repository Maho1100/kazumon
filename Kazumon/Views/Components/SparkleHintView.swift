import SwiftUI

struct SparkleHintView: View {
    let shown: Bool

    @State private var rotate1: Double = 0
    @State private var rotate2: Double = 0
    @State private var rotate3: Double = 0
    @State private var opacity1: Double = 1
    @State private var opacity2: Double = 0.3
    @State private var opacity3: Double = 0.2
    @State private var scale2: CGFloat = 0.6
    @State private var scale3: CGFloat = 0.5

    var body: some View {
        ZStack {
            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundColor(.yellow)
                .rotationEffect(.degrees(rotate1))
                .opacity(opacity1)

            Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)
                .offset(x: 10, y: -10)
                .rotationEffect(.degrees(rotate2))
                .opacity(opacity2)
                .scaleEffect(scale2)

            Image(systemName: "star.fill")
                .font(.system(size: 8))
                .foregroundColor(.pink)
                .offset(x: -10, y: 10)
                .rotationEffect(.degrees(rotate3))
                .opacity(opacity3)
                .scaleEffect(scale3)
        }
        .frame(width: 30, height: 40)
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .onAppear {
            guard shown else { return }

            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                rotate1 = 360
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                opacity1 = 0.2
            }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                rotate2 = -360
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                opacity2 = 1.0
                scale2 = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    rotate3 = -360
                }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    opacity3 = 1.0
                    scale3 = 1.0
                }
            }
        }
    }
}
