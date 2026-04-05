// ContentView.swift (RootView + MainTabView)

import SwiftUI
import SwiftData

@MainActor
struct RootView: View {
    @Query private var heroes: [Hero]
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "pq_onboarding_v1")
    @State private var isInsertingHero = false

    var body: some View {
        Group {
            if !onboardingComplete {
                OnboardingFlow {
                    UserDefaults.standard.set(true, forKey: "pq_onboarding_v1")
                    onboardingComplete = true
                    ensureHeroExists()
                }
            } else {
                if let hero = heroes.first {
                    MainTabView(hero: hero)
                        .environment(appState)
                } else {
                    // SwiftData hasn't loaded hero yet, or first launch post-onboarding
                    ZStack {
                        Color.black.ignoresSafeArea()
                        ProgressView()
                            .tint(.yellow)
                    }
                    .onAppear { ensureHeroExists() }
                }
            }
        }
        .environment(appState)
        .onChange(of: heroes) { _, newHeroes in
            if newHeroes.isEmpty && onboardingComplete {
                ensureHeroExists()
            }
        }
    }

    private func ensureHeroExists() {
        guard heroes.isEmpty && !isInsertingHero else { return }
        isInsertingHero = true
        let hero = Hero()
        modelContext.insert(hero)
        // Seed default achievements
        AchievementDefinition.all.forEach { def in
            let record = AchievementRecord(definitionID: def.id)
            modelContext.insert(record)
        }
        // Seed default cosmetics
        CosmeticItem.defaults.forEach { item in
            modelContext.insert(item)
        }
        // Flush immediately so the @Query reflects the new hero before any
        // reactive onChange can fire and call ensureHeroExists() a second time.
        try? modelContext.save()
    }
}

// MARK: - Main Tab Container

struct MainTabView: View {
    let hero: Hero
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            TabView(selection: $appState.selectedTab) {
                HeroDashboardView(hero: hero)
                    .tabItem { Label("Quest", systemImage: "shield.fill") }
                    .tag(0)

                AchievementsView(hero: hero)
                    .tabItem { Label("Feats", systemImage: "trophy.fill") }
                    .tag(1)

                CosmeticShopView(hero: hero)
                    .tabItem { Label("Forge", systemImage: "sparkles") }
                    .tag(2)

                SettingsView(hero: hero)
                    .tabItem { Label("Sanctum", systemImage: "gearshape.fill") }
                    .tag(3)
            }
            .tint(Color("GoldAccent"))
        }
        .fullScreenCover(isPresented: $appState.isInCombat) {
            if let session = appState.activeCombatSession {
                CombatView(session: session, hero: hero)
                    .environment(appState)
            }
        }
        .sheet(isPresented: $appState.showLevelUp) {
            LevelUpView(level: hero.level)
                .presentationDetents([.medium])
                .presentationBackground(.ultraThinMaterial)
        }
    }
}
