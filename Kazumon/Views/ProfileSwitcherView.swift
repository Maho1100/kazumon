import SwiftUI

/// プロフィール切り替え画面
struct ProfileSwitcherView: View {
    @Environment(\.dismiss) private var dismiss
    let onSwitch: () -> Void

    @State private var profiles: [PlayerProfile] = []
    @State private var activeId: String = ""
    @State private var showAddProfile = false
    @State private var deleteTarget: PlayerProfile? = nil
    @State private var showDeleteConfirm = false
    @State private var showProPlan = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(profiles) { profile in
                        HStack(spacing: 12) {
                            Button {
                                HapticsManager.tap(); SoundManager.shared.playTap()
                                DataStore.setActiveProfile(profile.id)
                                dismiss()
                                onSwitch()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: profile.avatarColor))
                                            .frame(width: 44, height: 44)
                                        Text(String(profile.name.prefix(1)))
                                            .font(.zenMaru(18, weight: .bold))
                                            .foregroundColor(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(profile.name)
                                            .font(.zenMaru(16, weight: .bold))
                                            .foregroundColor(.primary)
                                        Text(profile.ageGroup.label)
                                            .font(.zenMaru(12, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if profile.id.uuidString == activeId {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 22))
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            if profiles.count > 1 {
                                Button {
                                    deleteTarget = profile
                                    showDeleteConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if profiles.count < 3 {
                    Section {
                        Button {
                            if PurchaseManager.shared.isPro || profiles.count < 1 {
                                showAddProfile = true
                            } else {
                                AnalyticsManager.logViewPaywall(source: "profile_add")
                                showProPlan = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text(NSLocalizedString("profile_add_new", comment: ""))
                                    .font(.zenMaru(15, weight: .bold))
                                Spacer()
                                if !PurchaseManager.shared.isPro && profiles.count >= 1 {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                    Text("PRO")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("profile_switcher_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert("profile_delete_confirm", isPresented: $showDeleteConfirm) {
                Button("profile_delete_action", role: .destructive) {
                    guard let target = deleteTarget else { return }
                    let wasActive = target.id.uuidString == activeId
                    DataStore.deleteProfile(target.id)
                    profiles = DataStore.loadProfiles()
                    if wasActive, let first = profiles.first {
                        DataStore.setActiveProfile(first.id)
                        activeId = first.id.uuidString
                        onSwitch()
                    }
                    deleteTarget = nil
                }
                Button("profile_delete_cancel", role: .cancel) {
                    deleteTarget = nil
                }
            }
        }
        .onAppear {
            profiles = DataStore.loadProfiles()
            activeId = DataStore.activeProfileId()
        }
        .fullScreenCover(isPresented: $showAddProfile) {
            ParentSetupView {
                showAddProfile = false
                profiles = DataStore.loadProfiles()
                activeId = DataStore.activeProfileId()
                dismiss()
                onSwitch()
            }
        }
        .sheet(isPresented: $showProPlan) {
            ProPlanView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - プロプラン比較画面

struct ProPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false

    var body: some View {
        VStack(spacing: 16) {
            // ドラッグインジケーターの下にタイトル
            Text(NSLocalizedString("pro_plan_title", comment: ""))
                .font(.zenMaru(24, weight: .black))
                .padding(.top, 16)

            Text(NSLocalizedString("pro_plan_siblings_pitch", comment: ""))
                .font(.zenMaru(14, weight: .bold))
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)

            // 比較表（コンパクト）
            VStack(spacing: 0) {
                HStack {
                    Text("").frame(maxWidth: .infinity)
                    Text(NSLocalizedString("pro_plan_free", comment: ""))
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 70)
                    Text("PRO")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.orange)
                        .frame(width: 70)
                }
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.08))

                comparisonRow(NSLocalizedString("pro_feature_play", comment: ""),
                              free: NSLocalizedString("pro_free_play", comment: ""),
                              pro: NSLocalizedString("pro_pro_play", comment: ""))
                comparisonRow(NSLocalizedString("pro_feature_profile", comment: ""),
                              free: "1", pro: "3")
                comparisonRow(NSLocalizedString("pro_feature_floor", comment: ""),
                              free: "~20F", pro: NSLocalizedString("pro_pro_unlimited", comment: ""))
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            .padding(.horizontal, 20)

            // 購入ボタン
            if PurchaseManager.shared.isPro {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text(NSLocalizedString("pro_plan_already", comment: ""))
                        .font(.system(size: 15, weight: .bold))
                }
            } else {
                Button {
                    purchasing = true
                    Task {
                        try? await PurchaseManager.shared.purchase()
                        purchasing = false
                        if PurchaseManager.shared.isPro { dismiss() }
                    }
                } label: {
                    Text(NSLocalizedString("pro_plan_buy", comment: ""))
                        .font(.zenMaru(20, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 6, y: 3)
                }
                .disabled(purchasing)
                .padding(.horizontal, 32)
            }

            // 復元
            Button {
                Task { try? await PurchaseManager.shared.purchase() }
            } label: {
                Text(NSLocalizedString("pro_plan_restore", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func comparisonRow(_ feature: String, free: String, pro: String) -> some View {
        HStack {
            Text(feature)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            Text(free)
                .font(.system(size: 12)).foregroundColor(.secondary)
                .frame(width: 70)
            Text(pro)
                .font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                .frame(width: 70)
        }
        .padding(.vertical, 10)
        Divider().padding(.horizontal, 16)
    }
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
