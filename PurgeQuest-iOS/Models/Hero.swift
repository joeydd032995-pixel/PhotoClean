// Models/Hero.swift
// SwiftData model for the player's hero character

import SwiftUI
import SwiftData
import Foundation

@Model
final class Hero {
    var id: UUID
    var createdAt: Date

    // ─── Progression ───────────────────────────────────────────────
    var level: Int
    var currentXP: Int
    var totalXPEarned: Int
    var storageGemsEarned: Int          // 1 gem = 1 MB deleted
    var storageGemsSpent: Int
    var totalBytesDeleted: Int64        // actual bytes purged
    var totalPhotosDeleted: Int
    var totalPhotosSpared: Int
    var currentStreak: Int              // consecutive daily sessions
    var longestStreak: Int
    var lastSessionDate: Date?

    // ─── Combat Stats ───────────────────────────────────────────────
    var currentHP: Int
    var maxHP: Int
    var attackPower: Int                // base XP earned per delete
    var dungeonFloor: Int               // how deep they've gone (never resets)
    var bossesDefeated: Int
    var highestCombo: Int

    // ─── Cosmetics ──────────────────────────────────────────────────
    var equippedSkinID: String
    var equippedWeaponID: String
    var equippedPetID: String?

    // ─── Flags ──────────────────────────────────────────────────────
    var hasPremium: Bool

    init() {
        id = UUID()
        createdAt = .now
        level = 1
        currentXP = 0
        totalXPEarned = 0
        storageGemsEarned = 0
        storageGemsSpent = 0
        totalBytesDeleted = 0
        totalPhotosDeleted = 0
        totalPhotosSpared = 0
        currentStreak = 0
        longestStreak = 0
        lastSessionDate = nil
        currentHP = 100
        maxHP = 100
        attackPower = 10
        dungeonFloor = 0
        bossesDefeated = 0
        highestCombo = 0
        equippedSkinID = "skin_knight"
        equippedWeaponID = "weapon_broom"
        equippedPetID = nil
        hasPremium = false
    }

    // ─── Computed ────────────────────────────────────────────────────

    var heroClass: HeroClass {
        switch level {
        case 1...9:   return .clutterSlayer
        case 10...24: return .dungeonCleanser
        case 25...39: return .legendCleanser
        case 40...49: return .eternalPurger
        default:      return .grandArchivist
        }
    }

    var xpForNextLevel: Int {
        guard level < 50 else { return Int.max }
        return level * 150
    }

    var xpProgress: Double {
        guard level < 50 else { return 1.0 }
        return Double(currentXP) / Double(xpForNextLevel)
    }

    var storageGems: Int {
        storageGemsEarned - storageGemsSpent
    }

    var gbDeleted: Double {
        Double(totalBytesDeleted) / 1_073_741_824
    }

    var mbDeleted: Double {
        Double(totalBytesDeleted) / 1_048_576
    }

    // Returns true if a level-up occurred
    @discardableResult
    func addXP(_ amount: Int) -> Bool {
        guard level < 50 else { return false }
        currentXP += amount
        totalXPEarned += amount
        if currentXP >= xpForNextLevel {
            currentXP -= xpForNextLevel
            level += 1
            maxHP += 10
            currentHP = min(currentHP + 20, maxHP)
            attackPower += 2
            return true
        }
        return false
    }

    func addGems(_ amount: Int) {
        storageGemsEarned += amount
    }

    func spendGems(_ amount: Int) -> Bool {
        guard storageGems >= amount else { return false }
        storageGemsSpent += amount
        return true
    }

    func recordDelete(bytes: Int64) {
        totalBytesDeleted += bytes
        totalPhotosDeleted += 1
        // 1 gem per MB
        let newMB = Int(bytes / 1_048_576)
        if newMB > 0 { addGems(newMB) }
    }

    func takeDamage(_ amount: Int) {
        currentHP = max(0, currentHP - amount)
    }

    func heal(_ amount: Int) {
        currentHP = min(maxHP, currentHP + amount)
    }

    func updateStreak() {
        let cal = Calendar.current
        if let last = lastSessionDate, cal.isDateInYesterday(last) {
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else if let last = lastSessionDate, cal.isDateInToday(last) {
            // same day, no change
        } else {
            currentStreak = 1
        }
        lastSessionDate = .now
    }
}

// ─── Hero Class Enum ─────────────────────────────────────────────────────────

enum HeroClass: String, Codable {
    case clutterSlayer   = "Clutter Slayer"
    case dungeonCleanser = "Dungeon Cleanser"
    case legendCleanser  = "Legend Cleanser"
    case eternalPurger   = "Eternal Purger"
    case grandArchivist  = "Grand Archivist"

    var icon: String {
        switch self {
        case .clutterSlayer:   return "🧹"
        case .dungeonCleanser: return "⚔️"
        case .legendCleanser:  return "🗡️"
        case .eternalPurger:   return "🔥"
        case .grandArchivist:  return "👑"
        }
    }

    var color: Color {
        switch self {
        case .clutterSlayer:   return .gray
        case .dungeonCleanser: return .green
        case .legendCleanser:  return .blue
        case .eternalPurger:   return .purple
        case .grandArchivist:  return .yellow
        }
    }

    var flavorTitle: String {
        switch self {
        case .clutterSlayer:   return "Apprentice of the Purge"
        case .dungeonCleanser: return "Sworn Foe of Clutter"
        case .legendCleanser:  return "Bane of the Blurry Beast"
        case .eternalPurger:   return "Eternal Flame of Storage"
        case .grandArchivist:  return "Grand Archivist – Keeper of Only the Best"
        }
    }
}
