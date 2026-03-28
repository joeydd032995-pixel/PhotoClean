// Services/FlavorTextService.swift
// Procedural flavor text generation.
// Phase 1: template-based (deterministic, offline, no framework needed)
// Phase 2 placeholder: Apple Foundation Models (on-device LLM, iOS 18+)

import Foundation

struct FlavorTextService {

    // ─── Quest Flavor ─────────────────────────────────────────────────────────

    static func questIntro(monsterType: MonsterType, floor: Int) -> String {
        let intros: [MonsterType: [String]] = [
            .duplicateDragon: [
                "The dungeon echoes with infinite copies. A \(monsterType.rawValue) lurks among the mirrors.",
                "Identical footsteps. \(monsterType.rawValue) hoards its redundant treasure.",
                "Every pixel, duplicated. Floor \(floor). The Dragon awakens.",
            ],
            .blurryBeast: [
                "A fog rolls through Dungeon Level \(floor). The Blurry Beast stirs.",
                "Shaky hands. Poor light. The \(monsterType.rawValue) smells your unfocused memories.",
                "The realm of blur awaits. Can you focus?",
            ],
            .screenshotSpecter: [
                "The ghost of receipts past. Level \(floor) is haunted by dead links.",
                "WhatsApp screenshots from 2019. The Specter feeds.",
                "Every forgotten screenshot: a spirit. The dungeon groans.",
            ],
            .lowQualityGoblin: [
                "480p horrors on Floor \(floor). The Goblins mass.",
                "Grain and noise. Darkness and blur. The Goblin hoards your mistakes.",
                "Low resolution. Low quality. High threat.",
            ],
            .oldRelicWraith: [
                "Photos from five years ago materialize on Floor \(floor).",
                "The Wraith of forgotten albums stirs from 2017.",
                "Ancient selfies. Ancient pain. The Old Relic Wraith awakens.",
            ],
            .darkShadowDemon: [
                "Pitch black photos swarm Floor \(floor). The Void Demon manifests.",
                "The shutter opened, but the light never came. A Demon was born.",
                "Underexposure incarnate. Floor \(floor) is lost in darkness.",
            ],
            .bossCorruptedArchive: [
                "⚠️ BOSS ROOM – The Corrupted Archive awaits. 250 photos fed it. Now you fight.",
                "BOSS ENCOUNTER. The Archive has amassed your entropy. Face it.",
                "The dungeon shakes. The BOSS looms. Purge or perish.",
            ],
            .bossStorageLeviathan: [
                "THE LEVIATHAN RISES from the depths of zero remaining storage.",
                "STORAGE FULL. The Leviathan feeds on your paralysis. FIGHT.",
                "Floor \(floor). The great beast of accumulated data surfaces.",
            ],
        ]
        return (intros[monsterType] ?? ["A \(monsterType.rawValue) appears on floor \(floor)!"])
            .randomElement()!
    }

    // ─── Victory Lines ────────────────────────────────────────────────────────

    static func victoryLine(photosDeleted: Int, bytesFreed: Int64, combo: Int) -> String {
        let mb = Int(bytesFreed / 1_048_576)
        let comboBonus = combo >= 10 ? " COMBO BONUS ACTIVATED!" : ""
        let lines = [
            "The dungeon breathes. \(photosDeleted) foes slain. \(mb) MB liberated.\(comboBonus)",
            "Room cleared! \(photosDeleted) photos purged from existence. \(mb) MB restored to the realm.",
            "Victory! The monster crumbles. \(mb) MB of freedom reclaimed. \(photosDeleted) memories purged.",
            "\(photosDeleted) photos vanished into the void. \(mb) MB is yours again.\(comboBonus)",
        ]
        return lines.randomElement()!
    }

    // ─── Level Up Lines ───────────────────────────────────────────────────────

    static func levelUpLine(newLevel: Int, heroClass: HeroClass) -> String {
        let lines = [
            "Level \(newLevel)! You become \(heroClass.rawValue). The dungeon fears you more.",
            "LEVEL UP → \(newLevel). \(heroClass.icon) \(heroClass.rawValue) ascends.",
            "The realm recognizes your power. Level \(newLevel) achieved.",
            "\(heroClass.rawValue) – Level \(newLevel). Your broom grows mightier.",
        ]
        return lines.randomElement()!
    }

    // ─── Daily Quest Titles ───────────────────────────────────────────────────

    static func dailyQuestTitle(type: DailyQuestType) -> String {
        switch type {
        case .deletePhotos:
            return ["Purge the Masses", "Clear the Chamber", "The Great Sweep",
                    "Daily Slaughter", "Room Clearance"].randomElement()!
        case .deleteScreenshots:
            return ["Banish the Specters", "Ghost Protocol", "Screen of the Dead",
                    "Screenshot Purge", "Phantom Hunt"].randomElement()!
        case .deleteDuplicates:
            return ["Slay the Dragon Brood", "End Redundancy", "Mirror Mirror, No More",
                    "Clone Wars", "Duplicate Doom"].randomElement()!
        case .achieveCombo:
            return ["Flurry of Steel", "Combo Master", "Chain Strike",
                    "Delete Frenzy", "Unstoppable Surge"].randomElement()!
        case .freeStorage:
            return ["Reclaim the Realm", "The Liberation", "Space Restored",
                    "Byte Liberator", "MB Freedom"].randomElement()!
        case .playSession:
            return ["Into the Dungeon", "First Descent", "Daily Descent",
                    "Answer the Call", "Enter the Dungeon"].randomElement()!
        case .defeatBoss:
            return ["Slay the Overlord", "Boss Bounty", "Corruption Cleansed",
                    "Archive Purged", "Leviathan Hunt"].randomElement()!
        }
    }

    // ─── Monster Attack Taunts ────────────────────────────────────────────────

    static func taunt(for type: MonsterType) -> String {
        type.attackLines.randomElement() ?? "\(type.rawValue) attacks!"
    }

    // ─── Apple Foundation Models Placeholder ─────────────────────────────────
    // TODO (iOS 18+): Use FoundationModels.GenerativeModel for richer text.
    // Uncomment and integrate when Foundation Models public API is available.
    /*
    import FoundationModels

    static func generateQuestDescriptionAI(monsterType: MonsterType, floor: Int) async -> String {
        let model = SystemLanguageModel.default
        guard model.availability == .available else {
            return questIntro(monsterType: monsterType, floor: floor)
        }
        let session = LanguageModelSession()
        let prompt = """
        Generate a one-sentence dramatic dungeon crawler quest description for a monster
        called "\(monsterType.rawValue)" on dungeon floor \(floor).
        The game is about deleting phone photos as combat. Keep it under 20 words.
        """
        let response = try? await session.respond(to: prompt)
        return response?.content ?? questIntro(monsterType: monsterType, floor: floor)
    }
    */
}
