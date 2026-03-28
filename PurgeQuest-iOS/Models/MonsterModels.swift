// Models/MonsterModels.swift
// Value-type monster definitions – not persisted directly (embedded in CombatSession)

import SwiftUI
import Foundation

// ─── Monster Type ─────────────────────────────────────────────────────────────

enum MonsterType: String, Codable, CaseIterable {
    case duplicateDragon       = "Duplicate Dragon"
    case blurryBeast           = "Blurry Beast"
    case screenshotSpecter     = "Screenshot Specter"
    case lowQualityGoblin      = "Low-Quality Goblin"
    case oldRelicWraith        = "Old Relic Wraith"
    case darkShadowDemon       = "Dark Shadow Demon"
    case bossCorruptedArchive  = "Corrupted Archive"   // boss every 250 photos
    case bossStorageLeviathan  = "Storage Leviathan"   // floor 10 boss
    // v1.1 placeholder
    case videoVampire          = "Video Vampire"

    var emoji: String {
        switch self {
        case .duplicateDragon:      return "🐉"
        case .blurryBeast:          return "👁️"
        case .screenshotSpecter:    return "👻"
        case .lowQualityGoblin:     return "👺"
        case .oldRelicWraith:       return "💀"
        case .darkShadowDemon:      return "🌑"
        case .bossCorruptedArchive: return "🏰"
        case .bossStorageLeviathan: return "🦑"
        case .videoVampire:         return "🧛"
        }
    }

    var sfSymbol: String {
        switch self {
        case .duplicateDragon:      return "doc.on.doc.fill"
        case .blurryBeast:          return "eye.slash.fill"
        case .screenshotSpecter:    return "camera.viewfinder"
        case .lowQualityGoblin:     return "photo.badge.exclamationmark"
        case .oldRelicWraith:       return "clock.arrow.circlepath"
        case .darkShadowDemon:      return "moon.fill"
        case .bossCorruptedArchive: return "server.rack"
        case .bossStorageLeviathan: return "externaldrive.fill"
        case .videoVampire:         return "video.fill"
        }
    }

    var baseAttackDamage: Int {
        switch self {
        case .duplicateDragon:      return 8
        case .blurryBeast:          return 6
        case .screenshotSpecter:    return 5
        case .lowQualityGoblin:     return 4
        case .oldRelicWraith:       return 7
        case .darkShadowDemon:      return 9
        case .bossCorruptedArchive: return 20
        case .bossStorageLeviathan: return 25
        case .videoVampire:         return 12
        }
    }

    var xpRewardPerPhoto: Int {
        switch self {
        case .duplicateDragon:      return 15
        case .blurryBeast:          return 12
        case .screenshotSpecter:    return 10
        case .lowQualityGoblin:     return 8
        case .oldRelicWraith:       return 11
        case .darkShadowDemon:      return 13
        case .bossCorruptedArchive: return 50
        case .bossStorageLeviathan: return 75
        case .videoVampire:         return 20
        }
    }

    var isBoss: Bool {
        self == .bossCorruptedArchive || self == .bossStorageLeviathan
    }

    var tint: Color {
        switch self {
        case .duplicateDragon:      return Color(red: 0.9, green: 0.3, blue: 0.2)
        case .blurryBeast:          return Color(red: 0.5, green: 0.2, blue: 0.8)
        case .screenshotSpecter:    return Color(red: 0.4, green: 0.8, blue: 0.9)
        case .lowQualityGoblin:     return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .oldRelicWraith:       return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .darkShadowDemon:      return Color(red: 0.3, green: 0.0, blue: 0.5)
        case .bossCorruptedArchive: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .bossStorageLeviathan: return Color(red: 0.0, green: 0.8, blue: 0.8)
        case .videoVampire:         return Color(red: 0.8, green: 0.0, blue: 0.3)
        }
    }

