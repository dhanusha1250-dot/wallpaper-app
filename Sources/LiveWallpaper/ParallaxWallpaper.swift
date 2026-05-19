import SwiftUI

/// A layered scenic vista. The cursor shifts each layer by an amount
/// proportional to its depth, producing a parallax "looking around" effect.
/// With no cursor, the layers drift gently on their own.
struct ParallaxWallpaper: View {
    @ObservedObject var model: InteractionModel
    @ObservedObject var settings: AppSettings
    @State private var state = ParallaxState()

    var body: some View {
        TimelineView(.animation(paused: settings.isPaused)) { timeline in
            Canvas { context, size in
                let frame = state.update(cursor: model.cursor,
                                         size: size,
                                         date: timeline.date,
                                         speed: settings.speed,
                                         paused: settings.isPaused)
                ParallaxScene.draw(into: &context, size: size,
                                   time: frame.time, px: frame.px, py: frame.py)
            }
        }
    }
}

/// Smooths the parallax offset so cursor movement never looks jittery.
final class ParallaxState {
    private let clock = AnimationClock()
    private var px: CGFloat = 0
    private var py: CGFloat = 0

    func update(cursor: CGPoint?, size: CGSize, date: Date,
                speed: Double, paused: Bool) -> (time: Double, px: CGFloat, py: CGFloat) {
        let t = clock.tick(date, speed: speed, paused: paused)
        let targetX: CGFloat
        let targetY: CGFloat
        if let cursor {
            targetX = (cursor.x / max(size.width, 1) - 0.5) * 2
            targetY = (cursor.y / max(size.height, 1) - 0.5) * 2
        } else {
            // Gentle autonomous drift when nothing is pointing at the scene.
            targetX = CGFloat(sin(t * 0.30)) * 0.40
            targetY = CGFloat(sin(t * 0.22)) * 0.22
        }
        let ease: CGFloat = paused ? 1 : 0.09
        px += (targetX.clamped(to: -1...1) - px) * ease
        py += (targetY.clamped(to: -1...1) - py) * ease
        return (t, px, py)
    }
}

enum ParallaxScene {
    static let maxShiftX: CGFloat = 90
    static let maxShiftY: CGFloat = 40

