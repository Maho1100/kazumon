import SwiftUI

/// 家族メンバー選択画面（家族モード/NPCパス&プレイ）
/// - 初回起動時は家族構成セットアップUIを表示
/// - 設定済みなら家族メンバーボタンを並べ、タップで選択
/// - 親メンバー（おとうさん/おかあさん）選択時はウェルカムオーバーレイを表示
struct FamilySelectView: View {
    let gameVM: GameViewModel
    let onSelect: (FamilyMember) -> Void
    let onBack: () -> Void

    @State private var members: [FamilyMember] = DataStore.loadFamilyMembers()
    @State private var setupDone: Bool = DataStore.isFamilySetupDone()
    @State private var setupSelection: Set<FamilyMember> = []
    @State private var pendingParent: FamilyMember? = nil
    @State private var fadeIn: Double = 0

    // 挑戦状アニメーション用
    @State private var letterIn = false
    @State private var charIn = false
    @State private var bubbleIn = false
    @State private var stampIn = false
    @State private var letterFloat: CGFloat = 0
    @State private var startBtnPressed = false
    @State private var laterBtnPressed = false

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(red: 0.30, green: 0.55, blue: 0.85),
                         Color(red: 0.20, green: 0.35, blue: 0.65)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            if setupDone {
                memberSelectContent
            } else {
                familySetupContent
            }