    // Procedural name templates (Foundation Models would expand these)
    var namePrefixes: [String] {
        switch self {
        case .duplicateDragon:      return ["Xerox", "Mirror", "Echo", "Clone", "Copy"]
        case .blurryBeast:          return ["Foggy", "Hazy", "Smeared", "Trembling", "Shaky"]
        case .screenshotSpecter:    return ["Phantom", "Ghost", "Specter", "Shadow", "Spectral"]
        case .lowQualityGoblin:     return ["Grainy", "Murky", "Dim", "Faded", "Dull"]
        case .oldRelicWraith:       return ["Ancient", "Forgotten", "Dusty", "Rotting", "Aged"]
        case .darkShadowDemon:      return ["Void", "Abyss", "Dark", "Obsidian", "Pitch"]
        case .bossCorruptedArchive: return ["Archon", "Grand", "Supreme", "Final"]
        case .bossStorageLeviathan: return ["Great", "Elder", "Ancient", "Colossal"]
        case .videoVampire:         return ["Draining", "Hungry", "Greedy", "Ravenous"]
        }
    }
    var nameSuffixes: [String] {
        switch self {
        case .duplicateDragon:      return ["the Redundant", "the Mirrored", "of Infinite Copies"]
        case .blurryBeast:          return ["the Unfocused", "the Trembling", "of Shaky Paws"]
        case .screenshotSpecter:    return ["the Forgotten", "the Archived", "of Dead Receipts"]
        case .lowQualityGoblin:     return ["the Grainy", "the Dark", "of Poor Choices"]
        case .oldRelicWraith:       return ["the Ancient", "the Forgotten", "of 2017"]
        case .darkShadowDemon:      return ["the Underexposed", "the Lightless", "of Midnight"]
        case .bossCorruptedArchive: return ["the Infinite", "the Unkillable", "Supreme"]
        case .bossStorageLeviathan: return ["the Devourer", "the Full", "of Zero Bytes"]
        case .videoVampire:         return ["the Lengthy", "the 4K", "the Uncompressed"]
        }
    }

    func generateName() -> String {
        let prefix = namePrefixes.randomElement() ?? name
        let suffix = nameSuffixes.randomElement() ?? ""
        return "\(prefix) \(rawValue) \(suffix)"
    }

    var attackLines: [String] {
        switch self {
        case .duplicateDragon:
            return ["Breathes redundant fire!", "Multiplies before your eyes!", "An endless copy!"]
        case .blurryBeast:
            return ["Shakes the very frame!", "You can barely see its attack!", "Focus lost!"]
        case .screenshotSpecter:
            return ["Haunts your home screen!", "A receipt from the dead!", "WhatsApp from 2020!"]
        case .lowQualityGoblin:
            return ["Hurls grainy pixels!", "So dark you can't see the blow!", "480p assault!"]
        case .oldRelicWraith:
            return ["Cries from 2016!", "Drags you to the past!", "An older iPhone attacked!"]
        case .darkShadowDemon:
            return ["Total darkness!", "Void strike!", "The exposure was -3!"]
        case .bossCorruptedArchive:
            return ["ARCHIVE BREATH!", "BOSS ROAR! Your storage screams!", "INFINITE COPIES!"]
        case .bossStorageLeviathan:
            return ["DEVOURS YOUR ICLOUD!", "STORAGE FULL! CRITICAL HIT!", "THE SEA OF FILES RISES!"]
        case .videoVampire:
            return ["Drains your battery!", "A 47-minute video!!", "Full HD bloodsucker!"]
        }
    }

