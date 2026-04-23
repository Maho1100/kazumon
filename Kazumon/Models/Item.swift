import Foundation

enum ItemRarity: String, Codable, Sendable {
    case common
    case uncommon
    case rare
    case legendary

    var label: String {
        switch self {
        case .common:    return NSLocalizedString("model_rarity_common", comment: "")
        case .uncommon:  return NSLocalizedString("model_rarity_uncommon", comment: "")
        case .rare:      return NSLocalizedString("model_rarity_rare", comment: "")
        case .legendary: return NSLocalizedString("model_rarity_legendary", comment: "")
        }
    }

    var star: String {
        switch self {
        case .common:    return "⭐"
        case .uncommon:  return "⭐⭐"
        case .rare:      return "⭐⭐⭐"
        case .legendary: return "⭐⭐⭐⭐"
        }
    }

    var color: String {
        switch self {
        case .common:    return "gray"
        case .uncommon:  return "green"
        case .rare:      return "blue"
        case .legendary: return "purple"
        }
    }
}

struct Item: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let rarity: ItemRarity
    let emoji: String
    var count: Int = 1
    /// 売却価格（将来拡張用、デフォルトはレアリティから自動計算）
    var sellPrice: Int?

    /// 旧バージョンの JSON でも安全にデコードできるよう、新プロパティにはデフォルト値を設定
    init(id: String, name: String, rarity: ItemRarity, emoji: String, count: Int = 1, sellPrice: Int? = nil) {
        self.id = id; self.name = name; self.rarity = rarity; self.emoji = emoji
        self.count = count; self.sellPrice = sellPrice
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        rarity = try c.decode(ItemRarity.self, forKey: .rarity)
        emoji = try c.decode(String.self, forKey: .emoji)
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 1
        sellPrice = try c.decodeIfPresent(Int.self, forKey: .sellPrice)
    }

    /// Always returns the localized name based on `id`, regardless of what's stored in `name`.
    var localizedName: String {
        NSLocalizedString("model_item_\(id)", comment: "")
    }

    static let dropTable: [(item: Item, weight: Int)] = [
        (Item(id: "wooden_sword",   name: NSLocalizedString("model_item_wooden_sword", comment: ""),   rarity: .common,    emoji: "🗡️"), 25),
        (Item(id: "leather_shield", name: NSLocalizedString("model_item_leather_shield", comment: ""), rarity: .common,    emoji: "🛡️"), 25),
        (Item(id: "herb",           name: NSLocalizedString("model_item_herb", comment: ""),           rarity: .common,    emoji: "🌿"), 20),
        (Item(id: "iron_sword",     name: NSLocalizedString("model_item_iron_sword", comment: ""),     rarity: .uncommon,  emoji: "⚔️"), 12),
        (Item(id: "magic_ring",     name: NSLocalizedString("model_item_magic_ring", comment: ""),     rarity: .uncommon,  emoji: "💍"), 8),
        (Item(id: "fire_sword",     name: NSLocalizedString("model_item_fire_sword", comment: ""),     rarity: .rare,      emoji: "🔥"), 5),
        (Item(id: "ice_staff",      name: NSLocalizedString("model_item_ice_staff", comment: ""),      rarity: .rare,      emoji: "❄️"), 3),
        (Item(id: "dragon_crown",   name: NSLocalizedString("model_item_dragon_crown", comment: ""),   rarity: .legendary, emoji: "👑"), 2),
    ]

    static func randomDrop() -> Item? {
        let totalWeight = dropTable.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<totalWeight)
        for entry in dropTable {
            roll -= entry.weight
            if roll < 0 {
                return entry.item
            }
        }
        return dropTable.last?.item
    }
}
