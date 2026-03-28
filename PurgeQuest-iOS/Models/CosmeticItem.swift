// Models/CosmeticItem.swift
// Hero skins, weapons, pets – purchased with Storage Gems

import SwiftData
import Foundation

@Model
final class CosmeticItem {
    var id: String
    var type: CosmeticType
    var displayName: String
    var flavorText: String
    var sfSymbol: String
    var colorHex: String
    var gemCost: Int
    var isUnlocked: Bool
    var isPremiumOnly: Bool
    var unlockedAt: Date?

    init(id: String, type: CosmeticType, displayName: String, flavorText: String,
         sfSymbol: String, colorHex: String, gemCost: Int,
         isUnlocked: Bool = false, isPremiumOnly: Bool = false) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.flavorText = flavorText
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.gemCost = gemCost
        self.isUnlocked = isUnlocked
        self.isPremiumOnly = isPremiumOnly
        self.unlockedAt = isUnlocked ? .now : nil
    }

    static var defaults: [CosmeticItem] {[
        // ─ Skins (always start unlocked: knight) ─────────────────────
        CosmeticItem(id: "skin_knight",    type: .skin, displayName: "Iron Knight",
                     flavorText: "Born in the dungeon of defaults.",
                     sfSymbol: "person.fill", colorHex: "#8A9BB0", gemCost: 0, isUnlocked: true),
        CosmeticItem(id: "skin_wizard",    type: .skin, displayName: "Archive Wizard",
                     flavorText: "Knows which photos to vanish.",
                     sfSymbol: "theatermask.and.paintbrush.fill", colorHex: "#7B5EA7", gemCost: 200),
        CosmeticItem(id: "skin_ninja",     type: .skin, displayName: "Delete Ninja",
                     flavorText: "Silent. Surgical. Zero duplicates.",
                     sfSymbol: "figure.walk.motion", colorHex: "#2D2D2D", gemCost: 350),
        CosmeticItem(id: "skin_paladin",   type: .skin, displayName: "Storage Paladin",
                     flavorText: "Holy light destroys JPEG artifacts.",
                     sfSymbol: "shield.lefthalf.filled.badge.checkmark", colorHex: "#F4D35E", gemCost: 500, isPremiumOnly: true),
        CosmeticItem(id: "skin_astronaut", type: .skin, displayName: "Space Archivist",
                     flavorText: "No storage limits in the cosmos.",
                     sfSymbol: "moon.stars.fill", colorHex: "#0D1B2A", gemCost: 750, isPremiumOnly: true),

        // ─ Weapons ───────────────────────────────────────────────────
        CosmeticItem(id: "weapon_broom",   type: .weapon, displayName: "Pixel Broom",
                     flavorText: "Every hero starts here.",
                     sfSymbol: "wand.and.sparkles", colorHex: "#C8A96E", gemCost: 0, isUnlocked: true),
        CosmeticItem(id: "weapon_sword",   type: .weapon, displayName: "Delete Sword",
                     flavorText: "+5% swipe speed (visual only).",
                     sfSymbol: "bolt.fill", colorHex: "#E84545", gemCost: 150),
        CosmeticItem(id: "weapon_staff",   type: .weapon, displayName: "Blur-Bane Staff",
                     flavorText: "Specifically effective against Blurry Beasts.",
                     sfSymbol: "wand.and.rays", colorHex: "#9B59B6", gemCost: 300),
        CosmeticItem(id: "weapon_axe",     type: .weapon, displayName: "Dupe Axe",
                     flavorText: "Cleaves through clone clusters.",
                     sfSymbol: "scissors.circle.fill", colorHex: "#E67E22", gemCost: 450, isPremiumOnly: true),
        CosmeticItem(id: "weapon_ultimate",type: .weapon, displayName: "Eternal Purge Blade",
                     flavorText: "Forged from 10,000 deleted screenshots.",
                     sfSymbol: "sparkles.rectangle.stack.fill", colorHex: "#F7C948", gemCost: 1000, isPremiumOnly: true),

        // ─ Pets ──────────────────────────────────────────────────────
        CosmeticItem(id: "pet_pixel_cat",  type: .pet, displayName: "Pixel Cat",
                     flavorText: "Meows at every delete. Purrs at combos.",
                     sfSymbol: "pawprint.fill", colorHex: "#F1A7B5", gemCost: 250),
        CosmeticItem(id: "pet_mini_dragon",type: .pet, displayName: "Tamed Dupe Dragon",
                     flavorText: "A reformed duplicate. Now fights for good.",
                     sfSymbol: "flame.circle", colorHex: "#FF6B35", gemCost: 400, isPremiumOnly: true),
        CosmeticItem(id: "pet_ghost",      type: .pet, displayName: "Screenshot Ghost",
                     flavorText: "It deletes what it once was.",
                     sfSymbol: "bubble.middle.bottom.fill", colorHex: "#BDC3C7", gemCost: 500, isPremiumOnly: true),
    ]}
}

enum CosmeticType: String, Codable, CaseIterable {
    case skin   = "Skin"
    case weapon = "Weapon"
    case pet    = "Pet"

    var icon: String {
        switch self {
        case .skin:   return "person.crop.circle"
        case .weapon: return "bolt"
        case .pet:    return "pawprint"
        }
    }
}
