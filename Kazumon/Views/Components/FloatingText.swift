import SwiftUI

struct FloatingText: View {
    let text: String
    @State private var opacity: Double = 1
    @State private var offsetY: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.zenMaru(22, weight: .black))
            .foregroundColor(.orange)
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            .opacity(opacity)
            .offset(y: offsetY)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    offsetY = -60
                    opacity = 0
                }
            }
    }
}
