// Models/Achievement.swift
// SwiftData achievement record + static definitions

import Foundation
import SwiftData

// ─── Persisted record (tracks progress per hero) ──────────────────────────────

@Model
final class AchievementRecord {
    var definitionID: String
    var isUnlocked: Bool
    var progress: Int
    var unlockedAt: Date?

    init(definitionID: String) {
        self.definitionID = definitionID
        self.isUnlocked = false
        self.progress = 0
        self.unlockedAt = nil
    }
}

// ─── Static achievement definitions ──────────────────────────────────────────

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String          // SF Symbol or emoji
    let goal: Int
    let category: Category
    let gemReward: Int
    let xpReward: Int

    enum Category: String, CaseIterable {
        case combat    = "Combat"
        case storage   = "Storage"
        case streak    = "Streak"
        case collector = "Collector"
        case legendary = "Legendary"
    }

    static let all: [AchievementDefinition] = [
        // ─ Combat ──────────────────────────────────────────────────────
        AchievementDefinition(
            id: "first_blood", title: "First Blood",
            description: "Delete your first photo.",
            icon: "drop.fill", goal: 1, category: .combat, gemReward: 5, xpReward: 50
        ),
        AchievementDefinition(
            id: "dragon_slayer_10", title: "Dragon Slayer",
            description: "Defeat 10 Duplicate Dragons.",
            icon: "flame.fill", goal: 10, category: .combat, gemReward: 25, xpReward: 200
        ),
        AchievementDefinition(
            id: "monster_hunter_100", title: "Monster Hunter",
            description: "Delete 100 photos across any combat.",
            icon: "sword.fill", goal: 100, category: .combat, gemReward: 50, xpReward: 500
        ),
        AchievementDefinition(
            id: "combo_master_10", title: "Combo Master",
            description: "Achieve a 10-hit combo.",
            icon: "bolt.fill", goal: 10, category: .combat, gemReward: 30, xpReward: 250
        ),
        AchievementDefinition(
            id: "combo_god_25", title: "Combo God",
            description: "Achieve a 25-hit combo.",
            icon: "bolt.circle.fill", goal: 25, category: .combat, gemReward: 100, xpReward: 750
        ),
        AchievementDefinition(
            id: "boss_slayer", title: "Boss Slayer",
            description: "Defeat your first Corrupted Archive Boss.",
            icon: "crown.fill", goal: 1, category: .combat, gemReward: 150, xpReward: 1000
        ),
        AchievementDefinition(
            id: "boss_legend_5", title: "Boss Legend",
            description: "Defeat 5 bosses.",
            icon: "crown.circle.fill", goal: 5, category: .combat, gemReward: 300, xpReward: 2000
        ),
        AchievementDefinition(
            id: "purge_500", title: "The Great Purge",
            description: "Delete 500 photos.",
            icon: "trash.circle.fill", goal: 500, category: .combat, gemReward: 100, xpReward: 1000
        ),
        AchievementDefinition(
            id: "purge_1000", title: "Thousand Slain",
            description: "Delete 1,000 photos.",
            icon: "person.fill.xmark", goal: 1000, category: .combat, gemReward: 250, xpReward: 2500
        ),

        // ─ Storage ─────────────────────────────────────────────────────
        AchievementDefinition(
            id: "storage_100mb", title: "Space Cadet",
            description: "Free up 100 MB of storage.",
            icon: "externaldrive.badge.minus", goal: 100, category: .storage, gemReward: 20, xpReward: 100
        ),
        AchievementDefinition(
            id: "storage_1gb", title: "Gigabyte Guardian",
            description: "Free up 1 GB of storage.",
            icon: "externaldrive.fill", goal: 1000, category: .storage, gemReward: 100, xpReward: 500
        ),
        AchievementDefinition(
            id: "storage_10gb", title: "Storage Liberator",
            description: "Free up 10 GB of storage.",
            icon: "server.rack", goal: 10000, category: .storage, gemReward: 500, xpReward: 2500
        ),
        AchievementDefinition(
            id: "storage_50gb", title: "The Void Bringer",
            description: "Free up 50 GB of storage.",
            icon: "externaldrive.badge.checkmark", goal: 50000, category: .storage, gemReward: 2000, xpReward: 10000
        ),

        // ─ Streak ──────────────────────────────────────────────────────
        AchievementDefinition(
            id: "streak_3", title: "Returning Hero",
            description: "Play 3 days in a row.",
            icon: "calendar.badge.clock", goal: 3, category: .streak, gemReward: 15, xpReward: 100
        ),
        AchievementDefinition(
            id: "streak_7", title: "Weekly Warrior",
            description: "Maintain a 7-day streak.",
            icon: "flame.circle.fill", goal: 7, category: .streak, gemReward: 50, xpReward: 300
        ),
        AchievementDefinition(
            id: "streak_30", title: "Month of Mayhem",
            description: "Maintain a 30-day streak.",
            icon: "calendar.circle.fill", goal: 30, category: .streak, gemReward: 200, xpReward: 1500
        ),

        // ─ Collector ───────────────────────────────────────────────────
        AchievementDefinition(
            id: "all_monster_types", title: "Bestiary Complete",
            description: "Encounter every monster type.",
            icon: "books.vertical.fill", goal: 6, category: .collector, gemReward: 75, xpReward: 500
        ),
        AchievementDefinition(
            id: "cosmetic_3", title: "Fashionista Cleanser",
            description: "Unlock 3 cosmetic items.",
            icon: "tshirt.fill", goal: 3, category: .collector, gemReward: 25, xpReward: 150
        ),

        // ─ Legendary ───────────────────────────────────────────────────
        AchievementDefinition(
            id: "level_10", title: "Dungeon Cleanser",
            description: "Reach Level 10.",
            icon: "laurel.leading", goal: 10, category: .legendary, gemReward: 100, xpReward: 0
        ),
        AchievementDefinition(
            id: "level_25", title: "Legend Cleanser",
            description: "Reach Level 25.",
            icon: "laurel.trailing", goal: 25, category: .legendary, gemReward: 300, xpReward: 0
        ),
        AchievementDefinition(
            id: "level_50", title: "Grand Archivist",
            description: "Reach the maximum level: 50.",
            icon: "crown.fill", goal: 50, category: .legendary, gemReward: 1000, xpReward: 0
        ),
    ]

    static func definition(for id: String) -> AchievementDefinition? {
        all.first { $0.id == id }
    }
}
