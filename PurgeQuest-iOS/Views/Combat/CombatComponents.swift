// Views/Combat/MonsterView.swift + SwipePhotoCard.swift

import SwiftUI

// ─── Monster View ─────────────────────────────────────────────────────────────

struct MonsterView: View {
    let monster: Monster
    let isAnimatingDamage: Bool
    let attackLine: String?
    var isDying: Bool = false

    @State private var idle = false
    @State private var enragePulse = false
    @State private var damageOffsetX: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            // Name + type
            VStack(spacing: 2) {
                if let line = attackLine {
                    Text(line)
                        .font(.custom("Georgia", size: 14))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .id(line)
                }

                Text(monster.name)
                    .font(.custom("Georgia Bold", size: 16))
                    .foregroundStyle(monster.type.tint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(monster.type.rawValue.uppercased())
                    .font(.custom("Georgia", size: 10))
                    .foregroundStyle(.secondary)
                    .tracking(3)
            }

            // Monster icon/sprite
            ZStack {
                // Glow aura
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [monster.type.tint.opacity(monster.isEnraged ? 0.4 : 0.15), .clear],
                            center: .center, startRadius: 0, endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(enragePulse && monster.isEnraged ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: enragePulse)

                // Main monster emoji/icon
                ZStack {
                    Image(systemName: monster.type.sfSymbol)
                        .font(.system(size: 64, weight: .regular))
                        .foregroundStyle(monster.type.tint)
                        .shadow(color: monster.type.tint, radius: isAnimatingDamage ? 20 : 4)

                    if isAnimatingDamage {
                        // Hit flash
                        Image(systemName: monster.type.sfSymbol)
                            .font(.system(size: 64))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .scaleEffect(isDying ? 0.01 : (idle ? 1.04 : 0.96))
                .opacity(isDying ? 0 : 1)
                .animation(.easeIn(duration: 0.35), value: isDying)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: idle)

                // Enrage indicator
                if monster.isEnraged {
                    Text("ENRAGED!")
                        .font(.custom("Georgia Bold", size: 10))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                        .offset(y: 52)
                }

                // Death burst — particle explosion when monster is defeated
                if isDying {
                    ParticleBurstView(color: monster.type.tint, count: 22, duration: 0.65)
                        .frame(width: 140, height: 140)
                }

                // Damage numbers (brief flash)
                if isAnimatingDamage {
                    Text("-1")
                        .font(.custom("Georgia Bold", size: 22))
                        .foregroundStyle(.red)
                        .offset(x: damageOffsetX, y: -50)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.5).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
            .frame(width: 140, height: 140)
        }
        .onAppear {
            idle = true
            enragePulse = true
        }
        .onChange(of: isDying) { _, dying in
            if dying { idle = false }
        }
        .onChange(of: isAnimatingDamage) { _, animating in
            if animating { damageOffsetX = CGFloat.random(in: -20...20) }
        }
        .animation(.default, value: attackLine)
        .animation(.spring(), value: isAnimatingDamage)
    }
}

// ─── Swipe Photo Card ─────────────────────────────────────────────────────────

struct SwipePhotoCard: View {
    let image: UIImage?
    let isLoading: Bool
    let swipeOffset: CGSize
    let rotation: Double
    let swipeDirection: CombatViewModel.SwipeDirection
    let swipeProgress: Double

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#111118"))
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(hex: "#F7C948"))
                    Text("Loading photo...")
                        .font(.custom("Georgia", size: 14))
                        .foregroundStyle(.secondary)
                }
            } else if let image {
                // Photo
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 420)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Delete overlay (red left)
                if swipeDirection == .left && swipeProgress > 0.1 {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.red.opacity(swipeProgress * 0.55))
                    VStack {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                Text("DELETE")
                                    .font(.custom("Georgia Bold", size: 22))
                            }
                            .foregroundStyle(.white)
                            .padding(20)
                            .rotationEffect(.degrees(-15))
                            .opacity(swipeProgress)
                            Spacer()
                        }
                        Spacer()
                    }
                }

                // Keep overlay (green right)
                if swipeDirection == .right && swipeProgress > 0.1 {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(swipeProgress * 0.45))
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Text("KEEP")
                                    .font(.custom("Georgia Bold", size: 22))
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                            }
                            .foregroundStyle(.white)
                            .padding(20)
                            .rotationEffect(.degrees(15))
                            .opacity(swipeProgress)
                        }
                        Spacer()
                    }
                }
            } else {
                // No image
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Photo unavailable")
                        .font(.custom("Georgia", size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 320, height: 420)
        .rotationEffect(.degrees(rotation))
        .offset(swipeOffset)
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: swipeOffset)
    }
}

