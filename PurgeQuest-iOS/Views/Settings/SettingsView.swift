// Views/Settings/SettingsView.swift

import SwiftUI
import SwiftData

struct SettingsView: View {
    let hero: Hero
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [AchievementRecord]
    @Query private var deletedRecords: [DeletedPhotoRecord]
    @State private var showResetConfirm = false
    @State private var showPrivacySheet = false

    var activeTrashCount: Int {
        deletedRecords.filter { $0.isWithinUndoWindow && !$0.wasRestored }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DungeonBackground()

                List {
                    // ─ Hero Section ───────────────────────────────────────────
                    Section {
                        HeroSummaryRow(hero: hero)
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    // ─ Stats ──────────────────────────────────────────────────
                    Section("Battle Statistics") {
                        SettingsStatRow(label: "Total Photos Deleted", value: "\(hero.totalPhotosDeleted)")
                        SettingsStatRow(label: "Total Photos Spared", value: "\(hero.totalPhotosSpared)")
                        SettingsStatRow(label: "Storage Freed", value: formatBytes(hero.totalBytesDeleted))
                        SettingsStatRow(label: "Bosses Defeated", value: "\(hero.bossesDefeated)")
                        SettingsStatRow(label: "Highest Combo", value: "×\(hero.highestCombo)")
                        SettingsStatRow(label: "Dungeon Floor", value: "\(hero.dungeonFloor)")
                        SettingsStatRow(label: "Longest Streak", value: "\(hero.longestStreak) days")
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    // ─ Undo Trash ─────────────────────────────────────────────
                    if activeTrashCount > 0 {
                        Section("Recent Deletions") {
                            NavigationLink {
                                UndoTrashView(records: deletedRecords.filter { $0.isWithinUndoWindow && !$0.wasRestored })
                            } label: {
                                HStack {
                                    Image(systemName: "trash.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text("View Recent Deletions")
                                    Spacer()
                                    Text("\(activeTrashCount) items")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }

                    // ─ Privacy ────────────────────────────────────────────────
                    Section("Privacy") {
                        Button {
                            showPrivacySheet = true
                        } label: {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(.green)
                                Text("Privacy Policy")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))

                        HStack {
                            Image(systemName: "iphone")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Data Collection")
                                    .foregroundStyle(.white)
                                Text("None. Everything stays on your device.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    // ─ Danger Zone ────────────────────────────────────────────
                    Section("Danger Zone") {
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text("Reset All Progress")
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text("PurgeQuest v1.0")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("com.purgequest.app")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary.opacity(0.5))
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Sanctum")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Reset All Progress?", isPresented: $showResetConfirm) {
            Button("Reset Everything", role: .destructive) { resetProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your hero, all achievements, cosmetics, and quest history. Photo deletions already performed will NOT be reversed.")
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyView()
        }
    }

    private func resetProgress() {
        // Delete all SwiftData objects
        allRecords.forEach { modelContext.delete($0) }
        deletedRecords.forEach { modelContext.delete($0) }
        modelContext.delete(hero)
        UserDefaults.standard.removeObject(forKey: "pq_onboarding_v1")
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1 { return String(format: "%.2f GB", gb) }
        let mb = Double(bytes) / 1_048_576
        if mb >= 0.1 { return String(format: "%.1f MB", mb) }
        return "\(bytes) B"
    }
}

struct HeroSummaryRow: View {
    let hero: Hero
    var body: some View {
        HStack(spacing: 16) {
            Text(hero.heroClass.icon)
                .font(.system(size: 44))
            VStack(alignment: .leading, spacing: 4) {
                Text(hero.heroClass.rawValue)
                    .font(.custom("Georgia Bold", size: 18))
                    .foregroundStyle(.white)
                Text("Level \(hero.level) · \(hero.heroClass.flavorTitle)")
                    .font(.custom("Georgia", size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsStatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.white)
            Spacer()
            Text(value)
                .foregroundStyle(Color(hex: "#F7C948"))
                .font(.custom("Georgia Bold", size: 15))
        }
    }
}

// ─── Undo Trash View ──────────────────────────────────────────────────────────

struct UndoTrashView: View {
    let records: [DeletedPhotoRecord]

    var body: some View {
        ZStack {
            DungeonBackground()
            List {
                Section {
                    Text("Photos deleted in the last 7 days. iOS stores them in the Recently Deleted album until they are permanently removed.")
                        .font(.custom("Georgia", size: 14))
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
                ForEach(records) { record in
                    HStack(spacing: 14) {
                        if let data = record.thumbnailData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 52, height: 52)
                                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.monsterType)
                                .font(.custom("Georgia Bold", size: 13))
                                .foregroundStyle(.white)
                            Text(record.deletedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(.secondary)
                            let mb = Double(record.fileSizeBytes) / 1_048_576
                            Text(mb >= 1 ? String(format: "%.1f MB", mb) : "\(record.fileSizeBytes) B")
                                .font(.caption2).foregroundStyle(Color(hex: "#4CAF50"))
                        }
                        Spacer()
                        VStack {
                            let daysLeft = max(0, 7 - Int(Date.now.timeIntervalSince(record.deletedAt) / 86400))
                            Text("\(daysLeft)d")
                                .font(.caption2).foregroundStyle(.secondary)
                            Text("left")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Recent Deletions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ─── Privacy Policy View ──────────────────────────────────────────────────────

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DungeonBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PrivacySection(title: "Data Collection", content:
                            "PurgeQuest collects NO data. None. Zero. We have no servers, no analytics, no advertising SDK, and no way to receive your data even if we wanted it.")

                        PrivacySection(title: "Photo Access", content:
                            "PurgeQuest requests read/write access to your photo library solely to display photos for review and to delete photos you explicitly approve. No photos are uploaded or transmitted.")

                        PrivacySection(title: "On-Device Processing", content:
                            "All analysis (blur detection, duplicate detection, quality scoring) runs entirely on your iPhone using Apple's Vision framework. No photo data ever leaves your device.")

                        PrivacySection(title: "Deletions", content:
                            "Photos are only deleted after you review them in the Room Summary and confirm the deletion. iOS will ask for additional confirmation. Deleted photos enter iOS's 'Recently Deleted' album and remain there for 30 days before permanent deletion.")

                        PrivacySection(title: "Game Data", content:
                            "Your hero progress, achievements, and cosmetics are stored locally using SwiftData. This data never leaves your device.")

                        PrivacySection(title: "Network Access", content:
                            "PurgeQuest requires no network connection and makes zero network requests. All features work completely offline.")

                        Text("Last updated: March 2026")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#F7C948"))
                }
            }
        }
    }
}

struct PrivacySection: View {
    let title: String
    let content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Georgia Bold", size: 17))
                .foregroundStyle(Color(hex: "#F7C948"))
            Text(content)
                .font(.custom("Georgia", size: 15))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(4)
        }
    }
}

// ─── Level Up View ────────────────────────────────────────────────────────────

struct LevelUpView: View {
    let level: Int
    let hero: Hero
    @Environment(\.dismiss) private var dismiss
    @State private var animateIcon = false
    @State private var showStats = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            // Confetti rains behind everything
            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("⚔️")
                    .font(.system(size: 80))
                    .scaleEffect(animateIcon ? 1.2 : 0.8)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.4).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                    .shadow(color: Color(hex: "#F7C948").opacity(0.8), radius: animateIcon ? 30 : 8)

                VStack(spacing: 8) {
                    Text("LEVEL UP!")
                        .font(.custom("Georgia Bold", size: 36))
                        .foregroundStyle(Color(hex: "#F7C948"))
                        .shadow(color: Color(hex: "#F7C948"), radius: 12)

                    Text("You are now Level \(level)")
                        .font(.custom("Georgia", size: 20))
                        .foregroundStyle(.white.opacity(0.9))
                }

                // Stat badges fly in from below after a short delay
                if showStats {
                    HStack(spacing: 20) {
                        LevelUpStatBadge(icon: "❤️", label: "MAX HP", value: "+10")
                        LevelUpStatBadge(icon: "⚔️", label: "ATK",    value: "+2")
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button("Onward!") { dismiss() }
                    .font(.custom("Georgia Bold", size: 18))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(LinearGradient(
                            colors: [Color(hex: "#F7C948"), Color(hex: "#E8A020")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                    )
            }
            .padding(.horizontal, 24)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showStats)
        .onAppear {
            animateIcon = true
            HapticService.shared.levelUp()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showStats = true
            }
        }
    }
}

private struct LevelUpStatBadge: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 28))
            Text(value)
                .font(.custom("Georgia Bold", size: 22))
                .foregroundStyle(Color(hex: "#F7C948"))
            Text(label)
                .font(.custom("Georgia", size: 11))
                .foregroundStyle(.secondary)
                .tracking(2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#F7C948").opacity(0.3), lineWidth: 1)
                )
        )
    }
}
