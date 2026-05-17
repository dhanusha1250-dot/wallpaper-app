import SwiftUI

/// Soft, slowly morphing gradient orbs — a calm "gradient mesh" look. The
/// cursor drags the nearest orb; clicks send a ripple.
struct OrbsWallpaper: View {
    @ObservedObject var model: InteractionModel
    @ObservedObject var settings: AppSettings
    @State private var system = OrbSystem()

    var body: some View {
        TimelineView(.animation(paused: settings.isPaused)) { timeline in
            Canvas { context, size in
                system.update(date: timeline.date,
                              size: size,
                              cursor: model.cursor,
                              cursorActive: model.cursorActive,
                              speed: settings.speed,
                              paused: settings.isPaused)
                system.draw(into: &context, size: size,
                            pulses: model.pulses, now: timeline.date)
            }
        }
    }
}

final class OrbSystem {
    private struct Orb {
        var home: CGPoint
        var position: CGPoint
        var radius: CGFloat
        var color: Color
        var phaseX: CGFloat
        var phaseY: CGFloat
        var driftX: CGFloat
        var driftY: CGFloat
    }

    private static let palette: [Color] = [
        Color(red: 0.30, green: 0.85, blue: 0.95),
        Color(red: 0.55, green: 0.45, blue: 1.00),
        Color(red: 1.00, green: 0.55, blue: 0.80),
        Color(red: 0.40, green: 0.95, blue: 0.70),
        Color(red: 1.00, green: 0.80, blue: 0.45),
        Color(red: 0.50, green: 0.70, blue: 1.00)
    ]

    private var orbs: [Orb] = []
    private var lastDate: Date?
    private var size: CGSize = .zero
    private var time: Double = 0
    private var draggedIndex: Int?

    private func seed(_ newSize: CGSize) {
        size = newSize
        orbs = (0..<6).enumerated().map { index, _ in
            let home = CGPoint(x: Rand.between(0.15, 0.85) * newSize.width,
                               y: Rand.between(0.15, 0.85) * newSize.height)
            return Orb(
                home: home,
                position: home,
                radius: Rand.between(0.28, 0.5) * min(newSize.width, newSize.height),
                color: Self.palette[index % Self.palette.count],
                phaseX: Rand.between(0, 6.28),
                phaseY: Rand.between(0, 6.28),
                driftX: Rand.between(60, 150),
                driftY: Rand.between(60, 150))
        }
    }

    func update(date: Date, size newSize: CGSize, cursor: CGPoint?,
                cursorActive: Bool, speed: Double, paused: Bool) {
        if orbs.isEmpty || abs(newSize.width - size.width) > 1 || abs(newSize.height - size.height) > 1 {
            seed(newSize)
        }
        guard let last = lastDate else { lastDate = date; return }
        lastDate = date
        if paused { return }

        let dt = min(date.timeIntervalSince(last), 0.05)
        time += dt * speed
        let step = CGFloat(dt * speed)

        // Pick the orb nearest the cursor to "drag".
        if cursorActive, let cursor {
            if draggedIndex == nil {
                draggedIndex = orbs.indices.min { a, b in
                    distance(orbs[a].position, cursor) < distance(orbs[b].position, cursor)
                }
            }
        } else {
            draggedIndex = nil
        }

        for index in orbs.indices {
            var orb = orbs[index]
            let target: CGPoint
            if index == draggedIndex, let cursor {
                target = cursor
            } else {
                target = CGPoint(
                    x: orb.home.x + sin(time * 0.35 + Double(orb.phaseX)) * Double(orb.driftX),
                    y: orb.home.y + cos(time * 0.27 + Double(orb.phaseY)) * Double(orb.driftY))
            }
            // Ease toward the target.
            let ease = min(step * 3.0, 1)
            orb.position.x += (target.x - orb.position.x) * ease
            orb.position.y += (target.y - orb.position.y) * ease
            orbs[index] = orb
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x, dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }

    func draw(into context: inout GraphicsContext, size: CGSize,
              pulses: [InteractionModel.Pulse], now: Date) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.13),
                    Color(red: 0.10, green: 0.09, blue: 0.18)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)))

        var field = context
        field.blendMode = .plusLighter
        field.addFilter(.blur(radius: 40))
        for orb in orbs {
            let rect = CGRect(x: orb.position.x - orb.radius,
                              y: orb.position.y - orb.radius,
                              width: orb.radius * 2,
                              height: orb.radius * 2)
            field.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [orb.color.opacity(0.55),
                                      orb.color.opacity(0.18),
                                      .clear]),
                    center: orb.position,
                    startRadius: 0,
                    endRadius: orb.radius))
        }

        context.drawRipples(pulses, now: now,
                            color: .white, maxRadius: 360, life: 1.8)
    }
}