// ─── Room Summary View ────────────────────────────────────────────────────────

struct RoomSummaryView: View {
    let session: CombatSession
    let hero: Hero
    let appState: AppState
    let modelContext: ModelContext

    @State private var revealed = false
    @State private var showDeleteConfirm = false

    private let toDelete: [String]
    private let bytesIfDeleted: Int64
    private let xpEarned: Int
    private let gemsEarned: Int

    init(session: CombatSession, hero: Hero, appState: AppState, modelContext: ModelContext) {
        self.session = session
        self.hero = hero
        self.appState = appState
        self.modelContext = modelContext
        self.toDelete = session.room.photosToDelete
        self.bytesIfDeleted = session.room.totalBytesIfDeleted
        self.xpEarned = session.totalXPThisRoom
        self.gemsEarned = session.totalGemsThisRoom
    }

    var body: some View {
        ZStack {
            DungeonBackground()

            VStack(spacing: 0) {
                Spacer()

                // Monster death confirmation
                VStack(spacing: 8) {
                    Text(session.monster.randomDeathLine())
                        .font(.custom("Georgia", size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("Room \(session.room.roomNumber) Cleared!")
                        .font(.custom("Georgia Bold", size: 32))
                        .foregroundStyle(Color(hex: "#F7C948"))
                        .multilineTextAlignment(.center)
                }
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 20)

                Spacer()

                // Loot grid
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        LootItem(icon: "🗡️", label: "Deleted", value: "\(toDelete.count) photos",
                                 color: .red, delay: 0.3)
                        LootItem(icon: "⭐️", label: "XP Earned", value: "+\(xpEarned) XP",
                                 color: Color(hex: "#F7C948"), delay: 0.45)
                        LootItem(icon: "💎", label: "Gems", value: "+\(gemsEarned)",
                                 color: Color(hex: "#00BCD4"), delay: 0.6)
                    }

                    if bytesIfDeleted > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "externaldrive.fill")
                                .foregroundStyle(Color(hex: "#4CAF50"))
                            Text("Storage freed: \(bytesIfDeleted.formattedBytes())")
                                .font(.custom("Georgia Bold", size: 16))
                                .foregroundStyle(Color(hex: "#4CAF50"))
                        }
                        .opacity(revealed ? 1 : 0)
                        .animation(.easeInOut.delay(0.75), value: revealed)
                    }

                    // Combo bonus
                    if session.maxComboThisRoom >= 5 {
                        HStack(spacing: 8) {
                            Text("⚡️")
                            Text("Best Combo: ×\(session.maxComboThisRoom)")
                                .font(.custom("Georgia Bold", size: 15))
                                .foregroundStyle(Color(hex: "#F7C948"))
                        }
                        .opacity(revealed ? 1 : 0)
                        .animation(.easeInOut.delay(0.9), value: revealed)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#F7C948").opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if !toDelete.isEmpty {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Label("Confirm \(toDelete.count) Deletions", systemImage: "trash.fill")
                                .font(.custom("Georgia Bold", size: 18))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(colors: [Color(hex: "#E84545"), Color(hex: "#C0392B")],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: Color(hex: "#E84545").opacity(0.4), radius: 10, y: 4)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Task { await appState.onRoomComplete(hero: hero, session: session, modelContext: modelContext) }
                    } label: {
                        Label(appState.currentRoomIndex + 1 < appState.dungeonRooms.count
                              ? "Next Room →" : "Exit Dungeon",
                              systemImage: appState.currentRoomIndex + 1 < appState.dungeonRooms.count
                              ? "arrow.right.circle.fill" : "door.right.and.door.left.open")
                            .font(.custom("Georgia Bold", size: 18))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { revealed = true }
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirm) {
            Button("Delete \(toDelete.count) Photos", role: .destructive) {
                Task { await appState.confirmDelete(modelContext: modelContext) }
            }
            Button("Not Yet", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(toDelete.count) photos, freeing \(bytesIfDeleted.formattedBytes()). You have 7 days to request a review before they are removed from your device.\n\nNote: iOS may ask for your confirmation again.")
        }
    }

}

struct LootItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let delay: Double
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 8) {
            Text(icon).font(.title)
            Text(value)
                .font(.custom("Georgia Bold", size: 16))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.5)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay), value: appeared)
        .onAppear { appeared = true }
    }
}
