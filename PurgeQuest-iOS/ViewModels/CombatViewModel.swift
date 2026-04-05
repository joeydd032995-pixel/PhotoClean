// ViewModels/CombatViewModel.swift
// Drives all swipe mechanics, combo tracking, XP calculation, and monster state.

import SwiftUI
import Photos
import Observation

@Observable
@MainActor
final class CombatViewModel {

    // ─── State ─────────────────────────────────────────────────────────────────
    var session: CombatSession
    var currentImage: UIImage? = nil
    var isLoadingImage: Bool = false
    var swipeOffset: CGSize = .zero
    var swipeRotation: Double = 0
    var isAnimatingDamage: Bool = false
    var isAnimatingHeroDamage: Bool = false
    var monsterShakeOffset: CGSize = .zero
    var heroShakeOffset: CGSize = .zero
    var showComboFlash: Bool = false
    var attackLineText: String = ""
    var showAttackLine: Bool = false
    var xpGainText: String = ""
    var showXPGain: Bool = false
    var cardFlipped: Bool = false

    private var preloadedNextImage: UIImage? = nil
    private var imageLoadTask: Task<Void, Never>? = nil
    private var burstResetItem: DispatchWorkItem? = nil

    // ─── Particle / visual effect triggers ────────────────────────────────────
    var isMonsterDying: Bool = false
    var showDeleteBurst: Bool = false
    var showKeepBurst: Bool = false

    var monster: Monster { session.monster }
    var room: DungeonRoom { session.room }
    var combo: Int { session.combo }
    var isRoomComplete: Bool { session.room.isComplete || session.monster.isDead }
    var swipeProgress: Double {
        abs(swipeOffset.width) / 120.0   // 0–1 for visual indicators
    }
    var swipeDirection: SwipeDirection {
        if swipeOffset.width < -20 { return .left }
        if swipeOffset.width > 20 { return .right }
        return .none
    }

    enum SwipeDirection { case left, right, none }

    // ─── Init ──────────────────────────────────────────────────────────────────

    init(session: CombatSession) {
        self.session = session
        Task { await loadCurrentImage() }
    }

    deinit {
        imageLoadTask?.cancel()
        burstResetItem?.cancel()
    }

    // ─── Image Loading ─────────────────────────────────────────────────────────

    func loadCurrentImage() async {
        guard let assetID = room.currentAssetID else { return }
        isLoadingImage = true

        if let preloaded = preloadedNextImage {
            currentImage = preloaded
            preloadedNextImage = nil
            isLoadingImage = false
        } else {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
            if let asset = assets.firstObject {
                currentImage = await PhotoLibraryService.shared.loadImage(for: asset)
            }
            isLoadingImage = false
        }

        // Preload next — cancel any in-flight preload first
        imageLoadTask?.cancel()
        let nextIndex = room.currentPhotoIndex + 1
        if nextIndex < room.assetLocalIDs.count {
            let nextID = room.assetLocalIDs[nextIndex]
            imageLoadTask = Task.detached(priority: .userInitiated) {
                let nextAssets = PHAsset.fetchAssets(withLocalIdentifiers: [nextID], options: nil)
                if let asset = nextAssets.firstObject {
                    let img = await PhotoLibraryService.shared.loadImage(for: asset)
                    await MainActor.run { self.preloadedNextImage = img }
                }
            }
        }
    }

    // ─── Swipe Gesture Handling ────────────────────────────────────────────────

    func onDragChanged(_ value: DragGesture.Value) {
        swipeOffset = value.translation
        swipeRotation = Double(value.translation.width / 20)
    }

