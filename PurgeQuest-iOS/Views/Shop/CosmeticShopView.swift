// Views/Shop/CosmeticShopView.swift

import SwiftUI
import SwiftData

struct CosmeticShopView: View {
    let hero: Hero
    @Query private var items: [CosmeticItem]
    @State private var selectedType: CosmeticType = .skin
    @State private var previewItem: CosmeticItem? = nil
    @State private var showInsufficientGems = false
    @State private var recentlyPurchased: String? = nil

    var filteredItems: [CosmeticItem] {
        items.filter { $0.type == selectedType }
             .sorted {
                 // Unlocked items first, then locked; within each group sort by cost.
                 if $0.isUnlocked != $1.isUnlocked { return $0.isUnlocked && !$1.isUnlocked }
                 return $0.gemCost < $1.gemCost
             }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DungeonBackground()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text("The Forge")
                            .font(.custom("Georgia Bold", size: 28))
                            .foregroundStyle(Color(hex: "#F7C948"))
                        Text("Spend your hard-earned Storage Gems")
                            .font(.custom("Georgia", size: 14))
                            .foregroundStyle(.secondary)

                        // Gem balance
                        HStack(spacing: 8) {
                            Image(systemName: "diamond.fill")
                                .foregroundStyle(Color(hex: "#00BCD4"))
                            Text("\(hero.storageGems) Gems")
                                .font(.custom("Georgia Bold", size: 22))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#00BCD4").opacity(0.12))
                                .overlay(Capsule().stroke(Color(hex: "#00BCD4").opacity(0.3), lineWidth: 1))
                        )
                    }
                    .padding(.vertical, 20)

                    // Type selector
                    HStack(spacing: 0) {
                        ForEach(CosmeticType.allCases, id: \.self) { type in
                            Button {
                                withAnimation(.spring()) { selectedType = type }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.title3)
                                    Text(type.rawValue)
                                        .font(.custom("Georgia Bold", size: 13))
                                }
                                .foregroundStyle(selectedType == type ? .black : .white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                                .background(
                                    selectedType == type
                                    ? AnyView(LinearGradient(
                                        colors: [Color(hex: "#F7C948"), Color(hex: "#E8A020")],
                                        startPoint: .top, endPoint: .bottom))
                                    : AnyView(Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Item grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(filteredItems, id: \.id) { item in
                                ShopItemCard(
                                    item: item,
                                    isEquipped: isEquipped(item),
                                    canAfford: hero.storageGems >= item.gemCost
                                ) {
                                    handleItemTap(item)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Not Enough Gems", isPresented: $showInsufficientGems) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Delete more photos to earn Storage Gems!\n1 MB deleted = 1 Gem")
            }
            .overlay {
                if let purchased = recentlyPurchased {
                    VStack {
                        Spacer()
                        Text("✅ \(purchased) equipped!")
                            .font(.custom("Georgia Bold", size: 16))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color(hex: "#4CAF50").opacity(0.9)))
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: recentlyPurchased)
                }
            }
        }
    }

    private func isEquipped(_ item: CosmeticItem) -> Bool {
        switch item.type {
        case .skin:   return hero.equippedSkinID == item.id
        case .weapon: return hero.equippedWeaponID == item.id
        case .pet:    return hero.equippedPetID == item.id
        }
    }

    private func handleItemTap(_ item: CosmeticItem) {
        if item.isUnlocked {
            equipItem(item)
            return
        }
        guard hero.storageGems >= item.gemCost else {
            showInsufficientGems = true
            return
        }
        hero.spendGems(item.gemCost)
        item.isUnlocked = true
        item.unlockedAt = .now
        equipItem(item)
    }

    private func equipItem(_ item: CosmeticItem) {
        switch item.type {
        case .skin:   hero.equippedSkinID = item.id
        case .weapon: hero.equippedWeaponID = item.id
        case .pet:    hero.equippedPetID = item.id
        }
        recentlyPurchased = item.displayName
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { recentlyPurchased = nil }
        HapticService.shared.achievementUnlocked()
    }
}

struct ShopItemCard: View {
    let item: CosmeticItem
    let isEquipped: Bool
    let canAfford: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: item.colorHex).opacity(isEquipped ? 0.3 : 0.1))
                        .frame(width: 70, height: 70)

                    Image(systemName: item.sfSymbol)
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hex: item.colorHex))

                    if isEquipped {
                        Circle()
                            .stroke(Color(hex: "#F7C948"), lineWidth: 2)
                            .frame(width: 70, height: 70)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "#F7C948"))
                            .background(Circle().fill(.black))
                            .offset(x: 24, y: -24)
                    }

                    if item.isPremiumOnly && !item.isUnlocked {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .offset(x: 24, y: -24)
                    }
                }

                VStack(spacing: 4) {
                    Text(item.displayName)
                        .font(.custom("Georgia Bold", size: 13))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(item.flavorText)
                        .font(.custom("Georgia", size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }

                // Status / price
                if item.isUnlocked {
                    Text(isEquipped ? "Equipped" : "Equip")
                        .font(.custom("Georgia Bold", size: 12))
                        .foregroundStyle(isEquipped ? Color(hex: "#4CAF50") : Color(hex: "#F7C948"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isEquipped ? Color(hex: "#4CAF50").opacity(0.15) : Color(hex: "#F7C948").opacity(0.1))
                        )
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.caption2)
                            .foregroundStyle(canAfford ? Color(hex: "#00BCD4") : .secondary)
                        Text("\(item.gemCost)")
                            .font(.custom("Georgia Bold", size: 13))
                            .foregroundStyle(canAfford ? Color(hex: "#00BCD4") : .secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#00BCD4").opacity(canAfford ? 0.12 : 0.05))
                    )
                    .opacity(canAfford ? 1 : 0.5)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isEquipped ? Color(hex: "#F7C948").opacity(0.4)
                                    : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
