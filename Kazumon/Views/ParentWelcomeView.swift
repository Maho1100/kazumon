import SwiftUI

/// 親/兄弟が「ちょうせんじょう」を受け取った瞬間の画面
/// じぶん選択時はこの画面をスキップして直接BGM選択へ進む
struct ParentWelcomeView: View {
    let recipient: FamilyMember
    let monster: MonsterChoice
    let difficulty: Difficulty
    let problemType: ProblemType
    let playerName: String
    let onStart: () -> Void
    let onTimeout: () -> Void

    @State private var letterIn = false
    @State private var stampIn = false
    @State private var letterFloat: CGFloat = 0
    @State private var startBtnPressed = false
    @State private var buttonsVisible = false
    @State private var didInteract = false

    /// 大人向け or 兄弟向けで文言を切り替え
    private var titleText: String {
        String(format: NSLocalizedString("family_parent_welcome_title", comment: ""), recipient.label)
    }

    private var messageText: String {
        if recipient.isParent {
            return String(format: NSLocalizedString("family_parent_welcome_message_named", comment: ""), playerName)
        } else {
            return String(format: NSLocalizedString("family_sibling_welcome_message", comment: ""), playerName)
        }
    }

    var body: some View {
        ZStack {
            // 背景: 暗転 + ブラー
            ZStack {
                Color.black.opacity(0.85).ignoresSafeArea()
                Rectangle().fill(.ultraThinMaterial).opacity(0.4).ignoresSafeArea()
            }

            // 手紙（中央）
            ZStack {
                Image("letter_paper")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 480)
                    .shadow(color: .black.opacity(0.4), radius: 18, y: 10)

                VStack(spacing: 12) {
                    Spacer().frame(height: 36)

                    // 宛名
                    Text(titleText)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.20))

                    // 装飾線
                    Rectangle()
                        .fill(Color(red: 0.55, green: 0.40, blue: 0.30).opacity(0.4))
                        .frame(width: 140, height: 1.5)

                    // メッセージ
                    Text(messageText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 8)

                    // 挑戦内容（モンスター・難易度・問題タイプ）
                    VStack(spacing: 6) {
                        Image(monster.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        HStack(spacing: 3) {
                            ForEach(0..<difficulty.starCount, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                        }
                        Text(problemType == .addition
                             ? NSLocalizedString("versus_course_addition", comment: "")
                             : NSLocalizedString("versus_course_normal", comment: ""))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))
                    }
                    .padding(.top, 4)

                    // 補足情報
                    infoRow(icon: "clock.fill", text: NSLocalizedString("family_parent_welcome_b1", comment: ""))
                        .padding(.top, 6)

                    Spacer()
                }
                .frame(width: 280, height: 460)

                // ハンコ
                Image("stamp_quest")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(15))
                    .offset(x: 110, y: -190)
                    .scaleEffect(stampIn ? 1.0 : 0.0)
                    .opacity(stampIn ? 1 : 0)
            }
            .rotationEffect(.degrees(-2))
            .offset(y: letterIn ? letterFloat : 600)
            .opacity(letterIn ? 1 : 0)
            .scaleEffect(letterIn ? 1.0 : 0.85)

            // ボタン（「やってみる」のみ）
            Button {
                HapticsManager.tap()
                didInteract = true
                onStart()
            } label: {
                Text(NSLocalizedString("family_parent_welcome_start", comment: ""))
                    .kazumonFixedButton(color: KazumonTheme.grass)
            }
            .scaleEffect(startBtnPressed ? 0.93 : 1.0)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                withAnimation(.easeInOut(duration: 0.1)) { startBtnPressed = p }
            }, perform: {})
            .offset(y: 290)
            .opacity(buttonsVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                letterIn = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                    stampIn = true
                }
                HapticsManager.tap()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    letterFloat = -4
                }
            }
            // ボタンは3秒後にフェードイン（手紙を読む時間を確保）
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    buttonsVisible = true
                }
            }
            // 30秒操作なし → 自動で島に戻る（「また さそおうね！」）
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                guard !didInteract else { return }
                onTimeout()
            }
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0.30))
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color(red: 1.0, green: 0.92, blue: 0.85)))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))
        }
    }
}
