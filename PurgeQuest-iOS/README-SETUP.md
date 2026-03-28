# PurgeQuest – iOS App Setup Guide

**Bundle ID:** `com.purgequest.app`
**Target:** iOS 18+ | iPhone 12+
**Language:** Swift 6 | SwiftUI | SwiftData

---

## Project File Structure

```
PurgeQuest-iOS/
├── PurgeQuestApp.swift              ← @main entry, SwiftData container
├── ContentView.swift                ← RootView + MainTabView
├── Info.plist                       ← App metadata, permissions
├── PrivacyInfo.xcprivacy            ← App Store privacy manifest
│
├── Models/
│   ├── Hero.swift                   ← @Model hero with XP, levels, class
│   ├── MonsterModels.swift          ← Monster types, rooms, combat session
│   ├── Achievement.swift            ← @Model records + static definitions
│   ├── CosmeticItem.swift           ← @Model shop items
│   └── QuestAndTrashModels.swift    ← Daily quests + 7-day undo trash
│
├── Services/
│   ├── PhotoLibraryService.swift    ← PHPhotoLibrary: auth, fetch, delete
│   ├── MLAnalysisService.swift      ← Vision: blur, duplicates, quality
│   ├── HapticService.swift          ← CoreHaptics + UIFeedbackGenerator
│   └── FlavorTextService.swift      ← Procedural text (Foundation Models placeholder)
│
├── ViewModels/
│   ├── AppState.swift               ← Root @Observable state
│   └── CombatViewModel.swift        ← Swipe mechanics, combo, animations
│
└── Views/
    ├── Onboarding/
    │   └── OnboardingFlow.swift     ← 4-page onboarding + permission
    ├── Dashboard/
    │   └── HeroDashboardView.swift  ← Hero stats, storage, quests, enter dungeon
    ├── Combat/
    │   ├── CombatView.swift         ← Full-screen combat with HUD
    │   └── CombatComponents.swift   ← MonsterView, SwipePhotoCard, RoomSummaryView
    ├── Achievements/
    │   └── AchievementsView.swift   ← Achievement gallery with progress
    ├── Shop/
    │   └── CosmeticShopView.swift   ← Cosmetic store (gems currency)
    └── Settings/
        └── SettingsView.swift       ← Stats, privacy, reset, undo trash
```

---

## Xcode Project Setup (Step by Step)

### 1. Create the Xcode Project

1. Open **Xcode 16** (requires iOS 18 SDK)
2. File → New → Project → **App**
3. Configure:
   - **Product Name:** `PurgeQuest`
   - **Bundle Identifier:** `com.purgequest.app`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** SwiftData ✅
4. Choose a location and click **Create**

### 2. Add All Source Files

1. Delete the auto-generated `ContentView.swift` and `[AppName]App.swift`
2. In Finder, copy all `.swift` files from this repo into the Xcode project folder
3. In Xcode: File → Add Files to "PurgeQuest" → select all `.swift` files
4. Make sure all files are added to the **PurgeQuest** target

### 3. Replace Info.plist

1. In Xcode project navigator, open `Info.plist`
2. Copy the contents from `Info.plist` in this repo (or merge the keys)
3. Critical keys to add:
   - `NSPhotoLibraryUsageDescription`
   - `UIUserInterfaceStyle` = `Dark`
   - `UISupportedInterfaceOrientations` = Portrait only

### 4. Add PrivacyInfo.xcprivacy

1. File → New → File → **App Privacy** → name it `PrivacyInfo`
2. Replace the content with `PrivacyInfo.xcprivacy` from this repo
3. **Important:** This file must be in the app target (not a framework)

### 5. Configure Deployment Target

1. Click the project root → Target → General
2. Set **Minimum Deployments** to **iOS 18.0**
3. Set **Supported Destinations** to iPhone only

### 6. Enable Frameworks

