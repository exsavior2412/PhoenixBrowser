import Foundation

final class BookmarkManager: ObservableObject {
    @Published var bookmarks: [Bookmark] = []

    private let storageKey = "phoenix_bookmarks"

    init() {
        load()
    }

    func add(title: String, url: URL) {
        let bookmark = Bookmark(title: title, url: url)
        bookmarks.insert(bookmark, at: 0)
        save()
    }

    func remove(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        save()
    }

    func isBookmarked(url: URL?) -> Bool {
        guard let url else { return false }
        return bookmarks.contains { $0.url == url }
    }

    func toggle(title: String, url: URL) {
        if let existing = bookmarks.first(where: { $0.url == url }) {
            remove(existing)
        } else {
            add(title: title, url: url)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([Bookmark].self, from: data)
        else { return }
        bookmarks = saved
    }
}