    func onDragEnded(_ value: DragGesture.Value, hero: Hero, appState: AppState, modelContext: Any) {
        let threshold: CGFloat = 90
        if value.translation.width < -threshold {
            commitSwipe(direction: .left, hero: hero, appState: appState)
        } else if value.translation.width > threshold {
            commitSwipe(direction: .right, hero: hero, appState: appState)
        } else {
            // Snap back
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                swipeOffset = .zero
                swipeRotation = 0
            }
        }
    }

    // ─── Commit Decision ──────────────────────────────────────────────────────

    func commitSwipe(direction: SwipeDirection, hero: Hero, appState: AppState) {
        guard let assetID = room.currentAssetID else { return }
        guard direction != .none else { return }

        let isDelete = direction == .left

        // Animate card out
        withAnimation(.easeInOut(duration: 0.25)) {
            swipeOffset = CGSize(width: isDelete ? -500 : 500, height: -50)
            swipeRotation = isDelete ? -20 : 20
        }

        // Fire swipe burst; cancel any pending reset so rapid swipes don't clear early
        burstResetItem?.cancel()
        if isDelete { showDeleteBurst = true } else { showKeepBurst = true }
        let resetItem = DispatchWorkItem { [weak self] in
            self?.showDeleteBurst = false
            self?.showKeepBurst = false
        }
        burstResetItem = resetItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: resetItem)

        // Process after brief delay (card flying off)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.processDecision(assetID: assetID, isDelete: isDelete, hero: hero, appState: appState)
        }
    }

    private func processDecision(assetID: String, isDelete: Bool, hero: Hero, appState: AppState) {
        // Record decision
        session.room.decisionsMade[assetID] = isDelete ? .delete : .keep

        if isDelete {
            // Attack the monster
            HapticService.shared.swipeDelete()
            session.combo += 1
            session.maxComboThisRoom = max(session.maxComboThisRoom, session.combo)
            var damage = 1
            if session.combo >= 5 { damage = 2 }   // combo bonus
            if session.combo >= 10 { damage = 3 }

            session.monster.takeDamage(damage)

            // XP
            let xp = monster.type.xpRewardPerPhoto + (session.combo >= 5 ? 5 : 0)
            session.totalXPThisRoom += xp
            showXPPopup("+\(xp) XP")

            // Combo haptic
            HapticService.shared.comboHit(comboCount: session.combo)

            // Animate monster damage
            animateMonsterDamage()

            if session.combo >= 5 {
                showComboFlash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.showComboFlash = false
                }
            }

            // Gems
            let idx = room.assetLocalIDs.firstIndex(of: assetID) ?? 0
            let bytes = idx < room.assetByteSizes.count ? room.assetByteSizes[idx] : 0
            let gems = Int(bytes / 1_048_576)
            session.totalGemsThisRoom += gems

        } else {
            // Spare = monster attacks hero
            HapticService.shared.swipeKeep()
            session.combo = 0   // reset combo
            let damage = session.monster.type.baseAttackDamage +
                         (session.monster.isEnraged ? 3 : 0)
            hero.takeDamage(damage)
            showAttackLinePopup(session.monster.randomAttackLine())
            animateHeroDamage()
            HapticService.shared.heroDamage()
        }

        // Advance to next photo
        session.room.currentPhotoIndex += 1

        // Reset card
        swipeOffset = .zero
        swipeRotation = 0

        // Check completion
        if session.room.isComplete || session.monster.isDead {
            handleRoomComplete(hero: hero, appState: appState)
            return
        }

        // Load next image
        Task { await loadCurrentImage() }
    }

    // ─── Room Completion ──────────────────────────────────────────────────────

    private func handleRoomComplete(hero: Hero, appState: AppState) {
        // Trigger death burst when the monster was actually killed (not room-exhausted)
        if session.monster.isDead { isMonsterDying = true }
        session.phase = .victory
        HapticService.shared.monsterDeath()
        hero.bossesDefeated += session.monster.type.isBoss ? 1 : 0
        hero.dungeonFloor = max(hero.dungeonFloor, session.room.roomNumber)
        hero.highestCombo = max(hero.highestCombo, session.maxComboThisRoom)
        // Delegate deletion/navigation to AppState
        appState.activeCombatSession = session
    }

    // ─── Animations ───────────────────────────────────────────────────────────

    private func animateMonsterDamage() {
        isAnimatingDamage = true
        // Shake monster
        withAnimation(.interpolatingSpring(stiffness: 500, damping: 10)) {
            monsterShakeOffset = CGSize(width: -15, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.interpolatingSpring(stiffness: 500, damping: 10)) {
                self.monsterShakeOffset = CGSize(width: 12, height: 0)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring()) {
                self.monsterShakeOffset = .zero
                self.isAnimatingDamage = false
            }
        }
    }

    private func animateHeroDamage() {
        isAnimatingHeroDamage = true
        withAnimation(.interpolatingSpring(stiffness: 600, damping: 8)) {
            heroShakeOffset = CGSize(width: 10, height: -5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring()) {
                self.heroShakeOffset = .zero
                self.isAnimatingHeroDamage = false
            }
        }
    }

    private func showXPPopup(_ text: String) {
        xpGainText = text
        showXPGain = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.showXPGain = false
        }
    }

    private func showAttackLinePopup(_ text: String) {
        attackLineText = text
        showAttackLine = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            self.showAttackLine = false
        }
    }
}
