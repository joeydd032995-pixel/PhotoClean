// PurgeQuestApp.swift
// PurgeQuest – Slay your camera roll. One swipe at a time.
// iOS 18+ | Swift 6 | SwiftData | Vision | PHPhotoLibrary

import SwiftUI
import SwiftData

@main
struct PurgeQuestApp: App {

    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Hero.self,
                AchievementRecord.self,
                CosmeticItem.self,
                DailyQuestRecord.self,
                DeletedPhotoRecord.self,
            ])
            let config = ModelConfiguration("PurgeQuest", schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed to initialize: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
