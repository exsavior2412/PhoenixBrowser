import SwiftUI

@main
struct PhoenixBrowserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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

                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeCurrentTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button("Toggle Developer Tools") {
                    NotificationCenter.default.post(name: .toggleDevTools, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
        }
    }
}

// MARK: - AppDelegate (handle quit + session save)

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save session before quit
        NotificationCenter.default.post(name: .saveSession, object: nil)
        // Small delay to let save complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let newTabRequested = Notification.Name("newTabRequested")
    static let closeCurrentTab = Notification.Name("closeCurrentTab")
    static let focusOmnibox = Notification.Name("focusOmnibox")
    static let unfocusOmnibox = Notification.Name("unfocusOmnibox")
    static let saveSession = Notification.Name("saveSession")
    static let toggleDevTools = Notification.Name("toggleDevTools")
}
