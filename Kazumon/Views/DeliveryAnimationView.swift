import SwiftUI

/// ちょうせんじょうを渡す演出（3.5秒・自動進行）
struct DeliveryAnimationView: View {
    let recipient: FamilyMember
    let onComplete: () -> Void

    @State private var charIn = false
    @State private var letterScale: CGFloat = 1.0
    @State private var letterOpacity: Double = 1.0
    @State private var letterOffsetY: CGFloat = 0
    @State private var dimOverlay: Double = 0
    @State private var bubbleIn = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.85, blue: 1.00),
                    Color(red: 0.85, green: 0.92, blue: 1.00),
                    Color(red: 1.00, green: 0.92, blue: 0.85)
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text(String(format: NSLocalizedString("delivery_text", comment: ""), recipient.label))
                    .font(.zenMaru(20, weight: .black))
                    .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                    .shadow(color: .white.opacity(0.7), radius: 2, y: 0)
                    .scaleEffect(bubbleIn ? 1.0 : 0.7)
                    .opacity(bubbleIn ? 1 : 0)

                ZStack {
                    // キャラ（差し出すポーズ）— char_delivering.png がなければ char_writing.png をフォールバック
                    Image("char_delivering")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .opacity(charIn ? 1 : 0)
                        .scaleEffect(charIn ? 1 : 0.7)

                    // 渡される手紙（ズームアウトしながらフェード）
                    Image("letter_paper")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 140)
                        .scaleEffect(letterScale)
                        .opacity(letterOpacity)
                        .offset(y: letterOffsetY)
                }

                Spacer()
            }

            // 暗転オーバーレイ
            Color.black.opacity(dimOverlay).ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                charIn = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                bubbleIn = true
            }
            // 手紙が前方にズームアウト
            withAnimation(.easeIn(duration: 0.7).delay(1.5)) {
                letterScale = 2.5
                letterOpacity = 0
                letterOffsetY = -40
            }
            // 軽い暗転 → ピンポーン
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeIn(duration: 0.3)) {
                    dimOverlay = 0.4
                }
                HapticsManager.tap()
                SoundManager.shared.playTap()
            }
            // 自動進行
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                onComplete()
            }
        }
    }
}
