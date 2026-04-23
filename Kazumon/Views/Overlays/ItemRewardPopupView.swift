import SwiftUI

struct ItemRewardPopupView: View {
    let items: [Item]
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5

    private let textDark = Color(red: 0.18, green: 0.22, blue: 0.28)

    var body: some View {
        ZStack {
            // 半透明オーバーレイ
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // 報酬カード
            VStack(spacing: 16) {
                Text("📦")
                    .font(.system(size: 48))

                Text("view_overlay_new_item")
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(textDark)

                // アイテムリスト
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        HStack(spacing: 10) {
                            Text(item.emoji)
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.localizedName)
                                    .font(.zenMaru(17, weight: .bold))
                                    .foregroundColor(textDark)
                                Text(item.rarity.star)
                                    .font(.zenMaru(12))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(rarityBackground(item.rarity))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Text("view_overlay_item_hint")
                    .font(.zenMaru(13, weight: .bold))
                    .foregroundColor(.secondary)

                Button(action: dismiss) {
                    Text("OK")
                        .font(.zenMaru(18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 140, height: 48)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.01
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }

    private func rarityBackground(_ rarity: ItemRarity) -> Color {
        switch rarity {
        case .common:    return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .uncommon:  return Color(red: 0.90, green: 0.97, blue: 0.92)
        case .rare:      return Color(red: 0.90, green: 0.93, blue: 1.0)
        case .legendary: return Color(red: 0.97, green: 0.92, blue: 1.0)
        }
    }
}