            // 親向けウェルカムオーバーレイ
            if let parent = pendingParent {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    Rectangle().fill(.ultraThinMaterial).opacity(0.4).ignoresSafeArea()
                }
                .transition(.opacity)
                parentWelcomeOverlay(for: parent)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .opacity(fadeIn)
        .onAppear {
            AnalyticsManager.logViewFamilySelect()
            withAnimation(.easeOut(duration: 0.3)) { fadeIn = 1 }
        }
    }

    // MARK: - 家族メンバー選択UI（設定済みの場合）

    private var memberSelectContent: some View {
        VStack(spacing: 24) {
            HStack {
                backButton
                Spacer()
                Button {
                    HapticsManager.tap()
                    setupSelection = Set(members)
                    setupDone = false
                } label: {
                    Text(NSLocalizedString("family_edit_button", comment: ""))
                        .font(.zenMaru(13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.25)))
                }
            }
            .padding(.horizontal, 20).padding(.top, 16)

            Spacer().frame(height: 8)

            Text(NSLocalizedString("family_select_title", comment: ""))
                .font(.zenMaru(24, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
                .multilineTextAlignment(.center)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14)],
                          spacing: 14) {
                    ForEach(members) { member in
                        memberButton(member)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }

    @ViewBuilder
    private func memberButton(_ member: FamilyMember) -> some View {
        Button {
            HapticsManager.tap()
            if member.isParent {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    pendingParent = member
                }
            } else {
                onSelect(member)
            }
        } label: {
            VStack(spacing: 6) {
                Text(member.emoji).font(.system(size: 48))
                Text(member.label)
                    .font(.zenMaru(16, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                let score = DataStore.loadFamilyScore(for: member).bestScore
                Text(score > 0
                     ? String(format: NSLocalizedString("family_member_best_score", comment: ""), score)
                     : NSLocalizedString("family_member_no_score", comment: ""))
                    .font(.zenMaru(11, weight: .bold))
                    .foregroundColor(.yellow)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: member.isParent
                            ? [Color(red: 0.95, green: 0.55, blue: 0.30),
                               Color(red: 0.85, green: 0.40, blue: 0.20)]
                            : [Color(red: 0.40, green: 0.65, blue: 0.95),
                               Color(red: 0.25, green: 0.45, blue: 0.85)],
                        startPoint: .top, endPoint: .bottom
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
        }
    }

    // MARK: - 家族構成セットアップUI（初回 or 編集時）

    private var familySetupContent: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Text(NSLocalizedString("family_setup_title", comment: ""))
                .font(.zenMaru(24, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)

            Text(NSLocalizedString("family_setup_subtitle", comment: ""))
                .font(.zenMaru(13, weight: .bold))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)],
                          spacing: 12) {
                    ForEach(FamilyMember.allCases) { member in
                        setupToggleButton(member)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }

            // 完了ボタン
            Button {
                HapticsManager.tap()
                // じぶんは必ず含める
                var selected = setupSelection
                selected.insert(.self_)
                let ordered = FamilyMember.allCases.filter { selected.contains($0) }
                members = ordered
                DataStore.saveFamilyMembers(ordered)
                DataStore.markFamilySetupDone()
                AnalyticsManager.logFamilySetupComplete(memberCount: ordered.count)
                withAnimation { setupDone = true }
            } label: {
                Text(NSLocalizedString("family_setup_done", comment: ""))
                    .font(.zenMaru(20, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.30, green: 0.69, blue: 0.49))
                    )
                    .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
            }
            .padding(.horizontal, 40)
            .disabled(setupSelection.isEmpty)
            .opacity(setupSelection.isEmpty ? 0.5 : 1.0)

            Button {
                HapticsManager.tap()
                onBack()
            } label: {
                Text(NSLocalizedString("battle_shop_back", comment: ""))
                    .font(.zenMaru(16, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 24).padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.25)))
            }
            .padding(.bottom, 30)
        }
    }

    @ViewBuilder
    private func setupToggleButton(_ member: FamilyMember) -> some View {
        let isSelf = member == .self_
        let isSelected = setupSelection.contains(member) || isSelf
        Button {
            guard !isSelf else { return }
            HapticsManager.tap()
            if setupSelection.contains(member) {
                setupSelection.remove(member)
            } else {
                setupSelection.insert(member)
            }
        } label: {
            VStack(spacing: 4) {
                Text(member.emoji).font(.system(size: 36))
                Text(member.label)
                    .font(.zenMaru(13, weight: .black))
                    .foregroundColor(isSelected ? .white : Color(red: 0.16, green: 0.16, blue: 0.23))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected
                          ? Color(red: 0.30, green: 0.72, blue: 0.49)
                          : Color.white.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .disabled(isSelf)
    }

    /// プレイヤー名に「ちゃん」を自動付与（既に敬称が付いていれば付けない）
    private var playerNameWithHonorific: String {
        let name = gameVM.playerData.playerName
        let existing = ["ちゃん", "くん", "さん", "様", "ちゃま", "君", "さま"]
        if existing.contains(where: { name.hasSuffix($0) }) {
            return name
        }
        return name + "ちゃん"
    }

    // MARK: - 親向け挑戦状オーバーレイ（手紙メタファー）

    @ViewBuilder
    private func parentWelcomeOverlay(for parent: FamilyMember) -> some View {
        let playerName = playerNameWithHonorific

        ZStack {
            // 手紙背景
            ZStack {
                Image("letter_paper")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 480)
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 10)

                // 手紙の中身
                VStack(spacing: 14) {
                    Spacer().frame(height: 38)

                    // 宛名: ○○へ
                    Text(String(format: NSLocalizedString("family_parent_welcome_title", comment: ""), parent.label))
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.20))

                    // 装飾線
                    Rectangle()
                        .fill(Color(red: 0.55, green: 0.40, blue: 0.30).opacity(0.4))
                        .frame(width: 140, height: 1.5)

                    // メッセージ: ○○ちゃんから ちょうせんじょう！
                    Text(String(format: NSLocalizedString("family_parent_welcome_message_named", comment: ""), playerName))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 12)
                        .padding(.top, 2)

                    // 3項目（クエストカード風）
                    VStack(alignment: .leading, spacing: 9) {
                        questBullet(icon: "clock.fill", text: NSLocalizedString("family_parent_welcome_b1", comment: ""))
                        questBullet(icon: "pencil.tip", text: NSLocalizedString("family_parent_welcome_b2", comment: ""))
                        questBullet(icon: "trophy.fill", text: NSLocalizedString("family_parent_welcome_b3", comment: ""))
                    }
                    .padding(.top, 6)

                    Spacer()
                }
                .frame(width: 280, height: 460)

                // ちょうせんじょうハンコ（右上）
                Image("stamp_quest")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(15))
                    .offset(x: 110, y: -190)
                    .scaleEffect(stampIn ? 1.0 : 0.0)
                    .opacity(stampIn ? 1 : 0)
            }
            .rotationEffect(.degrees(-2))
            .offset(y: letterIn ? letterFloat : 600)
            .opacity(letterIn ? 1 : 0)
            .scaleEffect(letterIn ? 1.0 : 0.85)

            // プレイヤーキャラ（右下から覗き込む）
            VStack(spacing: 4) {
                // 吹き出し
                Text(NSLocalizedString("family_parent_welcome_bubble", comment: ""))
                    .font(.zenMaru(13, weight: .black))
                    .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.55, green: 0.40, blue: 0.30).opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .scaleEffect(bubbleIn ? 1.0 : 0.0, anchor: .bottomLeading)
                    .opacity(bubbleIn ? 1 : 0)

                KennyCharacterView(
                    appearance: gameVM.playerAppearance,
                    size: 72
                )
            }
            .offset(x: 120, y: 235)
            .offset(y: charIn ? 0 : 80)
            .opacity(charIn ? 1 : 0)

            // ボタン
            VStack(spacing: 10) {
                Button {
                    HapticsManager.tap()
                    let p = parent
                    withAnimation { pendingParent = nil }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onSelect(p)
                    }
                } label: {
                    Text(NSLocalizedString("family_parent_welcome_start", comment: ""))
                        .kazumonFixedButton(color: KazumonTheme.grass)
                }
                .scaleEffect(startBtnPressed ? 0.93 : 1.0)
                .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                    withAnimation(.easeInOut(duration: 0.1)) { startBtnPressed = p }
                }, perform: {})

                Button {
                    HapticsManager.tap()
                    withAnimation { pendingParent = nil }
                } label: {
                    Text(NSLocalizedString("family_parent_welcome_later", comment: ""))
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.3)))
                }
                .scaleEffect(laterBtnPressed ? 0.93 : 1.0)
                .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                    withAnimation(.easeInOut(duration: 0.1)) { laterBtnPressed = p }
                }, perform: {})
            }
            .offset(y: 290)
            .opacity(letterIn ? 1 : 0)
        }
        .onAppear {
            triggerWelcomeAnimation()
        }
    }

    private func triggerWelcomeAnimation() {
        // 手紙登場
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            letterIn = true
        }
        // ハンコ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                stampIn = true
            }
            HapticsManager.tap()
        }
        // キャラ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                charIn = true
            }
        }
        // 吹き出し
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                bubbleIn = true
            }
        }
        // 手紙のふんわり浮遊
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                letterFloat = -4
            }
        }
    }

    @ViewBuilder
    private func questBullet(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0.30))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color(red: 1.0, green: 0.92, blue: 0.85))
                )
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - 共通

    private var backButton: some View {
        Button {
            HapticsManager.tap()
            onBack()
        } label: {
            Text(NSLocalizedString("battle_shop_back", comment: ""))
                .font(.zenMaru(16, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 22).padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.25)))
        }
    }
}
