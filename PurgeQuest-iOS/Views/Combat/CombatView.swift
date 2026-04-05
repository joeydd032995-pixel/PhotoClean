// Views/Combat/CombatView.swift
// Full-screen combat: photo card, monster, HUD, swipe gestures.

import SwiftUI
import SwiftData

struct CombatView: View {
    let session: CombatSession
    let hero: Hero
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var combatVM: CombatViewModel
    @State private var showRoomSummary = false
    @State private var showExitAlert = false

    init(session: CombatSession, hero: Hero) {
        self.session = session
        self.hero = hero
        _combatVM = State(wrappedValue: CombatViewModel(session: session))
    }

    var body: some View {
        ZStack {
            CombatBackground(monsterType: combatVM.monster.type)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ─ Top HUD ────────────────────────────────────────────────────
                CombatTopHUD(
                    hero: hero,
                    monster: combatVM.monster,
                    combo: combatVM.combo,
                    room: combatVM.room,
                    onExit: { showExitAlert = true }
                )
                .offset(x: combatVM.heroShakeOffset.width, y: combatVM.heroShakeOffset.height)
                .padding(.top, 8)

                Spacer()

                // ─ Monster ────────────────────────────────────────────────────
                MonsterView(
                    monster: combatVM.monster,
                    isAnimatingDamage: combatVM.isAnimatingDamage,
                    attackLine: combatVM.showAttackLine ? combatVM.attackLineText : nil,
                    isDying: combatVM.isMonsterDying
                )
                .offset(x: combatVM.monsterShakeOffset.width, y: combatVM.monsterShakeOffset.height)
                .padding(.bottom, 8)

                // ─ Photo Swipe Card ───────────────────────────────────────────
                ZStack {
                    // Next card peek
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 320, height: 420)
                        .scaleEffect(0.92)
                        .offset(y: 10)

                    // Main card
                    SwipePhotoCard(
                        image: combatVM.currentImage,
                        isLoading: combatVM.isLoadingImage,
                        swipeOffset: combatVM.swipeOffset,
                        rotation: combatVM.swipeRotation,
                        swipeDirection: combatVM.swipeDirection,
                        swipeProgress: combatVM.swipeProgress
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { combatVM.onDragChanged($0) }
                            .onEnded { combatVM.onDragEnded($0, hero: hero, appState: appState, modelContext: modelContext) }
                    )

                    // Swipe burst effects
                    if combatVM.showDeleteBurst {
                        ParticleBurstView(color: Color(hex: "#E84545"), count: 16, duration: 0.45)
                            .frame(width: 320, height: 420)
                            .transition(.opacity)
                            .zIndex(11)
                    }
                    if combatVM.showKeepBurst {
                        ParticleBurstView(color: Color(hex: "#4CAF50"), count: 12, duration: 0.45)
                            .frame(width: 320, height: 420)
                            .transition(.opacity)
                            .zIndex(11)
                    }

                    // XP Gain popup
                    if combatVM.showXPGain {
                        XPGainPopup(text: combatVM.xpGainText)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                            .zIndex(10)
                    }

                    // Combo flash
                    if combatVM.showComboFlash {
                        ComboFlashView(combo: combatVM.combo)
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(9)
                    }
                }
                .frame(height: 440)

                // ─ Action Hints ───────────────────────────────────────────────
                SwipeHintsRow()
                    .padding(.vertical, 16)

                Spacer(minLength: 20)
            }
        }
        .animation(.spring(response: 0.3), value: combatVM.showXPGain)
        .animation(.spring(), value: combatVM.showComboFlash)
        .onChange(of: combatVM.session.phase) { _, phase in
            if case .victory = phase {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showRoomSummary = true
                }
            }
        }
        .fullScreenCover(isPresented: $showRoomSummary) {
            RoomSummaryView(
                session: combatVM.session,
                hero: hero,
                appState: appState,
                modelContext: modelContext
            )
        }
        .alert("Retreat?", isPresented: $showExitAlert) {
            Button("Retreat", role: .destructive) { appState.exitDungeon() }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("Your progress in this room will be lost. Unsaved deletes will not be applied.")
        }
    }
}