In Target → General → Frameworks, Libraries, and Embedded Content, verify these are present (they're system frameworks, no manual linking needed):
- `Photos.framework`
- `PhotosUI.framework`
- `Vision.framework`
- `CoreHaptics.framework`
- `CoreML.framework` (for future custom models)

### 7. SwiftData Container

The `PurgeQuestApp.swift` sets up the `ModelContainer` with all models. No additional configuration needed.

### 8. Build & Run

1. Select an **iPhone 15 Pro** simulator or a real device
2. **⌘+B** to build
3. **⌘+R** to run

> **Note:** Photo library access only works on a **real device** or a simulator with photos added. The simulator has no photos by default — use Device → Trigger Photo Library Access to add sample photos.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│                     AppState                          │
│   @Observable root state – dungeon, navigation,      │
│   active session, library stats                      │
└────────────────┬─────────────────────────────────────┘
                 │ @Environment
      ┌──────────┼──────────────┐
      ▼          ▼              ▼
 Dashboard    Combat         Shop/Achievements
   View        View          Views
      │          │
      │    CombatViewModel
      │    (swipe, combo,
      │     animations)
      │
  SwiftData
  (Hero, Achievements,
   CosmeticItems, Quests,
   DeletedPhotoRecords)
```

---

## Core Game Loop

1. **Enter Dungeon** → `AppState.enterDungeon()`:
   - Requests photo library permission
   - Fetches up to 150 photos
   - Runs `MLAnalysisService.analyzeAndGroup()` (Vision, async)
   - Groups photos by monster type into rooms of 15–25 photos
   - Creates `CombatSession` for first room

2. **Combat** → `CombatViewModel`:
   - `swipeLeft()` → Photo marked for deletion → Monster takes damage → XP + Gems
   - `swipeRight()` → Photo spared → Monster attacks hero → Hero loses HP
   - Combo multiplier activates at ×5, ×10
   - Room complete when all photos decided or monster HP = 0

3. **Room Summary** → `RoomSummaryView`:
   - Shows loot: deletions, XP, gems, storage freed
   - **User must confirm deletions** – `PHPhotoLibrary.performChanges()`
   - 7-day undo window via `DeletedPhotoRecord`
   - Advance to next room or exit dungeon

4. **Post-Session**:
   - Hero XP/level updated
   - Daily quest progress tracked
   - Achievements checked and unlocked

---

## ML Analysis (Vision Framework)

| Detection        | Vision API                            | Threshold         |
|-----------------|---------------------------------------|-------------------|
| Blur             | Laplacian variance (custom impl)     | variance < 80     |
| Duplicates       | `VNGenerateImageFeaturePrintRequest`  | distance < 0.12   |
| Screenshots      | `PHAsset.mediaSubtypes` + text density| > 10 text blocks  |
| Low quality      | Average brightness analysis           | < 0.3 score       |
| Dark photos      | Average brightness                    | < 0.10            |
| Old photos       | `PHAsset.creationDate`                | > 5 years ago     |

### Custom Core ML Models (Future v1.1)

Add `.mlmodel` files to the project for:
- `BlurClassifier.mlmodel` – binary blur/sharp classifier (MobileNetV3 fine-tuned)
- `QualityScorer.mlmodel` – aesthetic quality regression (NIMA-style)

Place in `Resources/MLModels/` and reference in `MLAnalysisService.swift` (placeholders marked with `// TODO: CoreML`).

---

## Cosmetic System

- **Currency:** Storage Gems (1 MB deleted = 1 Gem)
- **Categories:** Skins, Weapons, Pets
- **Free starter:** Iron Knight skin + Pixel Broom weapon
- **Premium items:** Marked `isPremiumOnly` – can be purchased via IAP (StoreKit 2, v1.1)

---

## App Store Submission Notes

### Safety Documentation
Include in App Review notes:
> "PurgeQuest deletes photos via `PHAssetChangeRequest.deleteAssets()`, which is the iOS-sanctioned API. The user reviews each batch in the Room Summary screen and must confirm deletion with a UIAlert. iOS then presents its own native confirmation. Deleted photos enter the iOS 'Recently Deleted' album (30-day retention). PurgeQuest tracks a 7-day local undo window and warns users before any destructive action."

### Privacy Nutrition Label
- **Data Not Collected** (all categories)
- **No tracking**
- **No third-party SDKs**

### Screenshot Ideas (6.7" / 6.1" / iPad)
1. Hero Dashboard – hero at level 15 with XP bar, "Enter Dungeon" glowing button
2. Combat Screen – scary Duplicate Dragon, photo card mid-swipe with red DELETE overlay
3. Room Summary – loot explosion with "1.2 GB FREED!"
4. Achievements – gold achievement cards unlocked
5. Shop – cosmetic grid with gem balance
6. Onboarding page 1 – "Your Camera Roll Is a Dungeon."

---

## Future Roadmap

### v1.1 (Video Support)
- `VideoVampire` monster type (activate by removing placeholder guard in `MonsterType`)
- `AVFoundation` for video thumbnail + duration analysis

### v1.1 (IAP)
- StoreKit 2 integration for premium cosmetics
- "Starter Pack" one-time purchase

### v2.0 (Seasonal Events)
- `SeasonalDungeon` model with time-limited monster variants
- Halloween: Ghost Gallery event (delete spoooky themed monsters)
- New Year: "Archive Purge 2026" event

### v2.0 (WidgetKit)
- "Daily Dungeon Reminder" widget showing streak + gems
- Live Activity for ongoing combat session

### v2.0 (Foundation Models)
- Uncomment `FlavorTextService` Foundation Models section when API is public
- Richer procedural monster names, quest descriptions, and battle dialogue

---

*Built with Swift 6, SwiftUI, SwiftData, Vision, PHPhotoLibrary, CoreHaptics.*
*No cloud. No tracking. No excuses.*
