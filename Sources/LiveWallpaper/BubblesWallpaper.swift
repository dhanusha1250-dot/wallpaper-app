import SwiftUI

/// Rising soap bubbles. The cursor pushes nearby bubbles aside; a click pops
/// every bubble within reach with a little burst.
struct BubblesWallpaper: View {
    @ObservedObject var model: InteractionModel
    @ObservedObject var settings: AppSettings
    @State private var system = BubbleSystem()

    var body: some View {
        TimelineView(.animation(paused: settings.isPaused)) { timeline in
            Canvas { context, size in
                system.update(date: timeline.date,
                              size: size,
                              cursor: model.cursor,
                              pulses: model.pulses,
                              speed: settings.speed,
                              paused: settings.isPaused)
                system.draw(into: &context, size: size, cursor: model.cursor)
            }
        }
    }
}

final class BubbleSystem {
    private struct Bubble {
        var position: CGPoint
        var velocity: CGVector
        var radius: CGFloat
        var wobble: CGFloat
        var hue: Double
        var poppedAt: Date?
    }

    private var bubbles: [Bubble] = []
    private var lastDate: Date?
    private var size: CGSize = .zero
    private var consumedPulses: Set<UUID> = []

    private func makeBubble(in size: CGSize, atBottom: Bool) -> Bubble {
        let radius = Rand.between(16, 64)
        let y = atBottom ? size.height + radius : Rand.between(0, size.height)
        return Bubble(
            position: CGPoint(x: Rand.between(0, size.width), y: y),
            velocity: CGVector(dx: Rand.between(-12, 12), dy: Rand.between(-55, -22)),
            radius: radius,
            wobble: Rand.between(0, 6.28),
            hue: Double.random(in: 0...1),
            poppedAt: nil)
    }

    private func seed(_ newSize: CGSize) {
        size = newSize
        let count = Int(newSize.width / 26).clamped(to: 14...58)
        bubbles = (0..<count).map { _ in makeBubble(in: newSize, atBottom: false) }
    }

    func update(date: Date, size newSize: CGSize, cursor: CGPoint?,
                pulses: [InteractionModel.Pulse], speed: Double, paused: Bool) {
        if bubbles.isEmpty || abs(newSize.width - size.width) > 1 || abs(newSize.height - size.height) > 1 {
            seed(newSize)
        }
        guard let last = lastDate else { lastDate = date; return }
        lastDate = date
        if paused { return }

        let dt = min(date.timeIntervalSince(last), 0.05)
        let step = CGFloat(dt * speed)

        for pulse in pulses where !consumedPulses.contains(pulse.id) {
            guard date.timeIntervalSince(pulse.start) < 0.25 else { continue }
            consumedPulses.insert(pulse.id)
            for index in bubbles.indices where bubbles[index].poppedAt == nil {
                let dx = bubbles[index].position.x - pulse.point.x
                let dy = bubbles[index].position.y - pulse.point.y
                if sqrt(dx * dx + dy * dy) < 150 {
                    bubbles[index].poppedAt = date
                }
            }
        }
        consumedPulses.formIntersection(pulses.map(\.id))

        for index in bubbles.indices {
            var bubble = bubbles[index]

            if let popped = bubble.poppedAt {
                if date.timeIntervalSince(popped) > 0.35 {
                    bubble = makeBubble(in: newSize, atBottom: true)
                }
                bubbles[index] = bubble
                continue
            }

            if let cursor {
                let dx = bubble.position.x - cursor.x
                let dy = bubble.position.y - cursor.y
                let dist = max(sqrt(dx * dx + dy * dy), 1)
                let reach = bubble.radius + 110
                if dist < reach {
                    let force = (reach - dist) / reach * 240
                    bubble.velocity.dx += dx / dist * force * step
                    bubble.velocity.dy += dy / dist * force * step
                }
            }

            bubble.velocity.dx *= CGFloat(pow(0.9, dt * 60))
            // Buoyancy keeps bubbles rising.
            bubble.velocity.dy += -8 * step
            bubble.velocity.dy = max(bubble.velocity.dy, -90)

            bubble.wobble += step * 2.5
            bubble.position.x += (bubble.velocity.dx + sin(bubble.wobble) * 14) * step
            bubble.position.y += bubble.velocity.dy * step

            if bubble.position.y < -bubble.radius * 2 {
                bubble = makeBubble(in: newSize, atBottom: true)
            }
            if bubble.position.x < -bubble.radius { bubble.position.x = newSize.width + bubble.radius }
            if bubble.position.x > newSize.width + bubble.radius { bubble.position.x = -bubble.radius }

            bubbles[index] = bubble
        }
    }

    func draw(into context: inout GraphicsContext, size: CGSize, cursor: CGPoint?) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.03, green: 0.10, blue: 0.22),
                    Color(red: 0.05, green: 0.18, blue: 0.32),
                    Color(red: 0.02, green: 0.06, blue: 0.14)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)))

        let now = Date()
        var glow = context
        glow.blendMode = .plusLighter

        for bubble in bubbles {
            let tint = Color(hue: bubble.hue, saturation: 0.5, brightness: 1.0)

            if let popped = bubble.poppedAt {
                // Pop burst.
                let t = CGFloat(now.timeIntervalSince(popped) / 0.35).clamped(to: 0...1)
                let r = bubble.radius * (1 + t * 1.4)
                glow.stroke(
                    Path(ellipseIn: CGRect(x: bubble.position.x - r, y: bubble.position.y - r,
                                           width: r * 2, height: r * 2)),
                    with: .color(tint.opacity(Double(1 - t) * 0.7)),
                    lineWidth: 2)
                continue
            }

            let r = bubble.radius
            let rect = CGRect(x: bubble.position.x - r, y: bubble.position.y - r,
                              width: r * 2, height: r * 2)
            // Soft body.
            glow.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [tint.opacity(0.05), tint.opacity(0.22), .clear]),
                    center: bubble.position, startRadius: 0, endRadius: r))
            // Rim.
            context.stroke(Path(ellipseIn: rect),
                           with: .color(tint.opacity(0.6)), lineWidth: 1.3)
            // Specular highlight.
            let hl = CGRect(x: bubble.position.x - r * 0.45,
                            y: bubble.position.y - r * 0.55,
                            width: r * 0.5, height: r * 0.5)
            glow.fill(Path(ellipseIn: hl), with: .color(.white.opacity(0.55)))
        }

        if let cursor {
            let r: CGFloat = 90
            glow.fill(
                Path(ellipseIn: CGRect(x: cursor.x - r, y: cursor.y - r,
                                       width: r * 2, height: r * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.18), .clear]),
                    center: cursor, startRadius: 0, endRadius: r))
        }
    }
}
