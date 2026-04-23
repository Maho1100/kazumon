#if DEBUG
import SwiftUI
import UserNotifications

struct DebugPanelView: View {
    let gameVM: GameViewModel
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var vm = TitleViewModel()
    @State private var selectedFloor: Int = 1
    @State private var selectedChallengeDay: Int = 1
    @State private var showMistakeWarningPreview = false
    @State private var showTimeBossWarningPreview = false

    var body: some View {
        NavigationStack {
            List {
                DisclosureGroup("課金") {
                    HStack {
                        Text("現在: \(PurchaseManager.shared.isPro ? "Pro ✅" : "無料 🔒")")
                            .font(.zenMaru(14))
                        Spacer()
                        Button(PurchaseManager.shared.isPro ? "無料に切替" : "Proに切替") {
                            PurchaseManager.shared.isPro.toggle()
                            UserDefaults.standard.set(PurchaseManager.shared.isPro, forKey: "kazumon_is_pro")
                            vm.refresh()
                        }
                        .font(.zenMaru(13, weight: .bold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(PurchaseManager.shared.isPro ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                DisclosureGroup("プレイ回数") {
                    Button("🔧 回数リセット (→ 0)") {
                        var mission = DataStore.loadDailyMission()
                        mission.playCount = 0
                        mission.claimed = false
                        DataStore.saveDailyMission(mission)
                        vm.refresh()
                    }
                    Text("現在: \(DataStore.todayPlayCount())回 / 上限\(PurchaseManager.maxFreePlayCount)回")
                        .font(.zenMaru(12)).foregroundColor(.secondary)
                }

                DisclosureGroup("レベル") {
                    HStack(spacing: 8) {
                        ForEach([1, 5, 10, 20], id: \.self) { lv in
                            Button("Lv\(lv)") { vm.setDebugLevel(lv) }
                                .buttonStyle(.borderless)
                                .font(.zenMaru(12, weight: .bold))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    Button("🔧 レベルリセット (→ Lv.1)") { vm.setDebugLevel(1) }
                    Text("現在: Lv.\(vm.playerData.level)  stage=\(CharacterAppearanceFactory.stage(for: vm.playerData.level).displayName)")
                        .font(.zenMaru(12)).foregroundColor(.secondary)
                }

                DisclosureGroup("ショップ解放") {
                    Button {
                        if vm.playerData.level < 5 { vm.setDebugLevel(5) }
                    } label: {
                        Text("👕 きせかえショップ解放 (Lv5↑)")
                            .font(.zenMaru(13, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Capsule().fill(Color.purple))
                    }.buttonStyle(.plain)

                    Button {
                        if vm.playerData.level < 3 { vm.setDebugLevel(3) }
                    } label: {
                        Text("🔄 こうかんじょ解放 (Lv3↑)")
                            .font(.zenMaru(13, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Capsule().fill(Color.orange))
                    }.buttonStyle(.plain)
                }

                DisclosureGroup("XP・経験値") {
                    HStack(spacing: 8) {
                        ForEach([50, 100, 200, 500], id: \.self) { amount in
                            Button("+\(amount)") {
                                var player = DataStore.loadPlayerData()
                                _ = DataStore.addXP(amount, to: &player)
                                DataStore.savePlayerData(player)
                                vm.refresh()
                            }
                            .buttonStyle(.borderless)
                            .font(.zenMaru(12, weight: .bold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    Button("🔧 XPリセット (→ 0)") {
                        var player = DataStore.loadPlayerData()
                        player.totalXP = 0; player.level = 1
                        DataStore.savePlayerData(player)
                        vm.refresh()
                    }
                    Button("🔧 タブフラグリセット") {
                        UserDefaults.standard.removeObject(forKey: "kazumon_has_started_once")
                        UserDefaults.standard.removeObject(forKey: "kazumon_tapped_tabs")
                        vm.refresh()
                    }.buttonStyle(.borderless)
                    Text("現在: totalXP=\(vm.playerData.totalXP)  Lv.\(vm.playerData.level)")
                        .font(.zenMaru(12)).foregroundColor(.secondary)
                }

                DisclosureGroup("コイン") {
                    HStack(spacing: 8) {
                        ForEach([100, 500, 1000, 5000], id: \.self) { amount in
                            Button("+\(amount)") { DataStore.addCoins(amount) }
                                .buttonStyle(.borderless)
                                .font(.zenMaru(12, weight: .bold))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    Button("🔧 コインリセット (→ 0)") { DataStore.saveCoins(0) }
                    Text("現在: \(DataStore.loadCoins()) コイン")
                        .font(.zenMaru(12)).foregroundColor(.secondary)
                }

                DisclosureGroup("きせかえ・ツノ") {
                    Toggle("ツノタブ解放", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "debug_detail_unlocked") },
                        set: { UserDefaults.standard.set($0, forKey: "debug_detail_unlocked") }
                    )).font(.zenMaru(14))
                }

                DisclosureGroup("スタートフロア") {
                    Stepper("フロア: \(selectedFloor)F", value: $selectedFloor, in: 1...99)
                        .font(.zenMaru(14))
                    Button("🔧 このフロアからスタート") {
                        gameVM.debugStartFromFloor(selectedFloor)
                        dismiss(); onDismiss()
                    }
                    .font(.zenMaru(13, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(Color.purple).clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    Text("※ 無料ユーザーで30F以上を指定すると制限テストができます")
                        .font(.zenMaru(11)).foregroundColor(.secondary)
                }

                DisclosureGroup("30日チャレンジ") {
                    let challenge = DataStore.loadChallenge()
                    Text("現在: Day \(challenge.currentDay) / 完了: \(challenge.completedDays.count)日")
                        .font(.zenMaru(12)).foregroundColor(.secondary)
                    Text("フェーズ: \(ChallengeConfig.phaseName(for: challenge.currentDay))")
                        .font(.zenMaru(12)).foregroundColor(.secondary)
                    Stepper("Day: \(selectedChallengeDay)", value: $selectedChallengeDay, in: 1...30)
                        .font(.zenMaru(14))
                    Button("⚔️ このDayでチャレンジ開始") {
                        var c = DataStore.loadChallenge()
                        if !c.isActive { c = DataStore.startChallenge() }
                        c.currentDay = selectedChallengeDay
                        DataStore.saveChallenge(c)
                        gameVM.startChallengeDay(selectedChallengeDay)
                        dismiss(); onDismiss()
                    }
                    .font(.zenMaru(13, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(Color.orange).clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    Button("🗑 チャレンジリセット") {
                        DataStore.resetChallenge(); vm.refresh()
                    }.foregroundColor(.red)
                    Button("🔧 ビフォーテストリセット") {
                        UserDefaults.standard.removeObject(forKey: "kazumon_before_test_score")
                        UserDefaults.standard.removeObject(forKey: "kazumon_before_test_level")
                        UserDefaults.standard.removeObject(forKey: "kazumon_before_test_date")
                        vm.refresh()
                    }.foregroundColor(.red)
                    Button("🏆 Day30完了状態にする") {
                        var c = DataStore.loadChallenge()
                        if !c.isActive { c = DataStore.startChallenge() }
                        if !c.completedDays.contains(30) { c.completedDays.append(30) }
                        DataStore.saveChallenge(c)
                        UserDefaults.standard.removeObject(forKey: "kazumon_after_test_score")
                        UserDefaults.standard.removeObject(forKey: "kazumon_after_test_level")
                        UserDefaults.standard.removeObject(forKey: "kazumon_after_test_date")
                        gameVM.refreshTrigger += 1; vm.refresh()
                        dismiss(); onDismiss()
                    }.font(.zenMaru(13, weight: .bold)).foregroundColor(.orange)
                    Button("🔧 アフターテストリセット") {
                        UserDefaults.standard.removeObject(forKey: "kazumon_after_test_score")
                        UserDefaults.standard.removeObject(forKey: "kazumon_after_test_level")
                        UserDefaults.standard.removeObject(forKey: "kazumon_after_test_date")
                        gameVM.refreshTrigger += 1; vm.refresh()
                    }.foregroundColor(.red)
                }

                DisclosureGroup("プッシュ通知") {
                    Button("📩 通知許可をリクエスト") {
                        NotificationManager.shared.requestPermission()
                    }
                    Button("⏰ 5秒後にテスト通知（24h用）") {
                        let name = DataStore.loadPlayerData().playerName
                        NotificationManager.shared.cancelAll()
                        let content = UNMutableNotificationContent()
                        content.title = "\(name)がこないから😭"
                        content.body = "かずもんが ため息を 47かいも ついたよ！"
                        content.sound = .default
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                        let request = UNNotificationRequest(identifier: "debug_test", content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(request)
                    }
                    Button("🗑 保留中の通知をすべてキャンセル") {
                        NotificationManager.shared.cancelAll()
                    }
                    Text("※ 通知テストはアプリをバックグラウンドにしてから届きます")
                        .font(.zenMaru(11)).foregroundColor(.secondary)
                }

                DisclosureGroup("まちがいおに") {
                    let mistakeCount = DataStore.loadMistakeLog().count
                    let totalCount = DataStore.loadTotalMistakeCount()
                    let scheduled = DataStore.isMistakeBossScheduledToday()
                    Text("MistakeLog: \(mistakeCount)問 / 累計カウンター: \(totalCount)/\(MistakeBossConfig.appearanceThreshold)")
                        .font(.zenMaru(12)).foregroundColor(.secondary)
                    Text("今日出現予定: \(scheduled ? "YES" : "NO")")
                        .font(.zenMaru(12)).foregroundColor(scheduled ? .red : .secondary)
                    Button("📋 累計カウンターを10にする（即スケジュール）") {
                        let current = DataStore.loadTotalMistakeCount()
                        let needed = MistakeBossConfig.appearanceThreshold - current
                        for _ in 0..<max(needed, 0) { DataStore.incrementTotalMistakeCount() }
                        vm.refresh()
                    }
                    Button("📅 今日の出現を即セット") {
                        DataStore.scheduleMistakeBoss()
                        vm.refresh()
                    }
                    Button("🗑 カウンターリセット") {
                        DataStore.resetTotalMistakeCount()
                        DataStore.clearMistakeBossSchedule()
                        vm.refresh()
                    }.foregroundColor(.red)
                }

                DisclosureGroup("じかんどろぼう") {
                    let timeBossScheduled = DataStore.isTimeBossScheduledToday()
                    let timeBossDefeated = DataStore.isTimeBossDefeated()
                    Text("今日出現予定: \(timeBossScheduled ? "YES" : "NO")")
                        .font(.zenMaru(12)).foregroundColor(timeBossScheduled ? .red : .secondary)
                    Text("撃破済み: \(timeBossDefeated ? "YES" : "NO")")
                        .font(.zenMaru(12)).foregroundColor(.secondary)
                    Button("📅 じかんどろぼうを即スケジュール") {
                        DataStore.scheduleTimeBoss()
                        vm.refresh()
                    }
                    Button("🗑 じかんどろぼうリセット") {
                        DataStore.clearTimeBossSchedule()
                        DataStore.resetTimeBossDefeated()
                        vm.refresh()
                    }.foregroundColor(.red)
                }

                DisclosureGroup("予告演出プレビュー") {
                    Button("👹 まちがいおに予告") {
                        showMistakeWarningPreview = true
                    }
                    .font(.zenMaru(14, weight: .bold))
                    Button("⏰ じかんどろぼう予告") {
                        showTimeBossWarningPreview = true
                    }
                    .font(.zenMaru(14, weight: .bold))
                }

                DisclosureGroup("パーツ調整") {
                    NavigationLink("パーツ位置調整を開く") {
                        CharacterLayoutDebugView()
                    }
                    .font(.zenMaru(14, weight: .bold))
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("🔧 デバッグパネル")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss(); onDismiss() }
                }
            }
            .fullScreenCover(isPresented: $showMistakeWarningPreview) {
                MistakeOniWarningView { showMistakeWarningPreview = false }
            }
            .fullScreenCover(isPresented: $showTimeBossWarningPreview) {
                TimeBossWarningView { showTimeBossWarningPreview = false }
            }
        }
    }
}
#endif
