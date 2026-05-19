import SwiftUI

/// A retro synthwave horizon: a scrolling perspective grid under a neon sun.
/// The cursor lights up the grid; clicks send a pulse ring across it.
struct NeonGridWallpaper: View {
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

    private func draw(into context: inout GraphicsContext, size: CGSize, time: Double,
                      cursor: CGPoint?, pulses: [InteractionModel.Pulse], now: Date) {
        let horizon = size.height * 0.52
        let pink = Color(red: 1.0, green: 0.25, blue: 0.7)
        let cyan = Color(red: 0.25, green: 0.95, blue: 1.0)

        // Sky gradient.
        context.fill(
            Path(CGRect(x: 0, y: 0, width: size.width, height: horizon)),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.10, green: 0.02, blue: 0.22),
                    Color(red: 0.35, green: 0.06, blue: 0.40),
                    Color(red: 0.95, green: 0.30, blue: 0.45)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: horizon)))

        // The sun, with its trademark horizontal slits.
        let sunRadius = size.height * 0.20
        let sunCenter = CGPoint(x: size.width / 2, y: horizon - sunRadius * 0.35)
        var sun = context
        sun.clip(to: Path(ellipseIn: CGRect(x: sunCenter.x - sunRadius,
                                            y: sunCenter.y - sunRadius,
                                            width: sunRadius * 2,
                                            height: sunRadius * 2)))
        sun.fill(
            Path(CGRect(x: sunCenter.x - sunRadius, y: sunCenter.y - sunRadius,
                        width: sunRadius * 2, height: sunRadius * 2)),
            with: .linearGradient(
                Gradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.3),
                                  Color(red: 1.0, green: 0.3, blue: 0.5)]),
                startPoint: CGPoint(x: 0, y: sunCenter.y - sunRadius),
                endPoint: CGPoint(x: 0, y: sunCenter.y + sunRadius)))
        var slit = sunCenter.y + sunRadius * 0.15
        var gap: CGFloat = 6
        while slit < sunCenter.y + sunRadius {
            sun.fill(
                Path(CGRect(x: sunCenter.x - sunRadius, y: slit,
                            width: sunRadius * 2, height: gap)),
                with: .color(Color(red: 0.35, green: 0.06, blue: 0.40)))
            slit += gap * 2.2
            gap += 2
        }

        // Ground.
        context.fill(
            Path(CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon)),
            with: .linearGradient(
                Gradient(colors: [Color(red: 0.06, green: 0.01, blue: 0.14),
                                  Color(red: 0.14, green: 0.02, blue: 0.22)]),
                startPoint: CGPoint(x: 0, y: horizon),
                endPoint: CGPoint(x: 0, y: size.height)))

        var grid = context
        grid.blendMode = .plusLighter
        let vanishing = CGPoint(x: size.width / 2, y: horizon)

        // Converging vertical lines. Lines near the cursor's column light up.
        let columns = 26
        for i in -columns...columns {
            let spread = CGFloat(i) / CGFloat(columns)
            let bottomX = size.width / 2 + spread * size.width * 1.6
            var line = Path()
            line.move(to: vanishing)
            line.addLine(to: CGPoint(x: bottomX, y: size.height))
            var opacity = 0.35
            var width: CGFloat = 1
            if let cursor {
                let prox = max(0, 1 - abs(bottomX - cursor.x) / 220)
                opacity += Double(prox) * 0.5
                width += prox * 1.6
            }
            grid.stroke(line, with: .color(cyan.opacity(opacity)), lineWidth: width)
        }

        // Horizontal lines scrolling toward the viewer. Rows near the cursor
        // light up as it moves over the grid.
        let rows = 18
        let scroll = CGFloat(time.truncatingRemainder(dividingBy: 1.0))
        for i in 0..<rows {
            let frac = (CGFloat(i) + scroll) / CGFloat(rows)
            let y = horizon + (size.height - horizon) * frac * frac
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: size.width, y: y))
            var opacity = 0.5
            var width = 1 + frac * 1.6
            if let cursor {
                let prox = max(0, 1 - abs(y - cursor.y) / 160)
                opacity += Double(prox) * 0.5
                width += prox * 2
            }
            grid.stroke(line, with: .color(pink.opacity(opacity)), lineWidth: width)
        }

        context.drawRipples(pulses, now: now, color: cyan,
                            maxRadius: size.width * 0.5, life: 1.6)
    }
}
