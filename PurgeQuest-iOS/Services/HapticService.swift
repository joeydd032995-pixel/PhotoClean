// Services/HapticService.swift
// Centralized haptic feedback for all combat interactions.

import UIKit
import CoreHaptics

@MainActor
final class HapticService {

    static let shared = HapticService()
    private init() { prepareEngine() }

    private var engine: CHHapticEngine?
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
        engine?.resetHandler = { [weak self] in
            try? self?.engine?.start()
        }
        engine?.stoppedHandler = { _ in }
    }

    // ─── Combat Actions ────────────────────────────────────────────────────────

    func swipeDelete() {
        impact.impactOccurred(intensity: 0.9)
    }

    func swipeKeep() {
        lightImpact.impactOccurred(intensity: 0.6)
    }

    func monsterAttack() {
        playCustomPattern([
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8),
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
            ], relativeTime: 0.12),
        ])
    }

    func comboHit(comboCount: Int) {
        let intensity = min(1.0, 0.5 + Double(comboCount) * 0.05)
        UIImpactFeedbackGenerator(style: .rigid)
            .impactOccurred(intensity: CGFloat(intensity))
    }

    func monsterDeath() {
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.heavyImpact.impactOccurred(intensity: 0.8)
        }
    }

    func levelUp() {
        playCustomPattern([
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.0),
            ], relativeTime: 0, duration: 0.3),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0),
            ], relativeTime: 0.3),
        ])
    }

    func achievementUnlocked() {
        notification.notificationOccurred(.success)
    }

    func bossRoar() {
        playCustomPattern([
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
            ], relativeTime: 0, duration: 0.5),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
            ], relativeTime: 0.55),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
            ], relativeTime: 0.70),
        ])
    }

    func selectionFeedback() {
        selection.selectionChanged()
    }

    func heroDamage() {
        notification.notificationOccurred(.warning)
    }

    func heroDefeated() {
        notification.notificationOccurred(.error)
    }

    // ─── Internal ─────────────────────────────────────────────────────────────

    private func playCustomPattern(_ events: [CHHapticEvent]) {
        guard let engine else {
            impact.impactOccurred()
            return
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            impact.impactOccurred()
        }
    }
}
