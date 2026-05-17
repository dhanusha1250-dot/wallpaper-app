import SwiftUI

/// Accumulates animation time so changing `speed` never causes a visible jump
/// (unlike reading the wall clock directly). Shared by time-driven scenes.
final class AnimationClock {
    private var last: Date?
    private(set) var time: Double = 0

    @discardableResult
    func tick(_ date: Date, speed: Double, paused: Bool) -> Double {
        defer { last = date }
        guard let last else { return time }
        if paused { return time }
        time += min(date.timeIntervalSince(last), 0.05) * speed
        return time
    }
}

enum Rand {
    static func between(_ a: CGFloat, _ b: CGFloat) -> CGFloat { .random(in: a...b) }
    static func point(in size: CGSize) -> CGPoint {
        CGPoint(x: .random(in: 0...max(size.width, 1)),
                y: .random(in: 0...max(size.height, 1)))
    }
}

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

func smoothPulse(_ x: CGFloat) -> CGFloat {
    // Ease-out curve in 0...1.
    let c = min(max(x, 0), 1)
    return 1 - (1 - c) * (1 - c)
}

extension GraphicsContext {
    /// Renders the recent click ripples shared by most scenes.
    mutating func drawRipples(_ pulses: [InteractionModel.Pulse],
                              now: Date,
                              color: Color,
                              maxRadius: CGFloat = 280,
                              life: Double = 1.7) {
        for pulse in pulses {
            let age = now.timeIntervalSince(pulse.start)
            guard age >= 0, age < life else { continue }
            let t = CGFloat(age / life)
            let radius = maxRadius * smoothPulse(t)
            let alpha = (1 - t) * (1 - t)
            var ring = self
            ring.blendMode = .plusLighter
            let rect = CGRect(x: pulse.point.x - radius,
                              y: pulse.point.y - radius,
                              width: radius * 2,
                              height: radius * 2)
            ring.stroke(Path(ellipseIn: rect),
                        with: .color(color.opacity(Double(alpha) * 0.8)),
                        lineWidth: 1.5 + 4 * (1 - t))
        }
    }
}
