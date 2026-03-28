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

        // Check authorization
        let status = await PhotoLibraryService.shared.requestAuthorization()
        photoAuthStatus = status
        guard status == .authorized || status == .limited else {
            dungeonLoadError = "Photo library access is required to enter the dungeon."
            isDungeonLoading = false
            return
        }

        hero.updateStreak()

        // Fetch assets
        let result = PhotoLibraryService.shared.fetchAllPhotoAssets()
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }

        guard !assets.isEmpty else {
            dungeonLoadError = "Your photo library is empty. Nothing to purge!"
            isDungeonLoading = false
            return
        }

        // Shuffle for variety
        assets.shuffle()
        let batch = Array(assets.prefix(150))   // analyze up to 150 per session

        // ML grouping
        let groups = await MLAnalysisService.shared.analyzeAndGroup(assets: batch)

        // Build rooms (15–25 photos each)
        dungeonRooms = buildRooms(from: groups, hero: hero)
        currentRoomIndex = 0
        sessionPhotosDeleted = 0
        sessionBytesFreed = 0
        sessionXPEarned = 0

        // Fetch library stats in background
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

    private func buildRooms(from groups: [PhotoGroup], hero: Hero) -> [DungeonRoom] {
        var rooms: [DungeonRoom] = []
        var roomNumber = hero.dungeonFloor + 1
        let roomSize = 15

        for group in groups {
            var ids = group.assetLocalIDs
            var sizes = group.assetByteSizes
            while !ids.isEmpty {
                let batchIDs = Array(ids.prefix(roomSize))
                let batchSizes = Array(sizes.prefix(batchSizes.count > 0 ? roomSize : 0))
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

        if !toDelete.isEmpty {
            // Record for undo window
            for id in toDelete {
                let idx = session.room.assetLocalIDs.firstIndex(of: id) ?? 0
                let size = idx < session.room.assetByteSizes.count ? session.room.assetByteSizes[idx] : 0
                let record = DeletedPhotoRecord(
                    assetLocalID: id, fileSizeBytes: size,
                    monsterType: session.monster.type.rawValue
                )
                modelContext.insert(record)
            }
        }
    }

    func confirmDelete(modelContext: ModelContext) async {
        let ids = pendingDeleteIDs
        guard !ids.isEmpty else { return }
        do {
            let deleted = try await PhotoLibraryService.shared.deleteAssets(localIDs: ids)
            showToast("\(deleted) photos purged from existence.")
        } catch {
            showToast("Delete failed: \(error.localizedDescription)")
        }
        pendingDeleteIDs = []
        pendingDeleteBytes = 0
        advanceToNextRoom()
    }

    func skipDelete() {
        pendingDeleteIDs = []
        pendingDeleteBytes = 0
        advanceToNextRoom()
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
