import SwiftUI

/// Shared interaction state between the AppKit event layer and the SwiftUI
/// wallpaper scenes. One instance exists per desktop window (and per gallery
/// preview). Coordinates use a top-left origin to match SwiftUI's `Canvas`.
final class InteractionModel: ObservableObject {
    struct Pulse: Identifiable {
        let id = UUID()
        let point: CGPoint
        let start = Date()
    }

    /// Current cursor position, or `nil` when the cursor is outside the scene.
    @Published var cursor: CGPoint?
    @Published var cursorActive = false
    /// Recent clicks. Scenes read these to render ripples / spawn objects.
    @Published var pulses: [Pulse] = []

    func click(at point: CGPoint) {
        pulses.append(Pulse(point: point))
        let cutoff = Date().addingTimeInterval(-6)
        pulses.removeAll { $0.start < cutoff }
    }
}
