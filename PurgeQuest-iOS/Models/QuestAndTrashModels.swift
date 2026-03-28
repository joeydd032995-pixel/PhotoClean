// Models/DailyQuestRecord.swift + DeletedPhotoRecord.swift

import Foundation
import SwiftData

// ─── Daily Quest ──────────────────────────────────────────────────────────────

@Model
final class DailyQuestRecord {
    var id: UUID
    var questType: DailyQuestType
    var title: String
    var flavorText: String
    var goalCount: Int
    var currentCount: Int
    var isCompleted: Bool
    var gemReward: Int
    var xpReward: Int
    var createdDate: Date   // the calendar day this quest belongs to

    init(questType: DailyQuestType, title: String, flavorText: String,
         goalCount: Int, gemReward: Int, xpReward: Int) {
        self.id = UUID()
        self.questType = questType
        self.title = title
        self.flavorText = flavorText
        self.goalCount = goalCount
        self.currentCount = 0
        self.isCompleted = false
        self.gemReward = gemReward
        self.xpReward = xpReward
        self.createdDate = Calendar.current.startOfDay(for: .now)
    }

    var progress: Double {
        guard goalCount > 0 else { return 0 }
        return Double(currentCount) / Double(goalCount)
    }

    var progressText: String { "\(currentCount)/\(goalCount)" }
}

enum DailyQuestType: String, Codable, CaseIterable {
    case deletePhotos      = "delete_photos"
    case deleteScreenshots = "delete_screenshots"
    case deleteDuplicates  = "delete_duplicates"
    case achieveCombo      = "achieve_combo"
    case freeStorage       = "free_storage"    // MB
    case playSession       = "play_session"
    case defeatBoss        = "defeat_boss"

    var icon: String {
        switch self {
        case .deletePhotos:      return "trash.fill"
        case .deleteScreenshots: return "camera.viewfinder"
        case .deleteDuplicates:  return "doc.on.doc.fill"
        case .achieveCombo:      return "bolt.fill"
        case .freeStorage:       return "externaldrive.fill"
        case .playSession:       return "play.circle.fill"
        case .defeatBoss:        return "crown.fill"
        }
    }
}

// ─── Daily Quest Generator ────────────────────────────────────────────────────

struct DailyQuestGenerator {
    static func generateQuests(for date: Date = .now) -> [DailyQuestRecord] {
        // Seed by calendar day so quests are deterministic per day
        var cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let seed = (comps.year ?? 2025) * 10000 + (comps.month ?? 1) * 100 + (comps.day ?? 1)
        srand48(seed)

        let pool: [(DailyQuestRecord)] = [
            DailyQuestRecord(questType: .deletePhotos, title: "Purge the Masses",
                             flavorText: "The dungeon overflows. 20 must go.", goalCount: 20,
                             gemReward: 10, xpReward: 100),
            DailyQuestRecord(questType: .deleteScreenshots, title: "Banish the Specters",
                             flavorText: "Screenshots haunt you. Delete 10.", goalCount: 10,
                             gemReward: 15, xpReward: 120),
            DailyQuestRecord(questType: .deleteDuplicates, title: "Slay the Dragon Brood",
                             flavorText: "5 duplicate photos must be purged.", goalCount: 5,
                             gemReward: 20, xpReward: 150),
            DailyQuestRecord(questType: .achieveCombo, title: "Flurry of Steel",
                             flavorText: "Hit a 5-combo during combat.", goalCount: 5,
                             gemReward: 25, xpReward: 200),
            DailyQuestRecord(questType: .freeStorage, title: "Reclaim the Realm",
                             flavorText: "Free 50 MB of storage.", goalCount: 50,
                             gemReward: 30, xpReward: 200),
            DailyQuestRecord(questType: .playSession, title: "Into the Dungeon",
                             flavorText: "Complete a full combat room.", goalCount: 1,
                             gemReward: 10, xpReward: 75),
        ]

        // Pick 3 deterministic quests from pool
        let indices = [
            Int(drand48() * Double(pool.count)),
            (Int(drand48() * Double(pool.count)) + 2) % pool.count,
            (Int(drand48() * Double(pool.count)) + 4) % pool.count,
        ]
        return Array(Set(indices)).prefix(3).map { pool[$0] }
    }
}

// ─── Deleted Photo Record (7-day undo trash) ──────────────────────────────────

@Model
final class DeletedPhotoRecord {
    var id: UUID
    var assetLocalID: String
    var deletedAt: Date
    var fileSizeBytes: Int64
    var monsterType: String     // MonsterType.rawValue
    var thumbnailData: Data?    // Small thumbnail for undo UI (≤50KB)
    var wasRestored: Bool

    init(assetLocalID: String, fileSizeBytes: Int64, monsterType: String, thumbnailData: Data? = nil) {
        self.id = UUID()
        self.assetLocalID = assetLocalID
        self.deletedAt = .now
        self.fileSizeBytes = fileSizeBytes
        self.monsterType = monsterType
        self.thumbnailData = thumbnailData
        self.wasRestored = false
    }

    var isWithinUndoWindow: Bool {
        Date.now.timeIntervalSince(deletedAt) < 7 * 86400   // 7 days
    }

    // NOTE: PHPhotoLibrary can only recover photos deleted via our own
    // PHAssetChangeRequest. iOS does not expose a "restore from trash" API.
    // The undo window here means: show a reminder before permanent deletion.
}
