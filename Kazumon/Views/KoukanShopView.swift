import SwiftUI

struct KoukanShopView: View {
    let gameVM: GameViewModel
    let onDismiss: () -> Void

    @State private var playerItems: [Item] = DataStore.loadItems()
    @State private var coins: Int = DataStore.loadCoins()
    @State private var fadeIn: Double = 0
    @State private var soldItemId: String?
    @State private var treeStock: Int = DataStore.loadTreeShopStock()
    @State private var showTreePurchasedToast: Bool = false

    /// アイテムの売却価格（item.sellPrice があればそれを優先、なければレアリティから計算）
    private func sellPrice(for item: Item) -> Int {
        if let custom = item.sellPrice { return custom }
        switch item.rarity {
        case .common:    return 10
        case .uncommon:  return 30
        case .rare:      return 80
        case .legendary: return 200
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.30, green: 0.65, blue: 0.85), Color(red: 0.20, green: 0.45, blue: 0.70)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button {
                        HapticsManager.tap(); SoundManager.shared.playTap()
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

                // タイトル
                Text(NSLocalizedString("koukan_title", comment: ""))
                    .font(.zenMaru(28, weight: .black)).foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .padding(.bottom, 8)

                Text(NSLocalizedString("koukan_desc", comment: ""))
                    .font(.zenMaru(14, weight: .bold)).foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 16)

                // 木の購入カード
                treePurchaseCard()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                // アイテム一覧
                if playerItems.isEmpty {
                    Spacer()
                    Text(NSLocalizedString("koukan_empty", comment: ""))
                        .font(.zenMaru(18, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(playerItems) { item in
                                itemRow(item)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()
            }
        }
        .opacity(fadeIn)
        .onAppear {
            AnalyticsManager.trackScreenEnter("koukan_shop")
            withAnimation(.easeOut(duration: 0.3)) { fadeIn = 1 }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: Item) -> some View {
        let price = sellPrice(for: item)
        let justSold = soldItemId == item.id

        HStack(spacing: 12) {
            // 絵文字
            Text(item.emoji).font(.system(size: 32))

            // 名前 + レアリティ
            VStack(alignment: .leading, spacing: 2) {
                Text(item.localizedName)
                    .font(.zenMaru(16, weight: .bold)).foregroundColor(.white)
                HStack(spacing: 4) {
                    Text(item.rarity.star).font(.system(size: 10))
                    Text("×\(item.count)")
                        .font(.zenMaru(13, weight: .bold)).foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            // 売るボタン
            Button {
                sellItem(item)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill").font(.system(size: 12)).foregroundColor(.yellow)
                    Text("\(price)")
                        .font(.zenMaru(14, weight: .black)).foregroundColor(.yellow)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12).fill(justSold ? Color.green : Color.orange))
            }
            .disabled(justSold)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))
    }

    private func sellItem(_ item: Item) {
        let price = sellPrice(for: item)
        DataStore.addCoins(price)
        coins = DataStore.loadCoins()

        // アイテムの count を減らす
        var items = DataStore.loadItems()
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].count -= 1
            if items[idx].count <= 0 {
                items.remove(at: idx)
            }
        }
        DataStore.saveItems(items)
        playerItems = items

        soldItemId = item.id
        HapticsManager.tap(); SoundManager.shared.playTap()
        SoundManager.shared.playCorrect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            soldItemId = nil
        }
    }

    @ViewBuilder
    private func treePurchaseCard() -> some View {
        let canBuy = treeStock > 0 && coins >= TreeConfig.costPerTree
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image("island_tree")
                    .resizable().scaledToFit()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("koukan_tree_name", comment: ""))
                        .font(.zenMaru(15, weight: .black)).foregroundColor(.white)
                    Text(NSLocalizedString("koukan_tree_desc", comment: ""))
                        .font(.zenMaru(11, weight: .bold)).foregroundColor(.white.opacity(0.7))
                    Text(String(format: NSLocalizedString("koukan_tree_stock", comment: ""), treeStock, TreeConfig.shopMaxStock, DataStore.daysUntilNextTreeRefill()))
                        .font(.zenMaru(10, weight: .bold)).foregroundColor(.yellow.opacity(0.9))
                }
                Spacer()
                Button {
                    purchaseTree()
                } label: {
                    VStack(spacing: 2) {
                        Text("\(TreeConfig.costPerTree)")
                            .font(.zenMaru(16, weight: .black))
                        Text(NSLocalizedString("koukan_coin_label", comment: "")).font(.zenMaru(10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(canBuy ? Color.green : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canBuy)
            }
            if showTreePurchasedToast {
                Text(NSLocalizedString("koukan_tree_purchased", comment: ""))
                    .font(.zenMaru(11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.green.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.15)))
    }

    private func purchaseTree() {
        guard treeStock > 0, coins >= TreeConfig.costPerTree else { return }
        coins -= TreeConfig.costPerTree
        DataStore.saveCoins(coins)
        DataStore.decrementTreeShopStock()
        treeStock = DataStore.loadTreeShopStock()
        // 植樹モードを有効化（NotificationCenter経由）
        NotificationCenter.default.post(name: .treePurchased, object: nil)
        HapticsManager.tap(); SoundManager.shared.playTap()
        SoundManager.shared.playCorrect()
        showTreePurchasedToast = true
        // ショップを閉じて島で植えられるように
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onDismiss()
        }
    }
}

extension Notification.Name {
    static let treePurchased = Notification.Name("treePurchased")
    static let activeProfileChanged = Notification.Name("activeProfileChanged")
}
