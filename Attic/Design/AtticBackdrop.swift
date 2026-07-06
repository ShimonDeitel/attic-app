import SwiftUI
import CoreMotion

// MARK: - Device tilt (parallax)

/// Smoothed device tilt for parallax, roughly -1...1 per axis.
/// Gracefully inert in the simulator (no device motion available).
@Observable
final class MotionTilt {
    private(set) var x: Double = 0
    private(set) var y: Double = 0

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let targetX = max(-1, min(1, motion.attitude.roll / (.pi / 4)))
            let targetY = max(-1, min(1, motion.attitude.pitch / (.pi / 4)))
            // Low-pass so the light sways rather than jitters.
            self.x += (targetX - self.x) * 0.08
            self.y += (targetY - self.y) * 0.08
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

// MARK: - Backdrop

/// The shared attic ambience: dark beam-brown depths, one warm shaft of
/// light from an unseen roof window, and dust motes drifting through it.
/// Alive even at rest; device tilt parallaxes the shaft and motes.
struct AtticBackdrop: View {
    /// 0...1 — secondary screens run the ambience dimmer.
    var intensity: Double = 1

    @State private var tilt = MotionTilt()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AtticTheme.wood, AtticTheme.night],
                startPoint: .top, endPoint: .bottom
            )

            ShaftShape()
                .fill(
                    LinearGradient(
                        colors: [AtticTheme.candle.opacity(0.5), AtticTheme.candle.opacity(0)],
                        startPoint: .topTrailing, endPoint: .bottomLeading
                    )
                )
                .blur(radius: 38)
                .opacity(0.5 * intensity)
                .blendMode(.plusLighter)
                .offset(x: tilt.x * 14, y: tilt.y * 8)

            DustMotesCanvas(intensity: intensity)
                .blendMode(.plusLighter)
                .offset(x: tilt.x * 26, y: tilt.y * 16)

            RadialGradient(
                colors: [.clear, AtticTheme.night.opacity(0.55)],
                center: .center, startRadius: 150, endRadius: 520
            )
        }
        .ignoresSafeArea()
        .onAppear { tilt.start() }
        .onDisappear { tilt.stop() }
    }
}

/// Diagonal parallelogram of light falling from the top-right.
struct ShaftShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX * 0.55, y: rect.minY - 40))
        p.addLine(to: CGPoint(x: rect.maxX + 40, y: rect.minY - 40))
        p.addLine(to: CGPoint(x: rect.maxX * 0.62, y: rect.maxY * 0.92))
        p.addLine(to: CGPoint(x: rect.maxX * 0.12, y: rect.maxY * 0.78))
        p.closeSubpath()
        return p
    }
}

// MARK: - Dust motes

/// Deterministic drifting dust field. Each mote's path is a pure function of
/// (index, time), so the field is stable across view reloads and costs no
/// state. Motes glow brighter while inside the light shaft.
struct DustMotesCanvas: View {
    var intensity: Double

    private static let moteCount = 44

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }
                for index in 0..<Self.moteCount {
                    let mote = Mote(index: index)
                    let position = mote.position(at: t, in: size)
                    let alpha = mote.opacity(at: t, position: position, in: size) * intensity
                    guard alpha > 0.02 else { continue }
                    let rect = CGRect(
                        x: position.x - mote.radius, y: position.y - mote.radius,
                        width: mote.radius * 2, height: mote.radius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(AtticTheme.candle.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct Mote {
    let seedA: Double
    let seedB: Double
    let radius: CGFloat
    let riseSpeed: Double
    let wanderAmp: Double

    init(index: Int) {
        func hash(_ n: Double) -> Double {
            let s = sin(n) * 43758.5453
            return s - s.rounded(.down)
        }
        let base = Double(index) * 12.9898
        seedA = hash(base)
        seedB = hash(base + 78.233)
        radius = 0.8 + CGFloat(hash(base + 3.7)) * 2.3
        riseSpeed = 4 + hash(base + 9.1) * 10
        wanderAmp = 8 + hash(base + 5.5) * 14
    }

    private func pmod(_ a: Double, _ n: Double) -> Double {
        let r = a.truncatingRemainder(dividingBy: n)
        return r < 0 ? r + n : r
    }

    func position(at t: Double, in size: CGSize) -> CGPoint {
        let h = Double(size.height) + 40
        let w = Double(size.width)
        let y = pmod(seedB * h - t * riseSpeed, h) - 20
        let x = pmod(seedA * w + sin(t * 0.3 + seedA * .pi * 2) * wanderAmp, w)
        return CGPoint(x: x, y: y)
    }

    func opacity(at t: Double, position: CGPoint, in size: CGSize) -> Double {
        // Shaft center line runs from ~0.77w at the top to ~0.37w at the bottom.
        let progress = position.y / max(size.height, 1)
        let shaftCenterX = size.width * (0.77 - 0.4 * progress)
        let distance = abs(position.x - shaftCenterX)
        let band = size.width * 0.28
        let shaftBoost = max(0, 1 - distance / band)
        let twinkle = 0.5 + 0.5 * sin(t * (0.8 + seedA) + seedB * .pi * 2)
        return (0.08 + 0.55 * shaftBoost) * (0.35 + 0.65 * twinkle)
    }
}
