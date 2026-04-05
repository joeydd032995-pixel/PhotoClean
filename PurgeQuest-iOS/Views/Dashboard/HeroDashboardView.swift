// Views/Dashboard/HeroDashboardView.swift
// Main hero screen: stats, XP, storage savings, dungeon entry.

import SwiftUI
import SwiftData

struct HeroDashboardView: View {
    let hero: Hero
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var dailyQuests: [DailyQuestRecord]
    @State private var pulseEnter = false
    @State private var showQuests = false

    var todayQuests: [DailyQuestRecord] {
        let today = Calendar.current.startOfDay(for: .now)
        let relevant = dailyQuests.filter { $0.createdDate == today }
        return relevant.isEmpty ? [] : relevant
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DungeonBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // ─ Hero Header ────────────────────────────────────────
                        HeroHeaderCard(hero: hero)
                            .padding(.top, 16)

                        // ─ Stats Row ──────────────────────────────────────────
                        StatsRow(hero: hero)

                        // ─ Storage Meter ──────────────────────────────────────
                        StorageMeterCard(hero: hero, stats: appState.libraryStats)

                        // ─ Daily Quests ───────────────────────────────────────
                        if !todayQuests.isEmpty {
                            DailyQuestsCard(quests: todayQuests)
                        }

                        // ─ Enter Dungeon Button ───────────────────────────────
                        EnterDungeonButton(isLoading: appState.isDungeonLoading) {
                            Task { await appState.enterDungeon(hero: hero, modelContext: modelContext) }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                if let error = appState.dungeonLoadError {
                    DungeonErrorBanner(message: error) {
                        appState.dungeonLoadError = nil
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: appState.dungeonLoadError)
                }
            }
        }
        .onAppear { ensureDailyQuests() }
    }

    private func ensureDailyQuests() {
        let today = Calendar.current.startOfDay(for: .now)
        let alreadyHasToday = dailyQuests.contains { $0.createdDate == today }
        if !alreadyHasToday {
            let newQuests = DailyQuestGenerator.generateQuests()
            newQuests.forEach { modelContext.insert($0) }
        }
    }
}

// ─── Hero Header Card ─────────────────────────────────────────────────────────

struct HeroHeaderCard: View {
    let hero: Hero

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 20) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(colors: [hero.heroClass.color.opacity(0.4), .clear],
                                           center: .center, startRadius: 0, endRadius: 50)
                        )
                        .frame(width: 88, height: 88)
                    Text(hero.heroClass.icon)
                        .font(.system(size: 48))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(hero.heroClass.flavorTitle)
                        .font(.custom("Georgia", size: 12))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(2)

                    Text(hero.heroClass.rawValue)
                        .font(.custom("Georgia Bold", size: 22))
                        .foregroundStyle(.white)

                    Text("Level \(hero.level)")
                        .font(.custom("Georgia Bold", size: 30))
                        .foregroundStyle(hero.heroClass.color)

                    // XP Bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("XP")
                                .font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(hero.currentXP) / \(hero.xpForNextLevel)")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        XPBar(progress: hero.xpProgress, color: hero.heroClass.color)
                    }
                }
                Spacer()
            }
            .padding(20)

            // HP Bar
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(LinearGradient(colors: [.red, Color(hex: "#FF6B6B")],
                                                  startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * Double(hero.currentHP) / Double(hero.maxHP))
                    }
                }
                .frame(height: 8)
                Text("\(hero.currentHP)/\(hero.maxHP)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(hero.heroClass.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

struct StatsRow: View {
    let hero: Hero

    var body: some View {
        HStack(spacing: 12) {
            StatPill(label: "Streak", value: "\(hero.currentStreak)d", icon: "flame.fill", color: .orange)
            StatPill(label: "Deleted", value: "\(hero.totalPhotosDeleted)", icon: "trash.fill", color: .red)
            StatPill(label: "Gems", value: "\(hero.storageGems)", icon: "diamond.fill", color: Color(hex: "#00BCD4"))
        }
        .padding(.horizontal, 20)
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.custom("Georgia Bold", size: 18))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
        )
    }
}

