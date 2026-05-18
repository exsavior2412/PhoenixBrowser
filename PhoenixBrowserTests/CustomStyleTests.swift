import XCTest
@testable import PhoenixBrowser

final class CustomStyleTests: XCTestCase {

    // MARK: - URL Pattern Matching

    func testMatchesURL_wildcard() {
        let style = CustomStyle(name: "All", css: "body{}", urlPattern: "*")
        XCTAssertTrue(style.matchesURL(URL(string: "https://google.com")))
        XCTAssertTrue(style.matchesURL(URL(string: "https://example.com/path")))
    }

    func testMatchesURL_exactDomain() {
        let style = CustomStyle(name: "GH", css: "body{}", urlPattern: "github.com")
        XCTAssertTrue(style.matchesURL(URL(string: "https://github.com")))
        XCTAssertFalse(style.matchesURL(URL(string: "https://google.com")))
    }

    func testMatchesURL_wildcardSubdomain() {
        let style = CustomStyle(name: "GH", css: "body{}", urlPattern: "*.github.com")
        XCTAssertTrue(style.matchesURL(URL(string: "https://docs.github.com")))
        XCTAssertTrue(style.matchesURL(URL(string: "https://api.github.com")))
        // Note: "github.com" itself won't match "*.github.com" because * requires at least one char
    }

    func testMatchesURL_nil() {
        let style = CustomStyle(name: "T", css: "body{}", urlPattern: "*")
        XCTAssertFalse(style.matchesURL(nil))
    }

    func testMatchesURL_noHost() {
        let style = CustomStyle(name: "T", css: "body{}", urlPattern: "*")
        XCTAssertFalse(style.matchesURL(URL(string: "about:blank")))
    }

    // MARK: - Init

    func testInit_defaults() {
        let style = CustomStyle(name: "Test", css: "body{color:red}")
        XCTAssertEqual(style.name, "Test")
        XCTAssertEqual(style.css, "body{color:red}")
        XCTAssertEqual(style.urlPattern, "*")
        XCTAssertTrue(style.isEnabled)
    }

    func testInit_customPattern() {
        let style = CustomStyle(name: "T", css: "a{}", urlPattern: "*.google.com", isEnabled: false)
        XCTAssertEqual(style.urlPattern, "*.google.com")
        XCTAssertFalse(style.isEnabled)
    }

    // MARK: - Codable

    func testCodable_roundTrip() {
        let style = CustomStyle(name: "Encode", css: "body{background:#000}", urlPattern: "*.test.com")
        let data = try! JSONEncoder().encode(style)
        let decoded = try! JSONDecoder().decode(CustomStyle.self, from: data)
        XCTAssertEqual(decoded.name, style.name)
        XCTAssertEqual(decoded.css, style.css)
        XCTAssertEqual(decoded.urlPattern, style.urlPattern)
        XCTAssertEqual(decoded.isEnabled, style.isEnabled)
        XCTAssertEqual(decoded.id, style.id)
    }

    // MARK: - StyleManager

    func testStyleManager_addAndRemove() {
        let sm = StyleManager()
        sm.add(name: "Test", css: "body{}")
        XCTAssertEqual(sm.styles.count, 1)
        sm.remove(sm.styles.first!)
        XCTAssertEqual(sm.styles.count, 0)
    }

    func testStyleManager_toggle() {
        let sm = StyleManager()
        sm.add(name: "Toggle", css: "a{}")
        XCTAssertTrue(sm.styles.first!.isEnabled)
        sm.toggleStyle(sm.styles.first!)
        XCTAssertFalse(sm.styles.first!.isEnabled)
        sm.toggleStyle(sm.styles.first!)
        XCTAssertTrue(sm.styles.first!.isEnabled)
        // Cleanup
        sm.remove(sm.styles.first!)
    }

    func testStyleManager_update() {
        let sm = StyleManager()
        sm.add(name: "Update", css: "old{}")
        var style = sm.styles.first!
        style.css = "new{}"
        sm.update(style)
        XCTAssertEqual(sm.styles.first!.css, "new{}")
        sm.remove(sm.styles.first!)
    }
}
