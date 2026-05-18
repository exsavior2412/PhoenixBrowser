import XCTest
@testable import PhoenixBrowser

final class HomePageTests: XCTestCase {

    // MARK: - HomeShortcut Model

    func testHomeShortcut_init() {
        let url = URL(string: "https://test.com")!
        let shortcut = HomeShortcut(name: "Test", url: url, icon: "globe")
        XCTAssertEqual(shortcut.name, "Test")
        XCTAssertEqual(shortcut.url, url)
        XCTAssertEqual(shortcut.icon, "globe")
    }

    func testHomeShortcut_codable() {
        let shortcut = HomeShortcut(name: "Encode", url: URL(string: "https://test.com")!, icon: "star")
        let data = try! JSONEncoder().encode(shortcut)
        let decoded = try! JSONDecoder().decode(HomeShortcut.self, from: data)
        XCTAssertEqual(decoded.name, shortcut.name)
        XCTAssertEqual(decoded.url, shortcut.url)
        XCTAssertEqual(decoded.icon, shortcut.icon)
        XCTAssertEqual(decoded.id, shortcut.id)
    }

    func testHomeShortcut_defaultIcon() {
        let shortcut = HomeShortcut(name: "Default", url: URL(string: "https://x.com")!)
        XCTAssertEqual(shortcut.icon, "globe")
    }

    // MARK: - HomePageManager

    func testHomePageManager_hasDefaultShortcuts() {
        let hpm = HomePageManager.shared
        XCTAssertGreaterThanOrEqual(hpm.shortcuts.count, 1)
    }

    func testHomePageManager_addShortcut() {
        let hpm = HomePageManager.shared
        let countBefore = hpm.shortcuts.count
        hpm.addShortcut(name: "Test Add", url: URL(string: "https://added.com")!, icon: "plus")
        XCTAssertEqual(hpm.shortcuts.count, countBefore + 1)
        XCTAssertEqual(hpm.shortcuts.last?.name, "Test Add")
        // Cleanup
        hpm.removeShortcut(hpm.shortcuts.last!)
    }

    func testHomePageManager_removeShortcut() {
        let hpm = HomePageManager.shared
        hpm.addShortcut(name: "ToRemove", url: URL(string: "https://remove.com")!, icon: "trash")
        let countAfterAdd = hpm.shortcuts.count
        hpm.removeShortcut(hpm.shortcuts.last!)
        XCTAssertEqual(hpm.shortcuts.count, countAfterAdd - 1)
    }

    func testHomePageManager_addNote() {
        let hpm = HomePageManager.shared
        let countBefore = hpm.quickNotes.count
        hpm.addNote("Test note")
        XCTAssertEqual(hpm.quickNotes.count, countBefore + 1)
        XCTAssertEqual(hpm.quickNotes.first, "Test note")
        // Cleanup
        hpm.removeNote(at: 0)
    }

    func testHomePageManager_removeNote() {
        let hpm = HomePageManager.shared
        hpm.addNote("Note to remove")
        let countAfterAdd = hpm.quickNotes.count
        hpm.removeNote(at: 0)
        XCTAssertEqual(hpm.quickNotes.count, countAfterAdd - 1)
    }

    func testHomePageManager_notesInsertAtFront() {
        let hpm = HomePageManager.shared
        hpm.addNote("First")
        hpm.addNote("Second")
        XCTAssertEqual(hpm.quickNotes.first, "Second")
        // Cleanup
        hpm.removeNote(at: 0)
        hpm.removeNote(at: 0)
    }

    func testHomePageManager_resetBackground() {
        let hpm = HomePageManager.shared
        hpm.resetBackground()
        XCTAssertNil(hpm.backgroundImage)
    }

    // MARK: - Bookmark Model

    func testBookmark_init() {
        let url = URL(string: "https://bookmark.com")!
        let bookmark = Bookmark(title: "BM", url: url)
        XCTAssertEqual(bookmark.title, "BM")
        XCTAssertEqual(bookmark.url, url)
        XCTAssertNotNil(bookmark.dateAdded)
    }

    func testBookmark_codable() {
        let bookmark = Bookmark(title: "Codable", url: URL(string: "https://codable.com")!)
        let data = try! JSONEncoder().encode(bookmark)
        let decoded = try! JSONDecoder().decode(Bookmark.self, from: data)
        XCTAssertEqual(decoded.title, bookmark.title)
        XCTAssertEqual(decoded.url, bookmark.url)
        XCTAssertEqual(decoded.id, bookmark.id)
    }
}
