import SwiftUI

// MARK: - 店の種類

enum ShopType: String, CaseIterable {
    case bgm        // BGMの店
    case start      // スタートボタン
    case costume    // きせかえの店
    case exchange   // こうかんじょ

    var label: String {
        switch self {
        case .bgm:      return NSLocalizedString("island_label_bgm", comment: "")
        case .start:    return NSLocalizedString("island_label_battle", comment: "")
        case .costume:  return NSLocalizedString("island_label_kisekae", comment: "")
        case .exchange: return NSLocalizedString("island_label_koukan", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .bgm:      return "music.note"
        case .start:    return "flame.fill"
        case .costume:  return "tshirt.fill"
        case .exchange: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .bgm:      return Color(red: 0.35, green: 0.75, blue: 0.95)
        case .start:    return Color(red: 1.0, green: 0.45, blue: 0.35)
        case .costume:  return Color(red: 0.90, green: 0.55, blue: 0.85)
        case .exchange: return Color(red: 0.95, green: 0.75, blue: 0.30)
        }
    }

    /// 島上の相対位置 (0〜1)
    var position: CGPoint {
        switch self {
        case .bgm:      return CGPoint(x: 0.12, y: 0.56)   // 島の左縁
        case .start:    return CGPoint(x: 0.50, y: 0.50)   // 島の頂上
        case .costume:  return CGPoint(x: 0.78, y: 0.35)
        case .exchange: return CGPoint(x: 0.75, y: 0.70)
        }
    }
}

// MARK: - 店アイコンビュー

struct IslandShopIcon: View {
    let shop: ShopType
    let isUnlocked: Bool
    let onTap: () -> Void

    @State private var floatOffset: CGFloat = 0
    @State private var rhythmScale: CGFloat = 1.0

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // 背景円
                    Circle()
                        .fill(
                            isUnlocked
                                ? shop.color.gradient
                                : Color.gray.opacity(0.5).gradient
                        )
                        .frame(width: shop == .start ? 72 : 56,
                               height: shop == .start ? 72 : 56)
                        .shadow(color: (isUnlocked ? shop.color : .gray).opacity(0.4),
                                radius: 8, y: 4)

                    // アイコン
                    Image(systemName: isUnlocked ? shop.icon : "lock.fill")
                        .font(.system(size: shop == .start ? 28 : 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(rhythmScale)

                // ラベル
                Text(shop.label)
                    .font(.zenMaru(shop == .start ? 13 : 11, weight: .bold))
                    .foregroundStyle(isUnlocked ? .white : .white.opacity(0.6))
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
        }
        .buttonStyle(.plain)
        .opacity(isUnlocked ? 1.0 : 0.7)
        .offset(y: isUnlocked ? 0 : floatOffset)
        .onAppear {
            // 未開放: ゆっくり浮遊
            if !isUnlocked {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    floatOffset = -6
                }
            }
            // BGM店: リズム拡縮
            if shop == .bgm && isUnlocked {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    rhythmScale = 1.08
                }
            }
        }
    }
}
