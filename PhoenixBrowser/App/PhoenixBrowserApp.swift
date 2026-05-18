import SwiftUI

@main
struct PhoenixBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            BrowserView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1360, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    NotificationCenter.default.post(name: .newTabRequested, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let newTabRequested = Notification.Name("newTabRequested")
}