// ─── Storage Meter ────────────────────────────────────────────────────────────

struct StorageMeterCard: View {
    let hero: Hero
    let stats: LibraryStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundStyle(Color(hex: "#F7C948"))
                Text("Storage Freed")
                    .font(.custom("Georgia Bold", size: 16))
                    .foregroundStyle(.white)
                Spacer()
                Text(hero.totalBytesDeleted.formattedBytes())
                    .font(.custom("Georgia Bold", size: 22))
                    .foregroundStyle(Color(hex: "#4CAF50"))
            }

            if let stats = stats {
                VStack(spacing: 4) {
                    HStack {
                        Text("Library size: ~\(String(format: "%.1f", stats.estimatedGB)) GB")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(stats.totalPhotoCount) photos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#8BC34A")],
                                                      startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * min(1, hero.mbDeleted / stats.estimatedMB),
                                       height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#4CAF50").opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }

}

// ─── Daily Quests Card ────────────────────────────────────────────────────────

struct DailyQuestsCard: View {
    let quests: [DailyQuestRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "scroll.fill")
                    .foregroundStyle(Color(hex: "#F7C948"))
                Text("Daily Quests")
                    .font(.custom("Georgia Bold", size: 16))
                    .foregroundStyle(.white)
                Spacer()
                let completed = quests.filter(\.isCompleted).count
                Text("\(completed)/\(quests.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(quests) { quest in
                QuestRow(quest: quest)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F7C948").opacity(0.2), lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }
}

struct QuestRow: View {
    let quest: DailyQuestRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: quest.questType.icon)
                .font(.title3)
                .foregroundStyle(quest.isCompleted ? Color(hex: "#4CAF50") : Color(hex: "#F7C948"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(quest.title)
                    .font(.custom("Georgia Bold", size: 14))
                    .foregroundStyle(quest.isCompleted ? .secondary : .white)
                    .strikethrough(quest.isCompleted)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                        Capsule()
                            .fill(quest.isCompleted ? Color(hex: "#4CAF50") : Color(hex: "#F7C948"))
                            .frame(width: geo.size.width * quest.progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(quest.progressText)
                    .font(.caption2).foregroundStyle(.secondary)
                Text("+\(quest.gemReward)💎")
                    .font(.caption2).foregroundStyle(Color(hex: "#00BCD4"))
            }
        }
    }
}

// ─── Enter Dungeon Button ─────────────────────────────────────────────────────

struct EnterDungeonButton: View {
    let isLoading: Bool
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsing glow
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "#F7C948").opacity(0.15))
                    .scaleEffect(pulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)

                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#F7C948"), Color(hex: "#E8611A")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                if isLoading {
                    HStack(spacing: 14) {
                        ProgressView().tint(.black)
                        Text("Scanning dungeon...")
                            .font(.custom("Georgia Bold", size: 18))
                            .foregroundStyle(.black)
                    }
                } else {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.down.to.line.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.black)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enter the Dungeon")
                                .font(.custom("Georgia Bold", size: 20))
                                .foregroundStyle(.black)
                            Text("Find and slay your clutter")
                                .font(.custom("Georgia", size: 13))
                                .foregroundStyle(.black.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.black.opacity(0.6))
                    }
                    .padding(.horizontal, 24)
                }
            }
            .frame(height: 72)
            .contentShape(Rectangle())
            .shadow(color: Color(hex: "#F7C948").opacity(0.4), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onAppear { pulse = true }
    }
}

// ─── XP Bar Component ─────────────────────────────────────────────────────────

struct XPBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(LinearGradient(colors: [color, color.opacity(0.6)],
                                          startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * min(1, progress))
                    .animation(.spring(response: 0.6), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// ─── Dungeon Background ───────────────────────────────────────────────────────

struct DungeonBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#080810"), Color(hex: "#10081A"), Color(hex: "#080A10")],
                startPoint: .top, endPoint: .bottom
            )
            StarsBackground()
        }
        .ignoresSafeArea()
    }
}

struct DungeonErrorBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding()
        .background(Color(hex: "#1A1A2E"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .shadow(radius: 8)
    }
}
