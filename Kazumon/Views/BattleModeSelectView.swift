import SwiftUI

/// バトルボタン押下後のモード選択画面
/// 「家族と遊ぶ（NPCモード/パス&プレイ）」 or 「オンライン対戦」
struct BattleModeSelectView: View {
    let onSelectFamily: () -> Void
    let onSelectOnline: () -> Void
    let onBack: () -> Void

    @State private var leftIn = false
    @State private var rightIn = false
    @State private var familyPressed = false
    @State private var onlinePressed = false

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.40, blue: 0.80),
                         Color(red: 0.30, green: 0.25, blue: 0.65)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text(NSLocalizedString("battle_mode_select_title", comment: ""))
                    .font(.zenMaru(28, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 20)

                HStack(spacing: 24) {
                    // 家族と遊ぶ
                    Button {
                        HapticsManager.tap()
                        onSelectFamily()
                    } label: {
                        VStack(spacing: 12) {
                            Text("🏠")
                                .font(.system(size: 56))
                            Text(NSLocalizedString("battle_mode_family", comment: ""))
                                .font(.zenMaru(20, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                            Text(NSLocalizedString("battle_mode_family_desc", comment: ""))
                                .font(.zenMaru(11, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 140, height: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [Color(red: 1.00, green: 0.62, blue: 0.40),
                                             Color(red: 0.90, green: 0.45, blue: 0.30)],
                                    startPoint: .top, endPoint: .bottom
                                ))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                    }
                    .scaleEffect(familyPressed ? 0.92 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                        withAnimation(.easeInOut(duration: 0.1)) { familyPressed = p }
                    }, perform: {})
                    .offset(y: leftIn ? 0 : 60)
                    .opacity(leftIn ? 1 : 0)
                    .scaleEffect(leftIn ? 1.0 : 0.6)

                    // オンライン対戦
                    Button {
                        HapticsManager.tap()
                        onSelectOnline()
                    } label: {
                        VStack(spacing: 12) {
                            Text("🌍")
                                .font(.system(size: 56))
                            Text(NSLocalizedString("battle_mode_online", comment: ""))
                                .font(.zenMaru(20, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                            Text(NSLocalizedString("battle_mode_online_desc", comment: ""))
                                .font(.zenMaru(11, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 140, height: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.40, green: 0.65, blue: 0.95),
                                             Color(red: 0.25, green: 0.45, blue: 0.85)],
                                    startPoint: .top, endPoint: .bottom
                                ))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                    }
                    .scaleEffect(onlinePressed ? 0.92 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                        withAnimation(.easeInOut(duration: 0.1)) { onlinePressed = p }
                    }, perform: {})
                    .offset(y: rightIn ? 0 : 60)
                    .opacity(rightIn ? 1 : 0)
                    .scaleEffect(rightIn ? 1.0 : 0.6)
                }

                Spacer()

                // もどるボタン
                Button {
                    HapticsManager.tap()
                    onBack()
                } label: {
                    Text(NSLocalizedString("battle_shop_back", comment: ""))
                        .font(.zenMaru(20, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.25)))
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            AnalyticsManager.logViewBattleModeSelect()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) {
                leftIn = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.30)) {
                rightIn = true
            }
        }
    }
}
