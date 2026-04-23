import SwiftUI

struct KisekaeShopView: View {
    let gameVM: GameViewModel
    let onDismiss: () -> Void

    @State private var coins: Int = DataStore.loadCoins()
    @State private var purchasedColors: Set<String> = DataStore.loadPurchasedColors()
    @State private var selectedColor: String = DataStore.loadSelectedBodyColor()
    @State private var purchasedDetails: Set<String> = DataStore.loadPurchasedDetails()
    @State private var selectedDetail: String = DataStore.loadSelectedDetailType()
    @State private var showPurchaseConfirm = false
    @State private var confirmTarget: ShopItem?
    @State private var fadeIn: Double = 0
    @State private var tab: Int = 0  // 0=色, 1=ツノ
    private var isDetailUnlocked: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "debug_detail_unlocked")
        #else
        return false  // リリース時は開発中
        #endif
    }

    // MARK: - 商品定義

    @State private var showComingSoon = false

    struct ShopItem: Identifiable {
        let id: String
        let nameKey: String
        let price: Int
        let bgColor: Color
        let category: String  // "color" or "detail"
        let unlockFloor: Int  // 解放に必要なbestFloor（0=最初から）
        let unlockHintKey: String  // 解放条件の説明キー
        var unlockStreak: Int = 0  // ストリーク日数で解放（0=条件なし）
    }

    let colorItems: [ShopItem] = [
        ShopItem(id: "blue",   nameKey: "kisekae_color_blue",   price: 0,   bgColor: Color(red: 0.35, green: 0.75, blue: 0.95), category: "color", unlockFloor: 0,  unlockHintKey: ""),
        ShopItem(id: "green",  nameKey: "kisekae_color_green",  price: 100, bgColor: Color(red: 0.30, green: 0.75, blue: 0.40), category: "color", unlockFloor: 20, unlockHintKey: "kisekae_unlock_20f"),
        ShopItem(id: "red",    nameKey: "kisekae_color_red",    price: 100, bgColor: Color(red: 0.90, green: 0.35, blue: 0.30), category: "color", unlockFloor: 30, unlockHintKey: "kisekae_unlock_30f"),
        ShopItem(id: "yellow", nameKey: "kisekae_color_yellow", price: 150, bgColor: Color(red: 0.95, green: 0.80, blue: 0.20), category: "color", unlockFloor: 10, unlockHintKey: "kisekae_unlock_10f"),
        ShopItem(id: "dark",   nameKey: "kisekae_color_dark",   price: 200, bgColor: Color(red: 0.25, green: 0.25, blue: 0.30), category: "color", unlockFloor: 20, unlockHintKey: "kisekae_unlock_20f"),
        ShopItem(id: "white",  nameKey: "kisekae_color_white",  price: 200, bgColor: Color(red: 0.80, green: 0.80, blue: 0.85), category: "color", unlockFloor: 30, unlockHintKey: "kisekae_unlock_30f"),
        ShopItem(id: "pink",   nameKey: "kisekae_color_pink",   price: 0,   bgColor: Color(red: 0.95, green: 0.60, blue: 0.75), category: "color", unlockFloor: 0, unlockHintKey: "kisekae_unlock_streak7", unlockStreak: 7),
        ShopItem(id: "gold",   nameKey: "kisekae_color_gold",   price: 0,   bgColor: Color(red: 0.90, green: 0.75, blue: 0.30), category: "color", unlockFloor: 0, unlockHintKey: "kisekae_unlock_streak14", unlockStreak: 14),
    ]

    let detailItems: [ShopItem] = [
        ShopItem(id: "none",             nameKey: "kisekae_detail_none",       price: 0,    bgColor: .gray.opacity(0.5), category: "detail", unlockFloor: 0, unlockHintKey: ""),
        ShopItem(id: "horn_x1",          nameKey: "kisekae_detail_horn_1",     price: 500,  bgColor: Color(red: 0.85, green: 0.50, blue: 0.30), category: "detail", unlockFloor: 0, unlockHintKey: ""),
        ShopItem(id: "horn_x2",          nameKey: "kisekae_detail_horn_2",     price: 750,  bgColor: Color(red: 0.90, green: 0.45, blue: 0.25), category: "detail", unlockFloor: 0, unlockHintKey: ""),
        ShopItem(id: "horn_x3",          nameKey: "kisekae_detail_horn_3",     price: 1000, bgColor: Color(red: 0.95, green: 0.40, blue: 0.20), category: "detail", unlockFloor: 0, unlockHintKey: ""),
        ShopItem(id: "antenna_x1",       nameKey: "kisekae_detail_ant_1",      price: 500,  bgColor: Color(red: 0.50, green: 0.70, blue: 0.90), category: "detail", unlockFloor: 0, unlockHintKey: ""),
        ShopItem(id: "antenna_x2",       nameKey: "kisekae_detail_ant_2",      price: 750,  bgColor: Color(red: 0.45, green: 0.65, blue: 0.95), category: "detail", unlockFloor: 0, unlockHintKey: ""),
        ShopItem(id: "antenna_x3",       nameKey: "kisekae_detail_ant_3",      price: 1000, bgColor: Color(red: 0.40, green: 0.60, blue: 1.00), category: "detail", unlockFloor: 0, unlockHintKey: ""),
        ShopItem(id: "ear_x2",           nameKey: "kisekae_detail_ear_2",      price: 1000, bgColor: Color(red: 0.70, green: 0.50, blue: 0.80), category: "detail", unlockFloor: 0, unlockHintKey: ""),
        ShopItem(id: "ear_round_x2",     nameKey: "kisekae_detail_ear_r_2",    price: 1000, bgColor: Color(red: 0.65, green: 0.55, blue: 0.85), category: "detail", unlockFloor: 0, unlockHintKey: ""),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.90, green: 0.55, blue: 0.85), Color(red: 0.70, green: 0.30, blue: 0.65)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        gameVM.refreshTrigger += 1
                        onDismiss()
                    } label: {
                        Text(NSLocalizedString("battle_shop_back", comment: ""))
                            .font(.zenMaru(16, weight: .bold)).foregroundColor(.white.opacity(0.7))
                            .frame(height: 44).contentShape(Rectangle())
                    }.padding()
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                        Text("\(coins)").font(.zenMaru(18, weight: .black)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.3)))
                    .padding()
                }

                // プレビュー（タイトル削除、キャラを小さく）
                ZStack {
                    Circle().fill(Color.white.opacity(0.15)).frame(width: 100, height: 100)
                    KennyCharacterView(
                        appearance: previewAppearance(),
                        size: 60
                    ).allowsHitTesting(false)
                }
                .padding(.vertical, 8)
                .allowsHitTesting(false)

                // タブ切り替え
                HStack(spacing: 0) {
                    tabButton(NSLocalizedString("kisekae_tab_color", comment: ""), isSelected: tab == 0) { tab = 0 }
                    // ツノタブ（開発中は鍵付き）
                    Button(action: {
                        if isDetailUnlocked {
                            HapticsManager.tap(); SoundManager.shared.playTap(); tab = 1
                        } else {
                            showComingSoon = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showComingSoon = false }
                        }
                    }) {
                        HStack(spacing: 4) {
                            if !isDetailUnlocked {
                                Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
                            }
                            Text(NSLocalizedString("kisekae_tab_detail", comment: ""))
                                .font(.zenMaru(14, weight: .black))
                                .foregroundColor(tab == 1 ? .white : .white.opacity(isDetailUnlocked ? 0.5 : 0.3))
                        }
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(tab == 1 ? Color.white.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 12)

                // グリッド
                ScrollView {
                    if tab == 0 {
                        colorGrid
                    } else if isDetailUnlocked {
                        detailGrid
                    }
                }

                Spacer()
            }

            if showPurchaseConfirm, let target = confirmTarget {
                purchaseOverlay(target)
            }

            // 準備中メッセージ
            if showComingSoon {
                Text(NSLocalizedString("kisekae_coming_soon", comment: ""))
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.6)))
                    .transition(.opacity)
            }
        }
        .opacity(fadeIn)
        .onAppear {
            AnalyticsManager.trackScreenEnter("kisekae_shop")
            withAnimation(.easeOut(duration: 0.3)) { fadeIn = 1 }
        }
    }

    // MARK: - プレビュー

    private func previewAppearance() -> CharacterAppearance {
        let stage = CharacterAppearanceFactory.stage(for: gameVM.playerData.level)
        return CharacterAppearanceFactory.appearance(for: stage, color: selectedColor, detailType: selectedDetail)
    }

    // MARK: - タブボタン

    @ViewBuilder
    private func tabButton(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { HapticsManager.tap(); SoundManager.shared.playTap(); action() }) {
            Text(text)
                .font(.zenMaru(14, weight: .black))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity).frame(height: 36)
                .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 色グリッド

    private var bestFloor: Int { gameVM.playerData.bestFloor }

    private var colorGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(colorItems) { item in
                let floorUnlocked = bestFloor >= item.unlockFloor
                let streakUnlocked = item.unlockStreak == 0 || DataStore.loadPlayerData().bestStreak >= item.unlockStreak
                let isLocked = !floorUnlocked || !streakUnlocked
                let owned = purchasedColors.contains(item.id)

                shopCell(item, isOwned: owned, isSelected: selectedColor == item.id, isFloorLocked: isLocked) {
                    if isLocked {
                        // フロア未到達 → ヒント表示
                        return
                    }
                    if owned {
                        selectedColor = item.id
                        DataStore.saveSelectedBodyColor(item.id)
                        HapticsManager.tap(); SoundManager.shared.playTap()
                    } else {
                        confirmTarget = item
                        showPurchaseConfirm = true
                    }
                }
            }
        }.padding(.horizontal, 24)
    }

    // MARK: - ツノグリッド

    private var detailGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(detailItems) { item in
                let owned = purchasedDetails.contains(item.id)
                shopCell(item, isOwned: owned, isSelected: selectedDetail == item.id, isFloorLocked: false) {
                    if owned {
                        selectedDetail = item.id
                        DataStore.saveSelectedDetailType(item.id)
                        HapticsManager.tap(); SoundManager.shared.playTap()
                    } else {
                        confirmTarget = item
                        showPurchaseConfirm = true
                    }
                }
            }
        }.padding(.horizontal, 24)
    }

    // MARK: - 共通セル

    @ViewBuilder
    private func shopCell(_ item: ShopItem, isOwned: Bool, isSelected: Bool, isFloorLocked: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isFloorLocked ? Color.gray.opacity(0.4) : item.bgColor.opacity(0.85))
                        .frame(width: 90, height: 90)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.white : Color.clear, lineWidth: 3))
                        .shadow(color: isSelected ? .white.opacity(0.4) : .clear, radius: 6)

                    if isFloorLocked {
                        Image(systemName: "lock.fill").font(.system(size: 28, weight: .bold)).foregroundColor(.white.opacity(0.7))
                    } else if !isOwned && coins < item.price {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 24, weight: .bold)).foregroundColor(.red.opacity(0.8))
                    } else if !isOwned {
                        Image(systemName: "dollarsign.circle").font(.system(size: 24, weight: .bold)).foregroundColor(.yellow.opacity(0.9))
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundColor(.white).offset(x: 28, y: -28)
                    }

                    if item.category == "detail" && item.id != "none" && isOwned && !isFloorLocked {
                        let spriteName = "detail_\(selectedColor)_\(item.id)"
                        if spriteFrames[spriteName] != nil {
                            SpriteView(frameName: spriteName, displayWidth: 40)
                                .allowsHitTesting(false)
                        }
                    }
                }

                Text(NSLocalizedString(item.nameKey, comment: ""))
                    .font(.zenMaru(11, weight: .bold)).foregroundColor(.white)

                if isFloorLocked {
                    // フロア解放条件
                    Text(NSLocalizedString(item.unlockHintKey, comment: ""))
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.white.opacity(0.5))
                } else if !isOwned {
                    HStack(spacing: 2) {
                        Image(systemName: "dollarsign.circle.fill").font(.system(size: 10)).foregroundColor(.yellow)
                        Text("\(item.price)").font(.zenMaru(11, weight: .bold)).foregroundColor(.yellow)
                    }
                } else {
                    Text(NSLocalizedString("kisekae_owned", comment: ""))
                        .font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
                }
            }
        }.buttonStyle(.plain)
    }

    // MARK: - 購入確認

    @ViewBuilder
    private func purchaseOverlay(_ item: ShopItem) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { showPurchaseConfirm = false; confirmTarget = nil }

            VStack(spacing: 20) {
                Text(NSLocalizedString("kisekae_buy_confirm", comment: ""))
                    .font(.zenMaru(20, weight: .black)).foregroundColor(.white).multilineTextAlignment(.center)

                Text(NSLocalizedString(item.nameKey, comment: ""))
                    .font(.zenMaru(24, weight: .black)).foregroundColor(item.bgColor)

                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                    Text("\(item.price)").font(.zenMaru(22, weight: .black)).foregroundColor(.yellow)
                }

                HStack(spacing: 16) {
                    Button {
                        showPurchaseConfirm = false; confirmTarget = nil
                    } label: {
                        Text(NSLocalizedString("kisekae_cancel", comment: ""))
                            .font(.zenMaru(16, weight: .bold)).foregroundColor(.white)
                            .frame(width: 110, height: 48)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.5)))
                    }

                    Button {
                        if DataStore.spendCoins(item.price) {
                            if item.category == "color" {
                                purchasedColors.insert(item.id)
                                DataStore.savePurchasedColors(purchasedColors)
                                selectedColor = item.id
                                DataStore.saveSelectedBodyColor(item.id)
                            } else {
                                purchasedDetails.insert(item.id)
                                DataStore.savePurchasedDetails(purchasedDetails)
                                selectedDetail = item.id
                                DataStore.saveSelectedDetailType(item.id)
                            }
                            coins = DataStore.loadCoins()
                            HapticsManager.tap(); SoundManager.shared.playTap()
                        }
                        showPurchaseConfirm = false; confirmTarget = nil
                    } label: {
                        Text(NSLocalizedString("kisekae_buy", comment: ""))
                            .font(.zenMaru(18, weight: .black)).foregroundColor(.white)
                            .frame(width: 110, height: 48)
                            .background(RoundedRectangle(cornerRadius: 16).fill(coins >= item.price ? Color.orange : Color.gray))
                    }.disabled(coins < item.price)
                }

                if coins < item.price {
                    Text(NSLocalizedString("kisekae_not_enough", comment: ""))
                        .font(.zenMaru(13, weight: .bold)).foregroundColor(.red.opacity(0.9))
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.2, green: 0.2, blue: 0.25)))
            .padding(40)
        }
    }
}
