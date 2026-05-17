import SwiftUI

/// Parallax starfield. The cursor acts as a gravity well that pulls nearby
/// stars; a click sends out a shockwave that scatters them.
struct StarfieldWallpaper: View {
    @ObservedObject var model: InteractionModel
    @ObservedObject var settings: AppSettings
    @State private var system = StarfieldSystem()

    var body: some View {
        TimelineView(.animation(paused: settings.isPaused)) { timeline in
            Canvas { context, size in
                system.update(date: timeline.date,
                              size: size,
                              cursor: model.cursor,
                              pulses: model.pulses,
                              speed: settings.speed,
                              paused: settings.isPaused)
                system.draw(into: &context, size: size,
                            cursor: model.cursor,
                            pulses: model.pulses,
                            now: timeline.date)
            }
        }
    }
}

final class StarfieldSystem {
    private struct Star {
        var position: CGPoint
        var velocity: CGVector
        var depth: CGFloat      // 0.2 (far) ... 1.0 (near)
        var radius: CGFloat
        var twinkle: CGFloat
    }

    private var stars: [Star] = []
    private var lastDate: Date?
    private var size: CGSize = .zero
    private var consumedPulses: Set<UUID> = []

    private func seed(_ newSize: CGSize) {
        size = newSize
        let count = Int((newSize.width * newSize.height) / 9000).clamped(to: 90...320)
        stars = (0..<count).map { _ in
            let depth = Rand.between(0.2, 1.0)
            return Star(
                position: Rand.point(in: newSize),
                velocity: CGVector(dx: Rand.between(-6, 6), dy: Rand.between(-6, 6)),
                depth: depth,
                radius: depth * 1.8 + 0.4,
                twinkle: Rand.between(0, 6.28))
        }
    }

    func update(date: Date, size newSize: CGSize, cursor: CGPoint?,
                pulses: [InteractionModel.Pulse], speed: Double, paused: Bool) {
        if stars.isEmpty || abs(newSize.width - size.width) > 1 || abs(newSize.height - size.height) > 1 {
            seed(newSize)
        }
        guard let last = lastDate else { lastDate = date; return }
        lastDate = date
        if paused { return }

        let dt = min(date.timeIntervalSince(last), 0.05)
        let step = CGFloat(dt * speed)
        let damping = CGFloat(pow(0.86, dt * 60 * speed))

        for pulse in pulses where !consumedPulses.contains(pulse.id) {
            guard date.timeIntervalSince(pulse.start) < 0.25 else { continue }
            consumedPulses.insert(pulse.id)
            applyShockwave(at: pulse.point)
        }
        consumedPulses.formIntersection(pulses.map(\.id))

        for index in stars.indices {
            var star = stars[index]

            if let cursor {
                let dx = cursor.x - star.position.x
                let dy = cursor.y - star.position.y
                let dist = max(sqrt(dx * dx + dy * dy), 1)
                if dist < 280 {
                    let force = (280 - dist) / 280 * 130 * star.depth
                    star.velocity.dx += dx / dist * force * step
                    star.velocity.dy += dy / dist * force * step
                }
            }

            star.velocity.dx *= damping
            star.velocity.dy *= damping

            let drift = CGFloat(8 + star.depth * 14)
            star.position.x += (star.velocity.dx + drift * 0.15) * step
            star.position.y += star.velocity.dy * step
            star.position = wrap(star.position, in: newSize)
            star.twinkle += step * 2.2

            stars[index] = star
        }
    }

    private func applyShockwave(at point: CGPoint) {
        for index in stars.indices {
            let dx = stars[index].position.x - point.x
            let dy = stars[index].position.y - point.y
            let dist = max(sqrt(dx * dx + dy * dy), 1)
            guard dist < 420 else { continue }
            let force = (420 - dist) / 420 * 620
            stars[index].velocity.dx += dx / dist * force
            stars[index].velocity.dy += dy / dist * force
        }
    }

    private func wrap(_ point: CGPoint, in size: CGSize) -> CGPoint {
        var p = point
        if p.x < -10 { p.x += size.width + 20 }
        if p.x > size.width + 10 { p.x -= size.width + 20 }
        if p.y < -10 { p.y += size.height + 20 }
        if p.y > size.height + 10 { p.y -= size.height + 20 }
        return p
    }

    func draw(into context: inout GraphicsContext, size: CGSize,
              cursor: CGPoint?, pulses: [InteractionModel.Pulse], now: Date) {
        // Deep-space background.
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.04, green: 0.03, blue: 0.10),
                    Color(red: 0.10, green: 0.05, blue: 0.20),
                    Color(red: 0.02, green: 0.02, blue: 0.06)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)))

        // Soft nebula glow following the cursor.
        if let cursor {
            context.fill(
                Path(ellipseIn: CGRect(x: cursor.x - 240, y: cursor.y - 240,
                                       width: 480, height: 480)),
                with: .radialGradient(
                    Gradient(colors: [Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.22),
                                      .clear]),
                    center: cursor, startRadius: 0, endRadius: 240))
        }

        var glow = context
        glow.blendMode = .plusLighter
        for star in stars {
            let brightness = 0.55 + 0.45 * sin(star.twinkle)
            let alpha = Double(star.depth * brightness)
            let r = star.radius
            glow.fill(
                Path(ellipseIn: CGRect(x: star.position.x - r, y: star.position.y - r,
                                       width: r * 2, height: r * 2)),
                with: .color(Color.white.opacity(alpha)))

            // Connect the brightest near-cursor stars with faint lines.
            if let cursor {
                let dx = cursor.x - star.position.x
                let dy = cursor.y - star.position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < 150 {
                    var line = Path()
                    line.move(to: star.position)
                    line.addLine(to: cursor)
                    glow.stroke(line,
                                with: .color(Color(red: 0.6, green: 0.5, blue: 1.0)
                                    .opacity(Double((150 - dist) / 150) * 0.25)),
                                lineWidth: 0.6)
                }
            }
        }

        context.drawRipples(pulses, now: now,
                            color: Color(red: 0.7, green: 0.6, blue: 1.0),
                            maxRadius: 420, life: 1.4)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