// ─── Combat Background ────────────────────────────────────────────────────────

struct CombatBackground: View {
    let monsterType: MonsterType

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#060608"),
                    monsterType.tint.opacity(0.12),
                    Color(hex: "#060608"),
                ],
                startPoint: .top, endPoint: .bottom
            )
            StarsBackground()
            // Vignette
            RadialGradient(
                colors: [.clear, .black.opacity(0.5)],
                center: .center, startRadius: 200, endRadius: 500
            )
        }
    }
}

// ─── Top HUD: HP bars + room info ────────────────────────────────────────────

struct CombatTopHUD: View {
    let hero: Hero
    let monster: Monster
    let combo: Int
    let room: DungeonRoom
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                // Exit button
                Button(action: onExit) {
                    Image(systemName: "arrow.uturn.left")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .accessibilityLabel("Exit dungeon")

                Spacer()

                // Room info
                VStack(spacing: 2) {
                    Text("Room \(room.roomNumber)")
                        .font(.custom("Georgia Bold", size: 14, relativeTo: .caption))
                        .foregroundStyle(.white)
                    Text("\(room.photosDecided)/\(room.totalPhotos) photos")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Combo badge
                if combo >= 3 {
                    ComboBadge(combo: combo)
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)

            // Health bars
            HStack(spacing: 16) {
                // Hero HP
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("❤️ \(hero.currentHP)")
                            .font(.custom("Georgia Bold", size: 13))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    HealthBar(
                        progress: Double(hero.currentHP) / Double(hero.maxHP),
                        color: .red, height: 8
                    )
                }

                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                    .font(.title3)

                // Monster HP
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Spacer()
                        Text("\(monster.currentHP) 💀")
                            .font(.custom("Georgia Bold", size: 13))
                            .foregroundStyle(.white)
                    }
                    HealthBar(
                        progress: monster.hpPercent,
                        color: monster.isEnraged ? .orange : monster.type.tint,
                        height: 8
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }
}

struct HealthBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: [color, color.opacity(0.7)],
                                          startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * max(0, min(1, progress)))
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: height)
    }
}

struct ComboBadge: View {
    let combo: Int
    @State private var scale = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Text("⚡️ \(combo)x")
                .font(.custom("Georgia Bold", size: 14))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(hex: "#F7C948")))
        }
        .scaleEffect(scale)
        .onChange(of: combo) { _, _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { scale = 1.3 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring()) { scale = 1.0 }
            }
        }
    }
}

// ─── Swipe Hints ──────────────────────────────────────────────────────────────

struct SwipeHintsRow: View {
    var body: some View {
        HStack {
            Label("DELETE", systemImage: "trash.fill")
                .font(.custom("Georgia Bold", size: 13, relativeTo: .body))
                .foregroundStyle(Color(hex: "#E84545").opacity(0.8))
                .padding(.horizontal, 16)

            Spacer()

            Label("KEEP", systemImage: "heart.fill")
                .font(.custom("Georgia Bold", size: 13, relativeTo: .body))
                .foregroundStyle(Color(hex: "#4CAF50").opacity(0.8))
                .padding(.horizontal, 16)
        }
    }
}

// ─── XP Gain Popup ────────────────────────────────────────────────────────────

struct XPGainPopup: View {
    let text: String
    @State private var offset: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.custom("Georgia Bold", size: 18, relativeTo: .title3))
            .foregroundStyle(Color(hex: "#F7C948"))
            .shadow(color: Color(hex: "#F7C948"), radius: 6)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { offset = -40 }
            }
    }
}

// ─── Combo Flash ─────────────────────────────────────────────────────────────

struct ComboFlashView: View {
    let combo: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("COMBO!")
                .font(.custom("Georgia Bold", size: 28, relativeTo: .title))
                .foregroundStyle(Color(hex: "#F7C948"))
                .shadow(color: Color(hex: "#F7C948"), radius: 12)
            Text("×\(combo)")
                .font(.custom("Georgia Bold", size: 48, relativeTo: .largeTitle))
                .foregroundStyle(.white)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#F7C948").opacity(0.6), lineWidth: 2)
                )
        )
    }
}
