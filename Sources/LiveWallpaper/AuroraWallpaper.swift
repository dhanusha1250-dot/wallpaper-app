import SwiftUI

/// Flowing aurora curtains. The cursor warps the curtains toward it; clicks
/// send a bright ripple across the sky.
struct AuroraWallpaper: View {
    @ObservedObject var model: InteractionModel
    @ObservedObject var settings: AppSettings
    @State private var clock = AnimationClock()

    var body: some View {
        TimelineView(.animation(paused: settings.isPaused)) { timeline in
            Canvas { context, size in
                let t = clock.tick(timeline.date, speed: settings.speed, paused: settings.isPaused)
                draw(into: &context, size: size, time: t,
                     cursor: model.cursor, pulses: model.pulses, now: timeline.date)
            }
        }
    }

    private let bands: [(hue: Color, offset: CGFloat, amp: CGFloat, speed: CGFloat)] = [
        (Color(red: 0.20, green: 0.95, blue: 0.65), 0.30, 70, 0.55),
        (Color(red: 0.30, green: 0.70, blue: 1.00), 0.42, 90, 0.40),
        (Color(red: 0.65, green: 0.40, blue: 1.00), 0.54, 110, 0.30),
        (Color(red: 0.95, green: 0.45, blue: 0.85), 0.66, 80, 0.48)
    ]

    private func draw(into context: inout GraphicsContext, size: CGSize, time: Double,
                      cursor: CGPoint?, pulses: [InteractionModel.Pulse], now: Date) {
        // Night sky.
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.10),
                    Color(red: 0.05, green: 0.08, blue: 0.20),
                    Color(red: 0.01, green: 0.02, blue: 0.05)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)))

        // Static background stars (hash-based so they don't flicker between frames).
        var starLayer = context
        starLayer.blendMode = .plusLighter
        for i in 0..<70 {
            let x = CGFloat((i * 73) % 100) / 100 * size.width
            let y = CGFloat((i * 37) % 100) / 100 * size.height * 0.6
            let twinkle = 0.4 + 0.4 * sin(time * 1.5 + Double(i))
            starLayer.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)),
                with: .color(.white.opacity(twinkle)))
        }

        var sky = context
        sky.blendMode = .plusLighter

        let pulseBoost = pulseBrightness(pulses: pulses, now: now)
        let stepX: CGFloat = 12

        for (index, band) in bands.enumerated() {
            let baseY = size.height * band.offset

            var topPoints: [CGPoint] = []
            var x: CGFloat = -stepX
            while x <= size.width + stepX {
                let phase = Double(x) * 0.006 + time * Double(band.speed) + Double(index)
                let wave = sin(phase) * Double(band.amp)
                    + sin(phase * 2.3 + 1) * Double(band.amp) * 0.35
                var y = baseY + CGFloat(wave)
                y += curtainWarp(x: x, cursor: cursor, strength: 120)
                topPoints.append(CGPoint(x: x, y: y))
                x += stepX
            }
            guard let first = topPoints.first, let last = topPoints.last else { continue }

            let tailHeight: CGFloat = 220 + band.amp
            var shape = Path()
            shape.move(to: first)
            for p in topPoints { shape.addLine(to: p) }
            shape.addLine(to: CGPoint(x: last.x, y: last.y + tailHeight))
            for p in topPoints.reversed() {
                shape.addLine(to: CGPoint(x: p.x, y: p.y + tailHeight))
            }
            shape.closeSubpath()

            sky.fill(
                shape,
                with: .linearGradient(
                    Gradient(colors: [
                        band.hue.opacity(0.55 + pulseBoost),
                        band.hue.opacity(0.10),
                        .clear
                    ]),
                    startPoint: CGPoint(x: 0, y: baseY - band.amp),
                    endPoint: CGPoint(x: 0, y: baseY + tailHeight)))
        }

        context.drawRipples(pulses, now: now,
                            color: Color(red: 0.5, green: 1.0, blue: 0.8),
                            maxRadius: size.width * 0.6, life: 2.0)
    }

    private func curtainWarp(x: CGFloat, cursor: CGPoint?, strength: CGFloat) -> CGFloat {
        guard let cursor else { return 0 }
        let dx = x - cursor.x
        let sigma: CGFloat = 180
        return -strength * exp(-(dx * dx) / (2 * sigma * sigma))
    }

    private func pulseBrightness(pulses: [InteractionModel.Pulse], now: Date) -> Double {
        var boost = 0.0
        for pulse in pulses {
            let age = now.timeIntervalSince(pulse.start)
            if age >= 0, age < 1.2 {
                boost += (1.2 - age) / 1.2 * 0.3
            }
        }
        return min(boost, 0.4)
    }
}
