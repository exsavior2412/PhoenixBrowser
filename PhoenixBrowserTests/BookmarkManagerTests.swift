import XCTest
@testable import PhoenixBrowser

final class BookmarkManagerTests: XCTestCase {

    var bookmarkManager: BookmarkManager!

    override func setUp() {
        super.setUp()
        // Use fresh manager — clear stored data
        UserDefaults.standard.removeObject(forKey: "phoenix_bookmarks_test")
        bookmarkManager = BookmarkManager()
        // Clear any existing bookmarks
        for b in bookmarkManager.bookmarks {
            bookmarkManager.remove(b)
        }
    }

    // MARK: - Add

    func testAdd_insertsAtFront() {
        let url1 = URL(string: "https://a.com")!
        let url2 = URL(string: "https://b.com")!
        bookmarkManager.add(title: "A", url: url1)
        bookmarkManager.add(title: "B", url: url2)
        XCTAssertEqual(bookmarkManager.bookmarks.first?.title, "B")
    }

    func testAdd_incrementsCount() {
        let url = URL(string: "https://test.com")!
        bookmarkManager.add(title: "Test", url: url)
        XCTAssertTrue(bookmarkManager.bookmarks.contains { $0.url == url })
    }

    func testAdd_duplicateURLs() {
        let url = URL(string: "https://test.com")!
        bookmarkManager.add(title: "Test1", url: url)
        bookmarkManager.add(title: "Test2", url: url)
        let matching = bookmarkManager.bookmarks.filter { $0.url == url }
        XCTAssertEqual(matching.count, 2, "Should allow duplicate URLs")
    }

    // MARK: - Remove

    func testRemove_decreasesCount() {
        let url = URL(string: "https://remove.com")!
        bookmarkManager.add(title: "Remove", url: url)
        let bookmark = bookmarkManager.bookmarks.first { $0.url == url }!
        bookmarkManager.remove(bookmark)
        XCTAssertFalse(bookmarkManager.bookmarks.contains { $0.url == url })
    }

    func testRemove_nonExistent_noEffect() {
        let count = bookmarkManager.bookmarks.count
        let fake = Bookmark(title: "Fake", url: URL(string: "https://fake.com")!)
        bookmarkManager.remove(fake)
        XCTAssertEqual(bookmarkManager.bookmarks.count, count)
    }

    // MARK: - isBookmarked

    func testIsBookmarked_true() {
        let url = URL(string: "https://check.com")!
        bookmarkManager.add(title: "Check", url: url)
        XCTAssertTrue(bookmarkManager.isBookmarked(url: url))
    }

    func testIsBookmarked_false() {
        let url = URL(string: "https://notbookmarked.com")!
        XCTAssertFalse(bookmarkManager.isBookmarked(url: url))
    }

    func testIsBookmarked_nil() {
        XCTAssertFalse(bookmarkManager.isBookmarked(url: nil))
    }

    // MARK: - Toggle

    func testToggle_addsWhenNotExist() {
        let url = URL(string: "https://toggle.com")!
        bookmarkManager.toggle(title: "Toggle", url: url)
        XCTAssertTrue(bookmarkManager.isBookmarked(url: url))
    }

    func testToggle_removesWhenExist() {
        let url = URL(string: "https://toggle2.com")!
        bookmarkManager.add(title: "Toggle2", url: url)
        bookmarkManager.toggle(title: "Toggle2", url: url)
        XCTAssertFalse(bookmarkManager.isBookmarked(url: url))
    }

    func testToggle_doubleToggle_addsBack() {
        let url = URL(string: "https://double.com")!
        bookmarkManager.toggle(title: "D", url: url) // add
        bookmarkManager.toggle(title: "D", url: url) // remove
        bookmarkManager.toggle(title: "D", url: url) // add again
        XCTAssertTrue(bookmarkManager.isBookmarked(url: url))
    }
}
