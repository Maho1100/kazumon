import SwiftUI

/// 「だれに ちょうせんじょう？」宛先選択画面
/// - 初回起動時は家族構成セットアップUIを表示
/// - 設定済みなら家族メンバーを封筒風カードで表示
struct RecipientSelectView: View {
    let gameVM: GameViewModel
    let onSelect: (FamilyMember) -> Void
    let onBack: () -> Void

    @State private var members: [FamilyMember] = DataStore.loadFamilyMembers()
    @State private var setupDone: Bool = DataStore.isFamilySetupDone()
    @State private var setupSelection: Set<FamilyMember> = []
    @State private var fadeIn: Double = 0

    var body: some View {
        ZStack {
            // 背景: パステル空グラデ
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.85, blue: 1.00),
                    Color(red: 0.85, green: 0.92, blue: 1.00),
                    Color(red: 1.00, green: 0.92, blue: 0.85)
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            if setupDone {
                memberSelectContent
            } else {
                familySetupContent
            }
        }
        .opacity(fadeIn)
        .onAppear {
            AnalyticsManager.logViewFamilySelect()
            withAnimation(.easeOut(duration: 0.3)) { fadeIn = 1 }
        }
    }

    // MARK: - 宛先選択UI

    private var memberSelectContent: some View {
        VStack(spacing: 16) {
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
                        .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.7)))
                }
            }
            .padding(.horizontal, 20).padding(.top, 16)

            // タイトル
            Text(NSLocalizedString("recipient_select_title", comment: ""))
                .font(.zenMaru(24, weight: .black))
                .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                .shadow(color: .white.opacity(0.7), radius: 2, y: 0)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    ForEach(members) { member in
                        envelopeCard(for: member)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
    }

    @ViewBuilder
    private func envelopeCard(for member: FamilyMember) -> some View {
        Button {
            HapticsManager.tap()
            onSelect(member)
        } label: {
            ZStack {
                // 封筒画像
                Image("envelope_card")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 120)

                // メンバー情報を封筒の上に重ねる
                VStack(spacing: 2) {
                    Text(member.emoji).font(.system(size: 28))
                    Text(member.label)
                        .font(.zenMaru(14, weight: .black))
                        .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                    let score = DataStore.loadFamilyScore(for: member).bestScore
                    Text(score > 0
                         ? String(format: NSLocalizedString("family_member_best_score", comment: ""), score)
                         : NSLocalizedString("family_member_no_score", comment: ""))
                        .font(.zenMaru(10, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0.20))
                }
                .offset(y: -2)
            }
            .frame(height: 130)
        }
    }

    // MARK: - 家族構成セットアップUI

    private var familySetupContent: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Text(NSLocalizedString("family_setup_title", comment: ""))
                .font(.zenMaru(24, weight: .black))
                .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                .shadow(color: .white.opacity(0.7), radius: 2, y: 0)

            Text(NSLocalizedString("family_setup_subtitle", comment: ""))
                .font(.zenMaru(13, weight: .bold))
                .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
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
                    .kazumonFixedButton(color: KazumonTheme.grass)
            }
            .disabled(setupSelection.isEmpty)
            .opacity(setupSelection.isEmpty ? 0.5 : 1.0)

            Button {
                HapticsManager.tap()
                onBack()
            } label: {
                Text(NSLocalizedString("battle_shop_back", comment: ""))
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                    .padding(.horizontal, 20).padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.7)))
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
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected
                          ? Color(red: 0.95, green: 0.55, blue: 0.30)
                          : Color.white.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.6),
                            lineWidth: 2)
            )
        }
        .disabled(isSelf)
    }

    private var backButton: some View {
        Button {
            HapticsManager.tap()
            onBack()
        } label: {
            Text(NSLocalizedString("battle_shop_back", comment: ""))
                .font(.zenMaru(16, weight: .black))
                .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                .padding(.horizontal, 22).padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.7)))
        }
    }
}
