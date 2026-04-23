import SwiftUI

/// 「ちょうせんじょうを かこう！」イントロ画面
/// バトル選択後に表示。家族モード or オンライン対戦の2択。
struct ChallengeLetterIntroView: View {
    let onSelectFamily: () -> Void
    let onSelectOnline: () -> Void
    let onBack: () -> Void

    @State private var charIn = false
    @State private var leftCardIn = false
    @State private var rightCardIn = false
    @State private var titleIn = false
    @State private var charBob: CGFloat = 0
    @State private var familyPressed = false
    @State private var onlinePressed = false

    var body: some View {
        ZStack {
            // 背景: パステル空グラデ
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.85, blue: 1.00),  // 空の青
                    Color(red: 0.85, green: 0.92, blue: 1.00),  // 薄い水色
                    Color(red: 1.00, green: 0.92, blue: 0.85)   // 朝焼け
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            // ふわふわ星パーティクル
            ForEach(0..<10, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundColor(.white.opacity(0.8))
                    .position(
                        x: CGFloat.random(in: 20...UIScreen.main.bounds.width-20),
                        y: CGFloat.random(in: 60...UIScreen.main.bounds.height-100)
                    )
                    .opacity(charIn ? 0.9 : 0.3)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1.8...3.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.18),
                        value: charIn
                    )
            }

            VStack(spacing: 16) {
                // もどるボタン
                HStack {
                    Button {
                        HapticsManager.tap()
                        onBack()
                    } label: {
                        Text(NSLocalizedString("battle_shop_back", comment: ""))
                            .font(.zenMaru(16, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22).padding(.vertical, 8)
                            .background(Capsule().fill(Color.black.opacity(0.3)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // タイトル
                Text(NSLocalizedString("intro_title", comment: ""))
                    .font(.zenMaru(28, weight: .black))
                    .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                    .shadow(color: .white.opacity(0.7), radius: 2, y: 0)
                    .multilineTextAlignment(.center)
                    .scaleEffect(titleIn ? 1.0 : 0.7)
                    .opacity(titleIn ? 1 : 0)

                // キャラ（書いてる）
                Image("char_writing")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .offset(y: charBob)
                    .scaleEffect(charIn ? 1.0 : 0.6)
                    .opacity(charIn ? 1 : 0)

                Spacer().frame(height: 8)

                // 2択カード
                HStack(spacing: 18) {
                    // 家族にちょうせんじょう
                    Button {
                        HapticsManager.tap()
                        onSelectFamily()
                    } label: {
                        modeCard(
                            emoji: "📩",
                            title: NSLocalizedString("intro_family_card", comment: ""),
                            colorTop: Color(red: 1.00, green: 0.62, blue: 0.40),
                            colorBottom: Color(red: 0.90, green: 0.45, blue: 0.30)
                        )
                    }
                    .scaleEffect(familyPressed ? 0.93 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                        withAnimation(.easeInOut(duration: 0.1)) { familyPressed = p }
                    }, perform: {})
                    .offset(y: leftCardIn ? 0 : 60)
                    .opacity(leftCardIn ? 1 : 0)
                    .scaleEffect(leftCardIn ? 1.0 : 0.6)

                    // オンラインバトル
                    Button {
                        HapticsManager.tap()
                        onSelectOnline()
                    } label: {
                        modeCard(
                            emoji: "🌍",
                            title: NSLocalizedString("intro_online_card", comment: ""),
                            colorTop: Color(red: 0.40, green: 0.65, blue: 0.95),
                            colorBottom: Color(red: 0.25, green: 0.45, blue: 0.85)
                        )
                    }
                    .scaleEffect(onlinePressed ? 0.93 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                        withAnimation(.easeInOut(duration: 0.1)) { onlinePressed = p }
                    }, perform: {})
                    .offset(y: rightCardIn ? 0 : 60)
                    .opacity(rightCardIn ? 1 : 0)
                    .scaleEffect(rightCardIn ? 1.0 : 0.6)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            AnalyticsManager.logViewBattleModeSelect()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                titleIn = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.25)) {
                charIn = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.6)) {
                charBob = -6
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.4)) {
                leftCardIn = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.55)) {
                rightCardIn = true
            }
        }
    }

    @ViewBuilder
    private func modeCard(emoji: String, title: String, colorTop: Color, colorBottom: Color) -> some View {
        VStack(spacing: 10) {
            Text(emoji).font(.system(size: 50))
            Text(title)
                .font(.zenMaru(16, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                .lineLimit(2)
        }
        .frame(width: 140, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [colorTop, colorBottom],
                    startPoint: .top, endPoint: .bottom
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
    }
}
