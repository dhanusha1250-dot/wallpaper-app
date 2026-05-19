import SwiftUI

/// A lava-lamp of glowing metaball blobs. The cursor gently attracts blobs
/// within range; each click spawns a fresh blob.
struct FluidWallpaper: View {
    @ObservedObject var model: InteractionModel
    @ObservedObject var settings: AppSettings
    @State private var system = FluidSystem()

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
                            pulses: model.pulses,
                            now: timeline.date)
            }
        }
    }
}

final class FluidSystem {
    private struct Blob {
        var position: CGPoint
        var velocity: CGVector
        var radius: CGFloat
        var color: Color
    }

    private static let palette: [Color] = [
        Color(red: 1.00, green: 0.45, blue: 0.25),
        Color(red: 1.00, green: 0.30, blue: 0.55),
        Color(red: 1.00, green: 0.72, blue: 0.20),
        Color(red: 0.85, green: 0.25, blue: 0.85),
        Color(red: 1.00, green: 0.55, blue: 0.10)
    ]

    private var blobs: [Blob] = []
    private var lastDate: Date?
    private var size: CGSize = .zero
    private var consumedPulses: Set<UUID> = []

    private func makeBlob(in size: CGSize, at point: CGPoint? = nil) -> Blob {
        Blob(position: point ?? Rand.point(in: size),
             velocity: CGVector(dx: Rand.between(-30, 30), dy: Rand.between(-30, 30)),
             radius: Rand.between(80, 190),
             color: Self.palette.randomElement() ?? .orange)
    }

    private func seed(_ newSize: CGSize) {
        size = newSize
        blobs = (0..<7).map { _ in makeBlob(in: newSize) }
    }

    func update(date: Date, size newSize: CGSize, cursor: CGPoint?,
                pulses: [InteractionModel.Pulse], speed: Double, paused: Bool) {
        if blobs.isEmpty || abs(newSize.width - size.width) > 1 || abs(newSize.height - size.height) > 1 {
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
            if blobs.count < 16 {
                blobs.append(makeBlob(in: newSize, at: pulse.point))
            }
        }
        consumedPulses.formIntersection(pulses.map(\.id))

        for index in blobs.indices {
            var blob = blobs[index]

            if let cursor {
                let dx = cursor.x - blob.position.x
                let dy = cursor.y - blob.position.y
                let dist = max(sqrt(dx * dx + dy * dy), 1)
                if dist < 360 {
                    let force = (360 - dist) / 360 * 90
                    blob.velocity.dx += dx / dist * force * step
                    blob.velocity.dy += dy / dist * force * step
                }
            }

            // Gentle damping keeps motion lava-slow.
            blob.velocity.dx *= CGFloat(pow(0.92, dt * 60))
            blob.velocity.dy *= CGFloat(pow(0.92, dt * 60))

            blob.position.x += blob.velocity.dx * step
            blob.position.y += blob.velocity.dy * step

            // Bounce off edges.
            if blob.position.x < 0 { blob.position.x = 0; blob.velocity.dx = abs(blob.velocity.dx) }
            if blob.position.x > newSize.width { blob.position.x = newSize.width; blob.velocity.dx = -abs(blob.velocity.dx) }
            if blob.position.y < 0 { blob.position.y = 0; blob.velocity.dy = abs(blob.velocity.dy) }
            if blob.position.y > newSize.height { blob.position.y = newSize.height; blob.velocity.dy = -abs(blob.velocity.dy) }

            blobs[index] = blob
        }
    }

    func draw(into context: inout GraphicsContext, size: CGSize,
              pulses: [InteractionModel.Pulse], now: Date) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.12, green: 0.02, blue: 0.10),
                    Color(red: 0.20, green: 0.04, blue: 0.04),
                    Color(red: 0.05, green: 0.01, blue: 0.03)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)))

        // Additive radial gradients fake a metaball merge.
        var field = context
        field.blendMode = .plusLighter
        for blob in blobs {
            let rect = CGRect(x: blob.position.x - blob.radius,
                              y: blob.position.y - blob.radius,
                              width: blob.radius * 2,
                              height: blob.radius * 2)
            field.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [blob.color.opacity(0.85),
                                      blob.color.opacity(0.25),
                                      .clear]),
                    center: blob.position,
                    startRadius: 0,
                    endRadius: blob.radius))
        }

        context.drawRipples(pulses, now: now,
                            color: Color(red: 1.0, green: 0.7, blue: 0.4),
                            maxRadius: 300, life: 1.5)
    }
}
