// ViewModels/AppState.swift
// Root observable state passed through the environment.

import SwiftUI
import Observation
import SwiftData

@Observable
@MainActor
final class AppState {

    // ─── Navigation ────────────────────────────────────────────────────────────
    var selectedTab: Int = 0
    var isInCombat: Bool = false
    var showLevelUp: Bool = false
    var showDeleteConfirmation: Bool = false

    // ─── Active Combat ─────────────────────────────────────────────────────────
    var activeCombatSession: CombatSession?
    var pendingDeleteIDs: [String] = []
    var pendingDeleteBytes: Int64 = 0
    var pendingDeleteSizesByID: [String: Int64] = [:]
    var pendingDeleteMonsterType: String = ""

    // ─── Dungeon State ─────────────────────────────────────────────────────────
    var dungeonRooms: [DungeonRoom] = []
    var currentRoomIndex: Int = 0
    var isDungeonLoading: Bool = false
    var dungeonLoadError: String? = nil
    var libraryStats: LibraryStats? = nil

    // ─── Photo Library ─────────────────────────────────────────────────────────
    var photoAuthStatus: PHAuthorizationStatus = .notDetermined

    // ─── Toast / Feedback ──────────────────────────────────────────────────────
    var toastMessage: String? = nil
    var showingToast: Bool = false

    // ─── Session Stats (current dungeon run) ──────────────────────────────────
    var sessionPhotosDeleted: Int = 0
    var sessionBytesFreed: Int64 = 0
    var sessionXPEarned: Int = 0

    // ─── Dungeon Entry Point ───────────────────────────────────────────────────

    func enterDungeon(hero: Hero, modelContext: ModelContext) async {
        guard !isInCombat else { return }
        isDungeonLoading = true
        dungeonLoadError = nil

        guard let batch = await fetchValidatedAssets(hero: hero) else {
            isDungeonLoading = false
            return
        }

        hero.updateStreak()

        let groups = await MLAnalysisService.shared.analyzeAndGroup(assets: batch)
        dungeonRooms = buildRooms(from: groups, hero: hero)
        currentRoomIndex = 0
        sessionPhotosDeleted = 0
        sessionBytesFreed = 0
        sessionXPEarned = 0

        Task.detached(priority: .background) {
            let stats = await PhotoLibraryService.shared.totalLibraryStats()
            await MainActor.run { self.libraryStats = stats }
        }

        if let firstRoom = dungeonRooms.first {
            activeCombatSession = CombatSession(room: firstRoom)
            isDungeonLoading = false
            isInCombat = true
        } else {
            isDungeonLoading = false
            dungeonLoadError = "No photos to clean! Your dungeon is clear."
        }
    }

    /// Requests photo authorization, fetches and shuffles assets, returns nil (and sets dungeonLoadError) on failure.
    private func fetchValidatedAssets(hero: Hero) async -> [PHAsset]? {
        let status = await PhotoLibraryService.shared.requestAuthorization()
        photoAuthStatus = status
        guard status == .authorized || status == .limited else {
            dungeonLoadError = "Photo library access is required to enter the dungeon."
            return nil
        }
        var assets: [PHAsset] = []
        PhotoLibraryService.shared.fetchAllPhotoAssets().enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        guard !assets.isEmpty else {
            dungeonLoadError = "Your photo library is empty. Nothing to purge!"
            return nil
        }
        assets.shuffle()
        return Array(assets.prefix(150))
    }

    private func buildRooms(from groups: [PhotoGroup], hero: Hero) -> [DungeonRoom] {
        var rooms: [DungeonRoom] = []
        var roomNumber = hero.dungeonFloor + 1
        let roomSize = 15

        for group in groups {
            var ids = group.assetLocalIDs
            var sizes = group.assetByteSizes
            while !ids.isEmpty {
                let batchIDs = Array(ids.prefix(roomSize))
                let batchSizes = Array(sizes.prefix(roomSize))
                ids = Array(ids.dropFirst(roomSize))
                sizes = Array(sizes.dropFirst(roomSize))

                let isBoss = hero.totalPhotosDeleted > 0 &&
                             (hero.totalPhotosDeleted + rooms.count * roomSize) % 250 < roomSize

                let monsterType: MonsterType = isBoss ? .bossCorruptedArchive : group.monsterType
                let monster = Monster(type: monsterType, photoCount: batchIDs.count)
                let room = DungeonRoom(
                    monster: monster, assetLocalIDs: batchIDs,
                    assetByteSizes: batchSizes, roomNumber: roomNumber
                )
                rooms.append(room)
                roomNumber += 1
                if rooms.count >= 6 { break }   // cap at 6 rooms per session
            }
            if rooms.count >= 6 { break }
        }
        return rooms
    }

    // ─── Combat Outcome Handling ──────────────────────────────────────────────

    func onRoomComplete(hero: Hero, session: CombatSession, modelContext: ModelContext) async {
        let toDelete = session.room.photosToDelete
        let bytes = session.room.totalBytesIfDeleted

        pendingDeleteIDs = toDelete
        pendingDeleteBytes = bytes
        showDeleteConfirmation = !toDelete.isEmpty
        sessionPhotosDeleted += toDelete.count
        sessionBytesFreed += bytes

        // Commit XP / gems
        let leveledUp = hero.addXP(session.totalXPThisRoom)
        if leveledUp { showLevelUp = true }

        // Store context needed to record deletion — inserted only after confirmed delete succeeds
        if !toDelete.isEmpty {
            var sizesByID: [String: Int64] = [:]
            for id in toDelete {
                let idx = session.room.assetLocalIDs.firstIndex(of: id) ?? 0
                let size = idx < session.room.assetByteSizes.count ? session.room.assetByteSizes[idx] : 0
                sizesByID[id] = size
            }
            pendingDeleteSizesByID = sizesByID
            pendingDeleteMonsterType = session.monster.type.rawValue
        }
    }

    func confirmDelete(modelContext: ModelContext) async {
        let ids = pendingDeleteIDs
        let sizesByID = pendingDeleteSizesByID
        let monsterType = pendingDeleteMonsterType
        guard !ids.isEmpty else { return }
        do {
            let deleted = try await PhotoLibraryService.shared.deleteAssets(localIDs: ids)
            // Only record and advance once deletion is confirmed
            for id in ids {
                let record = DeletedPhotoRecord(
                    assetLocalID: id,
                    fileSizeBytes: sizesByID[id] ?? 0,
                    monsterType: monsterType
                )
                modelContext.insert(record)
            }
            showToast("\(deleted) photos purged from existence.")
            clearPendingDelete()
            advanceToNextRoom()
        } catch {
            showToast("Delete failed: \(error.localizedDescription)")
            clearPendingDelete()
        }
    }

    func skipDelete() {
        clearPendingDelete()
        advanceToNextRoom()
    }

    private func clearPendingDelete() {
        pendingDeleteIDs = []
        pendingDeleteBytes = 0
        pendingDeleteSizesByID = [:]
        pendingDeleteMonsterType = ""
    }

    func advanceToNextRoom() {
        currentRoomIndex += 1
        if currentRoomIndex < dungeonRooms.count {
            activeCombatSession = CombatSession(room: dungeonRooms[currentRoomIndex])
        } else {
            // Dungeon complete
            isInCombat = false
            activeCombatSession = nil
        }
    }

    func exitDungeon() {
        isInCombat = false
        activeCombatSession = nil
        pendingDeleteIDs = []
        showDeleteConfirmation = false
    }

    // ─── Toast ────────────────────────────────────────────────────────────────

    func showToast(_ message: String) {
        toastMessage = message
        showingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.showingToast = false
        }
    }
}