    static func draw(into context: inout GraphicsContext, size: CGSize,
                     time: Double, px: CGFloat, py: CGFloat) {
        // Twilight sky.
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.09, green: 0.08, blue: 0.26),
                    Color(red: 0.44, green: 0.26, blue: 0.42),
                    Color(red: 0.98, green: 0.56, blue: 0.36)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)))

        // Distant stars (smallest parallax).
        var starLayer = context
        starLayer.blendMode = .plusLighter
        let starDX = -px * maxShiftX * 0.05
        let starDY = -py * maxShiftY * 0.05
        for i in 0..<46 {
            let x = CGFloat((i * 71) % 100) / 100 * size.width + starDX
            let y = CGFloat((i * 29) % 100) / 100 * size.height * 0.4 + starDY
            let twinkle = 0.3 + 0.4 * sin(time * 1.4 + Double(i))
            starLayer.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: 1.7, height: 1.7)),
                with: .color(.white.opacity(twinkle)))
        }

        drawSun(into: &context, size: size, px: px, py: py)

        drawRidge(into: &context, size: size, depth: 0.24, baseYFrac: 0.56,
                  amp: 58, seed: 0.0, px: px, py: py,
                  color: Color(red: 0.43, green: 0.33, blue: 0.52))

        drawClouds(into: &context, size: size, time: time, px: px, py: py)

        drawRidge(into: &context, size: size, depth: 0.50, baseYFrac: 0.66,
                  amp: 80, seed: 11.0, px: px, py: py,
                  color: Color(red: 0.27, green: 0.19, blue: 0.35))

        drawRidge(into: &context, size: size, depth: 0.74, baseYFrac: 0.79,
                  amp: 64, seed: 23.0, px: px, py: py,
                  color: Color(red: 0.15, green: 0.10, blue: 0.21))

        drawRidge(into: &context, size: size, depth: 1.0, baseYFrac: 0.92,
                  amp: 50, seed: 37.0, px: px, py: py,
                  color: Color(red: 0.05, green: 0.03, blue: 0.09))
    }

    private static func drawSun(into context: inout GraphicsContext, size: CGSize,
                                px: CGFloat, py: CGFloat) {
        let depth: CGFloat = 0.10
        let center = CGPoint(x: size.width * 0.52 - px * maxShiftX * depth,
                             y: size.height * 0.40 - py * maxShiftY * depth)
        let radius = size.height * 0.14
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - radius * 2.4, y: center.y - radius * 2.4,
                                   width: radius * 4.8, height: radius * 4.8)),
            with: .radialGradient(
                Gradient(colors: [Color(red: 1.0, green: 0.7, blue: 0.4).opacity(0.45), .clear]),
                center: center, startRadius: 0, endRadius: radius * 2.4))
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                   width: radius * 2, height: radius * 2)),
            with: .radialGradient(
                Gradient(colors: [Color(red: 1.0, green: 0.93, blue: 0.72),
                                  Color(red: 1.0, green: 0.6, blue: 0.4)]),
                center: center, startRadius: 0, endRadius: radius))
    }

    private static func drawClouds(into context: inout GraphicsContext, size: CGSize,
                                   time: Double, px: CGFloat, py: CGFloat) {
        let depth: CGFloat = 0.36
        let dx = -px * maxShiftX * depth
        let dy = -py * maxShiftY * depth
        var layer = context
        layer.blendMode = .plusLighter
        let tint = Color(red: 1.0, green: 0.72, blue: 0.62)
        let span = size.width + 420
        for i in 0..<5 {
            let drift = CGFloat(time * 11).truncatingRemainder(dividingBy: span)
            let x = (CGFloat(i) / 5 * span + drift).truncatingRemainder(dividingBy: span) - 210 + dx
            let y = size.height * (0.30 + 0.08 * CGFloat((i * 37) % 10) / 10) + dy
            let w = size.width * (0.16 + 0.08 * CGFloat((i * 53) % 10) / 10)
            let h = w * 0.30
            for k in 0..<3 {
                let ratio: CGFloat = (k == 1) ? 1.3 : 0.85
                let cw = w * 0.6 * ratio
                let ch = h * ratio
                let ox = CGFloat(k - 1) * w * 0.30
                layer.fill(
                    Path(ellipseIn: CGRect(x: x + ox - cw / 2, y: y - ch / 2,
                                           width: cw, height: ch)),
                    with: .color(tint.opacity(0.14)))
            }
        }
    }

    private static func drawRidge(into context: inout GraphicsContext, size: CGSize,
                                  depth: CGFloat, baseYFrac: CGFloat, amp: CGFloat,
                                  seed: Double, px: CGFloat, py: CGFloat, color: Color) {
        let dx = -px * maxShiftX * depth
        let dy = -py * maxShiftY * depth
        let baseY = size.height * baseYFrac + dy
        let overscan: CGFloat = maxShiftX + 40
        let step: CGFloat = 6

        var path = Path()
        path.move(to: CGPoint(x: -overscan, y: size.height + 2))
        var x: CGFloat = -overscan
        while x <= size.width + overscan {
            path.addLine(to: CGPoint(x: x, y: baseY + ridge(x, seed: seed, amp: amp)))
            x += step
        }
        path.addLine(to: CGPoint(x: size.width + overscan, y: size.height + 2))
        path.closeSubpath()

        context.fill(
            path.offsetBy(dx: dx, dy: 0),
            with: .linearGradient(
                Gradient(colors: [color, color.opacity(0.8)]),
                startPoint: CGPoint(x: 0, y: baseY - amp),
                endPoint: CGPoint(x: 0, y: size.height)))
    }

    /// Layered sines give a stable, natural-looking ridge silhouette.
    private static func ridge(_ x: CGFloat, seed: Double, amp: CGFloat) -> CGFloat {
        let s = Double(x) * 0.0017 + seed
        let n = sin(s) * 0.55 + sin(s * 2.7 + 1.3) * 0.30 + sin(s * 6.3 + 3.9) * 0.15
        return CGFloat(n) * amp
    }
}
