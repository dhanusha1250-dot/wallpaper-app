import SwiftUI

/// App-wide settings, grouped into a standard macOS form.
struct SettingsPage: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Playback") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "Animation speed  %.2f×", settings.speed))
                        .font(.callout)
                    Slider(value: $settings.speed, in: 0.25...2.5)
                }
                Toggle("Pause all animation", isOn: $settings.isPaused)
            }

            Section("Appearance") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dim  \(Int(settings.dim * 100))%")
                        .font(.callout)
                    Slider(value: $settings.dim, in: 0...0.8)
                }
            }

            Section("Interaction") {
                Toggle("Interactive on desktop", isOn: $settings.interactive)
                Text("When on, wallpapers respond to your cursor and clicks anywhere on the desktop. Your desktop icons, folders and disk images stay fully visible and usable. When off, the wallpaper is a purely ambient background.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Video Wallpaper") {
                Picker("Scaling", selection: $settings.videoFillMode) {
                    ForEach(VideoFillMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                Toggle("Mute video audio", isOn: $settings.videoMuted)
            }

            Section {
                Button("Restore Defaults") {
                    settings.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
