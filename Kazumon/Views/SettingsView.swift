import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    var onNameChanged: (() -> Void)?
    var onPlayWithChild: (() -> Void)?
    var showCloseButton: Bool = true

    @State private var name: String = ""
    @State private var saved = false
    @State private var showDashboard = false
    @State private var showVoiceRecorder = false
    @State private var currentAgeGroup: AgeGroup = DataStore.loadAgeGroup()
    @State private var magicStart: Int = DataStore.loadMagicTimeStart()
    @State private var magicLocked: Bool = DataStore.isMagicTimeChangeLocked()

    private let maxLength = 10

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - 名前変更
                    VStack(alignment: .leading, spacing: 8) {
                        Text("view_settings_player_name")
                            .font(.zenMaru(15, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        TextField(
                            NSLocalizedString("view_settings_player_name", comment: ""),
                            text: $name
                        )
                        .font(.zenMaru(22, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onChange(of: name) { _, newValue in
                            if newValue.count > maxLength {
                                name = String(newValue.prefix(maxLength))
                            }
                            saved = false
                        }
                        .padding(.horizontal, 20)

                        Button {
                            HapticsManager.tap(); SoundManager.shared.playTap()
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            DataStore.savePlayerName(trimmed)
                            saved = true
                            onNameChanged?()
                        } label: {
                            HStack(spacing: 8) {
                                if saved { Image(systemName: "checkmark") }
                                Text(saved ? "common_ok" : "view_settings_save")
                            }
                            .font(.zenMaru(18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 180, height: 50)
                            .background(saved ? Color.green : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .frame(maxWidth: .infinity)
                    }

                    Divider().padding(.horizontal, 20)

                    // MARK: - Pro版
                    if !PurchaseManager.shared.isPro {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                HapticsManager.tap(); SoundManager.shared.playTap()
                                AnalyticsManager.logPaywallView(source: "settings")
                                Task { try? await PurchaseManager.shared.purchase() }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    VStack(spacing: 2) {
                                        Text(NSLocalizedString("title_upgrade_pro", comment: ""))
                                            .font(.zenMaru(18, weight: .bold))
                                        if !PurchaseManager.shared.proDisplayPrice.isEmpty {
                                            Text(PurchaseManager.shared.proDisplayPrice)
                                                .font(.zenMaru(12, weight: .bold))
                                                .opacity(0.8)
                                        }
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .orange.opacity(0.3), radius: 6, y: 3)
                            }
                            .padding(.horizontal, 20)

                            Button {
                                HapticsManager.tap(); SoundManager.shared.playTap()
                                Task { try? await PurchaseManager.shared.restore() }
                            } label: {
                                Text(NSLocalizedString("title_restore_purchase", comment: ""))
                                    .font(.zenMaru(13))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        Divider().padding(.horizontal, 20)
                    }

                    // MARK: - 年齢グループ
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings_age_group")
                            .font(.zenMaru(15, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        HStack(spacing: 8) {
                            ForEach(AgeGroup.allCases, id: \.rawValue) { group in
                                ageGroupButton(group)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Divider().padding(.horizontal, 20)

                    // MARK: - 成長のきろく
                    Button {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        showDashboard = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                            Text("settings_growth_dashboard")
                                .font(.zenMaru(16, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showDashboard) {
                        ParentDashboardView()
                    }

                    Divider().padding(.horizontal, 20)

                    // MARK: - おうえんボイス
                    Button {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        showVoiceRecorder = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.pink)
                            Text("settings_voice_title")
                                .font(.zenMaru(16, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                            if DataStore.hasParentVoiceRecording() {
                                Text("settings_voice_recorded")
                                    .font(.zenMaru(12, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showVoiceRecorder) {
                        VoiceRecorderView()
                    }

                    Divider().padding(.horizontal, 20)

                    // MARK: - こどもと あそぶ
                    if onPlayWithChild != nil {
                        Button {
                            HapticsManager.tap(); SoundManager.shared.playTap()
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onPlayWithChild?()
                            }
                        } label: {
                            Text("settings_play_with_child")
                                .font(.zenMaru(18, weight: .black))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.50, green: 0.47, blue: 0.87)))
                                .shadow(color: Color(red: 0.50, green: 0.47, blue: 0.87).opacity(0.4), radius: 6, y: 3)
                        }
                        .padding(.horizontal, 20)

                        Divider().padding(.horizontal, 20)
                    }

                    // MARK: - まほうのじかん（全モード共通）
                    if true {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("settings_magic_time")
                                .font(.zenMaru(15, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("settings_magic_start")
                                        .font(.zenMaru(14))
                                    Spacer()
                                    if magicLocked {
                                        Text("\(magicStart):00 〜 \((magicStart + 1) % 24):00")
                                            .font(.zenMaru(14, weight: .bold))
                                            .foregroundColor(.secondary)
                                    } else {
                                        Picker("", selection: $magicStart) {
                                            ForEach(0..<24, id: \.self) { h in
                                                Text("\(h):00 〜 \((h + 1) % 24):00").tag(h)
                                            }
                                        }
                                        .labelsHidden()
                                        .onChange(of: magicStart) { _, v in
                                            DataStore.saveMagicTimeStart(v)
                                            magicLocked = true
                                        }
                                    }
                                }

                                if magicLocked {
                                    let hours = Int(DataStore.magicTimeChangeLockRemaining() / 3600)
                                    Text(String(format: NSLocalizedString("settings_magic_locked", comment: ""), hours))
                                        .font(.zenMaru(11))
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Divider().padding(.horizontal, 20)
                    }

                    // MARK: - アプリ情報
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings_app_info")
                            .font(.zenMaru(15, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        HStack {
                            Text("settings_version")
                                .font(.zenMaru(14))
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                                .font(.zenMaru(14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle(NSLocalizedString("view_settings_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCloseButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("view_title_bgm_close", comment: "")) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            AnalyticsManager.trackScreenEnter("settings")
            name = DataStore.loadPlayerName()
        }
    }

    private func ageGroupButton(_ group: AgeGroup) -> some View {
        let isSelected = group == currentAgeGroup
        return Button {
            HapticsManager.tap(); SoundManager.shared.playTap()
            DataStore.saveAgeGroup(group)
            currentAgeGroup = group
        } label: {
            VStack(spacing: 4) {
                KennyCharacterView(
                    appearance: CharacterAppearanceFactory.appearance(for: group.characterLevel),
                    size: 36
                )
                .allowsHitTesting(false)
                .frame(height: 44)
                Text(group.label)
                    .font(.zenMaru(12, weight: .bold))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange : Color(.systemGray5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
