// Views/Combat/ParticleEffects.swift
// SwiftUI-native particle effects: one-shot burst for hits/death, looping confetti for level-up.
// Uses TimelineView + Canvas — no external dependencies, GPU-accelerated.

import SwiftUI

// ─── Particle Burst ───────────────────────────────────────────────────────────
// One-shot radial burst. Particles fly outward with gravity, fade out, then stop.

private struct ParticleSpec {
    let angle: Double       // radians
    let speed: CGFloat      // pts/s
    let color: Color
    let radius: CGFloat
}

struct ParticleBurstView: View {
    let color: Color
    var count: Int = 14
    var duration: Double = 0.55     // seconds until animation stops

    @State private var start = Date()
    @State private var running = true

    private let specs: [ParticleSpec]

    init(color: Color, count: Int = 14, duration: Double = 0.55) {
        self.color = color
        self.count = count
        self.duration = duration

        // Build particle specs at init time — deterministic, no random state mutation during render
        var s: [ParticleSpec] = []
        for i in 0..<count {
            let baseAngle = Double(i) / Double(count) * 2 * .pi
            let jitter = Double.random(in: -0.25...0.25)
            let speed = CGFloat.random(in: 60...160)
            // Alternate between pure color and a lighter tint for visual variety
            let useLight = i % 3 == 0
            let pc = useLight ? color.opacity(0.6) : color
            let radius = CGFloat.random(in: 4...9)
            s.append(ParticleSpec(angle: baseAngle + jitter, speed: speed, color: pc, radius: radius))
        }
        self.specs = s
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !running)) { tl in
            Canvas { ctx, size in
                let t = CGFloat(tl.date.timeIntervalSince(start))
                guard t >= 0 else { return }
                let progress = min(t / CGFloat(duration), 1)
                let cx = size.width / 2
                let cy = size.height / 2

                for spec in specs {
                    let x = cx + CGFloat(cos(spec.angle)) * spec.speed * t
                    let y = cy + CGFloat(sin(spec.angle)) * spec.speed * t + 180 * t * t   // gravity
                    let fade = pow(Double(1 - progress), 1.8)
                    let r = max(0.5, spec.radius * (1 - progress * 0.4))
                    ctx.opacity = fade
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(spec.color)
                    )
                }
            }
            .onChange(of: tl.date) { _, _ in
                if tl.date.timeIntervalSince(start) > duration { running = false }
            }
        }
        .allowsHitTesting(false)
        .onAppear { start = Date() }
    }
}

// ─── Confetti View ────────────────────────────────────────────────────────────
// Looping downward-falling confetti rectangles in 5 dungeon-themed colours.
// Designed for the level-up sheet — runs until removed from the view hierarchy.

private struct ConfettiPiece {
    let x0: CGFloat           // 0–1 fraction of view width
    let delay: Double         // start delay in seconds (staggers pieces)
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let rotSpeed: Double      // radians/s
    let fallSpeed: CGFloat    // pts/s
}

struct ConfettiView: View {
    @State private var start = Date()

    private let pieces: [ConfettiPiece]

    private static let palette: [Color] = [
        Color(hex: "#F7C948"),   // gold
        Color(hex: "#E84545"),   // red
        Color(hex: "#4CAF50"),   // green
        Color(hex: "#00BCD4"),   // cyan
        Color(hex: "#A78BFA"),   // purple
    ]

    init(count: Int = 42) {
        var p: [ConfettiPiece] = []
        for i in 0..<count {
            p.append(ConfettiPiece(
                x0: CGFloat(i) / CGFloat(count) + CGFloat.random(in: -0.02...0.02),
                delay: Double.random(in: 0...2.0),
                color: Self.palette[i % Self.palette.count],
                width: CGFloat.random(in: 7...13),
                height: CGFloat.random(in: 5...9),
                rotSpeed: Double.random(in: 1.5...4.0) * (Bool.random() ? 1 : -1),
                fallSpeed: CGFloat.random(in: 130...220)
            ))
        }
        self.pieces = p
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
            Canvas { ctx, size in
                let now = tl.date.timeIntervalSince(start)
                for piece in pieces {
                    let elapsed = max(0, now - piece.delay)
                    guard elapsed > 0 else { continue }

                    let cycleTime = Double(size.height + piece.height) / Double(piece.fallSpeed)
                    let phase = elapsed.truncatingRemainder(dividingBy: cycleTime)
                    let y = CGFloat(phase) * piece.fallSpeed - piece.height
                    let x = piece.x0 * size.width + CGFloat(sin(elapsed * 1.8)) * 18

                    let angle = CGFloat(elapsed * piece.rotSpeed)
                    let fadeIn = min(1.0, elapsed * 4)

                    ctx.opacity = fadeIn
                    ctx.withCGContext { cg in
                        cg.translateBy(x: x, y: y)
                        cg.rotate(by: angle)
                        cg.setFillColor(UIColor(piece.color).cgColor)
                        cg.fill(CGRect(
                            x: -piece.width / 2, y: -piece.height / 2,
                            width: piece.width, height: piece.height
                        ))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { start = Date() }
    }
}
