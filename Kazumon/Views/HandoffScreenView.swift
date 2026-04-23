import SwiftUI

/// 「スマホをわたしてね！」画面
/// DeliveryAnimation → (この画面) → ParentWelcomeView の間に挟む
/// 子供が「わたした！」を押すことで自分のターン終了を意識させる
struct HandoffScreenView: View {
    let recipient: FamilyMember
    let onHandedOver: () -> Void
    let onPlaySelf: () -> Void

    @State private var textIn = false
    @State private var btnIn = false
    @State private var btnPressed = false
    @State private var selfBtnPressed = false
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .opacity(fadeOut ? 1.0 : 0.85)

            VStack(spacing: 28) {
                // 宛先の絵文字
                Text(recipient.emoji)
                    .font(.system(size: 72))
                    .scaleEffect(textIn ? 1.0 : 0.5)
                    .opacity(textIn ? 1 : 0)

                // メッセージ
                Text(String(format: NSLocalizedString("handoff_message", comment: ""), recipient.label))
                    .font(.zenMaru(24, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .opacity(textIn ? 1 : 0)
                    .offset(y: textIn ? 0 : 20)

                VStack(spacing: 14) {
                    // 「わたした！」ボタン
                    Button {
                        HapticsManager.tap()
                        withAnimation(.easeIn(duration: 0.4)) {
                            fadeOut = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onHandedOver()
                        }
                    } label: {
                        Text(NSLocalizedString("handoff_done_button", comment: ""))
                            .font(.zenMaru(18, weight: .black))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                    }
                    .scaleEffect(btnPressed ? 0.93 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                        withAnimation(.easeInOut(duration: 0.1)) { btnPressed = p }
                    }, perform: {})

                    // 「やっぱり じぶんでやる！」ボタン
                    Button {
                        HapticsManager.tap()
                        onPlaySelf()
                    } label: {
                        Text(NSLocalizedString("handoff_play_self", comment: ""))
                            .font(.zenMaru(13, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .scaleEffect(selfBtnPressed ? 0.93 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                        withAnimation(.easeInOut(duration: 0.1)) { selfBtnPressed = p }
                    }, perform: {})
                }
                .opacity(btnIn ? 1 : 0)
                .offset(y: btnIn ? 0 : 10)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                textIn = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.4)) {
                    btnIn = true
                }
            }
        }
    }
}
