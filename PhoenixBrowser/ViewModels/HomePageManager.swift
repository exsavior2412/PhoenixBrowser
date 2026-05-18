import Foundation
import AppKit

final class HomePageManager: ObservableObject {
    static let shared = HomePageManager()

    @Published var shortcuts: [HomeShortcut] = []
    @Published var backgroundImage: NSImage?
    @Published var quickNotes: [String] = []

    private let shortcutsKey = "phoenix_home_shortcuts"
    private let notesKey = "phoenix_home_notes"

    private var bgImageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PhoenixBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("home_bg.jpg")
    }

    init() {
        loadShortcuts()
        loadNotes()
        loadBackgroundImage()

        if shortcuts.isEmpty {
            shortcuts = defaultShortcuts
            saveShortcuts()
        }
    }

    private var defaultShortcuts: [HomeShortcut] {
        [
            HomeShortcut(name: "Google", url: URL(string: "https://www.google.com")!, icon: "magnifyingglass"),
            HomeShortcut(name: "YouTube", url: URL(string: "https://www.youtube.com")!, icon: "play.rectangle.fill"),
            HomeShortcut(name: "GitHub", url: URL(string: "https://github.com")!, icon: "chevron.left.forwardslash.chevron.right"),
            HomeShortcut(name: "Twitter", url: URL(string: "https://x.com")!, icon: "bubble.left.fill"),
            HomeShortcut(name: "Reddit", url: URL(string: "https://www.reddit.com")!, icon: "text.bubble.fill"),
        ]
    }

    // MARK: - Shortcuts

    func addShortcut(name: String, url: URL, icon: String) {
        let shortcut = HomeShortcut(name: name, url: url, icon: icon)
        shortcuts.append(shortcut)
        saveShortcuts()
    }

    func removeShortcut(_ shortcut: HomeShortcut) {
        shortcuts.removeAll { $0.id == shortcut.id }
        saveShortcuts()
    }

    private func saveShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: shortcutsKey)
        }
    }

    private func loadShortcuts() {
        guard let data = UserDefaults.standard.data(forKey: shortcutsKey),
              let saved = try? JSONDecoder().decode([HomeShortcut].self, from: data)
        else { return }
        shortcuts = saved
    }

    // MARK: - Background Image

    func setBackgroundImage(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let imageData = try? Data(contentsOf: url),
              let image = NSImage(data: imageData)
        else { return }

        try? imageData.write(to: bgImageURL)
        backgroundImage = image
    }

    func resetBackground() {
        try? FileManager.default.removeItem(at: bgImageURL)
        backgroundImage = nil
    }

    private func loadBackgroundImage() {
        if FileManager.default.fileExists(atPath: bgImageURL.path),
           let data = try? Data(contentsOf: bgImageURL),
           let image = NSImage(data: data) {
            backgroundImage = image
        }
    }

    // MARK: - Quick Notes

    func addNote(_ note: String) {
        quickNotes.insert(note, at: 0)
        saveNotes()
    }

    func removeNote(at index: Int) {
        quickNotes.remove(at: index)
        saveNotes()
    }

    private func saveNotes() {
        UserDefaults.standard.set(quickNotes, forKey: notesKey)
    }

    private func loadNotes() {
        quickNotes = UserDefaults.standard.stringArray(forKey: notesKey) ?? []
    }
}