    var deathLines: [String] {
        switch self {
        case .duplicateDragon:
            return ["The last copy crumbles.", "Redundancy: eliminated.", "Original restored."]
        case .blurryBeast:
            return ["Focus: achieved.", "Clarity restored to the realm.", "Sharpness returns."]
        case .screenshotSpecter:
            return ["The spirit is purged.", "Haunt ended. Screen clear.", "Exorcism successful."]
        case .lowQualityGoblin:
            return ["The goblin de-pixels.", "Low quality: rejected.", "Storage quality improved."]
        case .oldRelicWraith:
            return ["The past is released.", "Old photos, old wounds. Gone.", "2016 is finally over."]
        case .darkShadowDemon:
            return ["Light reclaims the void.", "Darkness dispelled.", "The shadow fades."]
        case .bossCorruptedArchive:
            return ["THE ARCHIVE SHATTERS!", "BOSS DEFEATED! LEGENDARY!", "THE DUNGEON TREMBLES!"]
        case .bossStorageLeviathan:
            return ["THE LEVIATHAN FALLS!", "STORAGE FREED! EPIC VICTORY!", "THE SEA RECEDES!"]
        case .videoVampire:
            return ["The vampire dissolves.", "Battery reclaimed.", "No more 4K nightmares."]
        }
    }
}

// ─── Monster Instance ─────────────────────────────────────────────────────────

struct Monster: Identifiable, Codable {
    let id: UUID
    let type: MonsterType
    let name: String
    let maxHP: Int
    var currentHP: Int
    var isEnraged: Bool     // < 25% HP

    init(type: MonsterType, photoCount: Int) {
        self.id = UUID()
        self.type = type
        self.name = type.generateName()
        self.maxHP = photoCount
        self.currentHP = photoCount
        self.isEnraged = false
    }

    var hpPercent: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }

    var isDead: Bool { currentHP <= 0 }

    mutating func takeDamage(_ amount: Int = 1) {
        currentHP = max(0, currentHP - amount)
        isEnraged = hpPercent < 0.25
    }

    func randomAttackLine() -> String {
        type.attackLines.randomElement() ?? "\(name) attacks!"
    }
    func randomDeathLine() -> String {
        type.deathLines.randomElement() ?? "\(name) is defeated!"
    }
}

// ─── Combat Room ──────────────────────────────────────────────────────────────

struct DungeonRoom: Identifiable, Codable {
    let id: UUID
    let monster: Monster
    let assetLocalIDs: [String]   // PHAsset localIdentifiers
    let assetByteSizes: [Int64]   // pre-fetched file sizes
    var currentPhotoIndex: Int
    var decisionsMade: [String: PhotoDecision]   // localID → decision
    var roomNumber: Int
    var isBossRoom: Bool

    init(monster: Monster, assetLocalIDs: [String], assetByteSizes: [Int64], roomNumber: Int) {
        self.id = UUID()
        self.monster = monster
        self.assetLocalIDs = assetLocalIDs
        self.assetByteSizes = assetByteSizes
        self.currentPhotoIndex = 0
        self.decisionsMade = [:]
        self.roomNumber = roomNumber
        self.isBossRoom = monster.type.isBoss
    }

    var totalPhotos: Int { assetLocalIDs.count }
    var photosDecided: Int { decisionsMade.count }
    var isComplete: Bool { photosDecided >= totalPhotos }

    var currentAssetID: String? {
        guard currentPhotoIndex < assetLocalIDs.count else { return nil }
        return assetLocalIDs[currentPhotoIndex]
    }

    var photosToDelete: [String] {
        decisionsMade.filter { $0.value == .delete }.map(\.key)
    }

    var totalBytesIfDeleted: Int64 {
        zip(assetLocalIDs, assetByteSizes)
            .filter { decisionsMade[$0.0] == .delete }
            .reduce(0) { $0 + $1.1 }
    }
}

enum PhotoDecision: String, Codable {
    case delete = "delete"
    case keep   = "keep"
}

// ─── Active Combat Session (passed through app state, NOT SwiftData) ──────────

@Observable
final class CombatSession {
    var room: DungeonRoom
    var monster: Monster
    var combo: Int = 0
    var maxComboThisRoom: Int = 0
    var totalXPThisRoom: Int = 0
    var totalGemsThisRoom: Int = 0
    var startedAt: Date = .now
    var phase: CombatPhase = .fighting

    init(room: DungeonRoom) {
        self.room = room
        self.monster = room.monster
    }

    enum CombatPhase {
        case fighting
        case monsterAttacking(line: String)
        case victory
        case pendingDelete
        case heroDefeated
    }
}
