import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Start as an accessory (menu-bar) app; the gallery window promotes us to .regular.
app.setActivationPolicy(.accessory)
app.run()
