// Views/Achievements/AchievementsView.swift

import SwiftUI
import SwiftData

struct AchievementsView: View {
    let hero: Hero
    @Query private var records: [AchievementRecord]
    @State private var selectedCategory: AchievementDefinition.Category? = nil

    var filteredDefs: [AchievementDefinition] {
        let cat = selectedCategory
        return AchievementDefinition.all.filter { cat == nil || $0.category == cat }
    }

    func record(for def: AchievementDefinition) -> AchievementRecord? {
        records.first { $0.definitionID == def.id }
    }

    var unlockedCount: Int { records.filter(\.isUnlocked).count }

    var body: some View {
        NavigationStack {
            ZStack {
                DungeonBackground()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Feats of Legend")
                            .font(.custom("Georgia Bold", size: 28))
                            .foregroundStyle(Color(hex: "#F7C948"))
                        Text("\(unlockedCount) / \(AchievementDefinition.all.count) unlocked")
                            .font(.custom("Georgia", size: 14))
                            .foregroundStyle(.secondary)

                        // Overall progress
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(LinearGradient(colors: [Color(hex: "#F7C948"), Color(hex: "#E8A020")],
                                                          startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * Double(unlockedCount) / Double(max(1, AchievementDefinition.all.count)))
                            }
                        }
                        .frame(height: 6)
                        .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 20)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryChip(label: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(AchievementDefinition.Category.allCases, id: \.self) { cat in
                                CategoryChip(label: cat.rawValue, isSelected: selectedCategory == cat) {
                                    selectedCategory = selectedCategory == cat ? nil : cat
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)

                    // Grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(filteredDefs) { def in
                                AchievementCard(
                                    def: def,
                                    record: record(for: def)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct AchievementCard: View {
    let def: AchievementDefinition
    let record: AchievementRecord?

    var isUnlocked: Bool { record?.isUnlocked ?? false }
    var progress: Double {
        guard let r = record, def.goal > 0 else { return 0 }
        return Double(r.progress) / Double(def.goal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color(hex: "#F7C948").opacity(0.2) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                    Image(systemName: def.icon)
                        .font(.title3)
                        .foregroundStyle(isUnlocked ? Color(hex: "#F7C948") : .secondary)
                }

                Spacer()

                if isUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color(hex: "#4CAF50"))
                        .font(.title3)
                }
            }

            Text(def.title)
                .font(.custom("Georgia Bold", size: 14))
                .foregroundStyle(isUnlocked ? .white : .secondary)
                .lineLimit(2)

            Text(def.description)
                .font(.custom("Georgia", size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if !isUnlocked {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(Color(hex: "#F7C948").opacity(0.6))
                            .frame(width: geo.size.width * min(1, progress))
                    }
                }
                .frame(height: 4)
            }

            HStack(spacing: 8) {
                Label("+\(def.gemReward)", systemImage: "diamond.fill")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#00BCD4"))
                if def.xpReward > 0 {
                    Label("+\(def.xpReward) XP", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#F7C948"))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isUnlocked ? Color(hex: "#F7C948").opacity(0.3) : Color.white.opacity(0.07), lineWidth: 1)
                )
        )
        .opacity(isUnlocked ? 1 : 0.7)
    }
}

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Georgia Bold", size: 13))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "#F7C948") : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}
