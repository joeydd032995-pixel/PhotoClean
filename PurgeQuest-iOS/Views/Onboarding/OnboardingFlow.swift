// Views/Onboarding/OnboardingFlow.swift
// Fun tutorial dungeon + permission request onboarding.

import SwiftUI
import Photos

struct OnboardingFlow: View {
    let onComplete: () -> Void
    @State private var page = 0
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Deep dungeon background
            LinearGradient(
                colors: [Color(hex: "#0A0A1A"), Color(hex: "#1A0A2E"), Color(hex: "#0D1B0A")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Particle-like stars
            StarsBackground()

            TabView(selection: $page) {
                OnboardingPage1().tag(0)
                OnboardingPage2().tag(1)
                OnboardingPage3().tag(2)
                OnboardingPermissionPage(onComplete: onComplete).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: page)
        }
        .preferredColorScheme(.dark)
    }
}

// ─── Page 1: The Hook ─────────────────────────────────────────────────────────

struct OnboardingPage1: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Hero Icon
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: "#F7C948").opacity(0.3), .clear],
                                        center: .center, startRadius: 0, endRadius: 100))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animate ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)

                Text("⚔️")
                    .font(.system(size: 90))
                    .shadow(color: Color(hex: "#F7C948"), radius: animate ? 20 : 5)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }

            VStack(spacing: 16) {
                Text("Your Camera Roll")
                    .font(.custom("Georgia", size: 16))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(4)

                Text("Is a Dungeon.")
                    .font(.custom("Georgia Bold", size: 42))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "#F7C948"), Color(hex: "#E8A020")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .multilineTextAlignment(.center)

                Text("7,342 photos. 12 GB of clutter.\nBlurry Beasts. Duplicate Dragons.\nScreenshot Specters.")
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 32)

            Spacer()

            OnboardingNextHint()
        }
        .onAppear { animate = true }
    }
}

// ─── Page 2: The Game Loop ────────────────────────────────────────────────────

struct OnboardingPage2: View {
    @State private var step = 0

    let steps: [(icon: String, title: String, detail: String)] = [
        ("👈", "Swipe Left: Attack", "Delete the photo. Deal damage. Earn XP."),
        ("👉", "Swipe Right: Spare", "Keep the photo. The monster fights back."),
        ("🐉", "Monsters = Clutter Types", "Blurry, duplicate, old, dark. Each has a boss."),
        ("💎", "Earn Storage Gems", "Real GB freed = real in-game rewards."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("How to Play")
                .font(.custom("Georgia Bold", size: 34))
                .foregroundStyle(Color(hex: "#F7C948"))
                .padding(.bottom, 40)

            VStack(spacing: 20) {
                ForEach(Array(steps.enumerated()), id: \.0) { i, s in
                    HStack(spacing: 20) {
                        Text(s.icon)
                            .font(.system(size: 36))
                            .frame(width: 60)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(s.title)
                                .font(.custom("Georgia Bold", size: 18))
                                .foregroundStyle(.white)
                            Text(s.detail)
                                .font(.custom("Georgia", size: 15))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .opacity(step > i ? 1 : 0.2)
                    .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.15), value: step)
                }
            }

            Spacer()
            OnboardingNextHint()
        }
        .onAppear {
            for i in 0...3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2 + 0.3) {
                    step = i + 1
                }
            }
        }
    }
}

// ─── Page 3: Privacy Pledge ───────────────────────────────────────────────────

struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("🔒")
                .font(.system(size: 80))

            VStack(spacing: 16) {
                Text("Your Privacy, Guaranteed")
                    .font(.custom("Georgia Bold", size: 28))
                    .foregroundStyle(Color(hex: "#F7C948"))
                    .multilineTextAlignment(.center)

                Text("PurgeQuest is 100% on-device.\nZero photos leave your iPhone.\nNo cloud. No accounts. No tracking.")
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 14) {
                PrivacyFeatureRow(icon: "iphone", text: "All processing on your device")
                PrivacyFeatureRow(icon: "wifi.slash", text: "No internet connection ever used")
                PrivacyFeatureRow(icon: "trash.circle", text: "You confirm every deletion")
                PrivacyFeatureRow(icon: "arrow.uturn.backward.circle", text: "7-day undo window for all deletes")
            }
            .padding(.horizontal, 24)

            Spacer()
            OnboardingNextHint()
        }
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(hex: "#4CAF50"))
                .frame(width: 30)
            Text(text)
                .font(.custom("Georgia", size: 16))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// ─── Page 4: Permission Request ───────────────────────────────────────────────

struct OnboardingPermissionPage: View {
    let onComplete: () -> Void
    @State private var isRequesting = false
    @State private var denied = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("📸")
                .font(.system(size: 80))

            VStack(spacing: 12) {
                Text("One Last Thing")
                    .font(.custom("Georgia Bold", size: 30))
                    .foregroundStyle(Color(hex: "#F7C948"))

                Text("PurgeQuest needs read access to your photo library to find the monsters hiding inside it.")
                    .font(.custom("Georgia", size: 17))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
            }

            if denied {
                VStack(spacing: 8) {
                    Text("Access Denied")
                        .font(.custom("Georgia Bold", size: 16))
                        .foregroundStyle(Color(hex: "#E84545"))
                    Text("Go to Settings → PurgeQuest → Photos to grant access.")
                        .font(.custom("Georgia", size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.custom("Georgia Bold", size: 15))
                    .foregroundStyle(Color(hex: "#F7C948"))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
            }

            Button {
                Task { await requestPermission() }
            } label: {
                HStack(spacing: 12) {
                    if isRequesting {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "shield.fill")
                    }
                    Text(isRequesting ? "Requesting..." : "Grant Photo Access")
                }
                .font(.custom("Georgia Bold", size: 18))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [Color(hex: "#F7C948"), Color(hex: "#E8A020")],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "#F7C948").opacity(0.4), radius: 12, y: 4)
            }
            .padding(.horizontal, 32)
            .disabled(isRequesting)

            Spacer()
        }
    }

    private func requestPermission() async {
        isRequesting = true
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        isRequesting = false
        switch status {
        case .authorized, .limited:
            onComplete()
        case .denied, .restricted:
            denied = true
        default:
            break
        }
    }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

struct OnboardingNextHint: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "chevron.right.2")
                .foregroundStyle(.white.opacity(0.4))
                .font(.caption)
            Text("Swipe to continue")
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.bottom, 50)
    }
}

struct StarsBackground: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<60, id: \.self) { i in
                let x = Double(i * 137 % Int(geo.size.width))
                let y = Double(i * 197 % Int(geo.size.height))
                let size = Double(i % 3) + 1.0
                Circle()
                    .fill(.white.opacity(Double(i % 5) * 0.06 + 0.03))
                    .frame(width: size, height: size)
                    .position(x: x, y: y)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// ─── Color Hex Extension ──────────────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255,
                  opacity: Double(a)/255)
    }
}
