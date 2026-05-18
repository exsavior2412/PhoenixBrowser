import XCTest
@testable import PhoenixBrowser

final class TabManagerTests: XCTestCase {

    var tabManager: TabManager!

    override func setUp() {
        super.setUp()
        tabManager = TabManager()
    }

    // MARK: - Init

    func testInit_createsOneTab() {
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertNotNil(tabManager.selectedTabID)
    }

    func testInit_firstTabIsHomePage() {
        XCTAssertNil(tabManager.selectedTab?.url)
        XCTAssertTrue(tabManager.isShowingHomePage)
    }

    // MARK: - Add Tab

    func testAddNewTab_incrementsCount() {
        let before = tabManager.tabs.count
        tabManager.addNewTab()
        XCTAssertEqual(tabManager.tabs.count, before + 1)
    }

    func testAddNewTab_selectsNewTab() {
        let newTab = tabManager.addNewTab()
        XCTAssertEqual(tabManager.selectedTabID, newTab.id)
    }

    func testAddNewTab_withURL() {
        let url = URL(string: "https://example.com")!
        let tab = tabManager.addNewTab(url: url)
        XCTAssertEqual(tab.url, url)
    }

    func testAddNewTab_withoutURL_isHomePage() {
        let tab = tabManager.addNewTab()
        XCTAssertNil(tab.url)
    }

    func testAddPrivateTab() {
        let tab = tabManager.addPrivateTab()
        XCTAssertTrue(tab.isPrivate)
        XCTAssertEqual(tab.title, "Private Tab")
    }

    func testAddPrivateTab_withURL() {
        let url = URL(string: "https://example.com")!
        let tab = tabManager.addPrivateTab(url: url)
        XCTAssertTrue(tab.isPrivate)
        XCTAssertEqual(tab.url, url)
    }

    func testAddMultipleTabs() {
        tabManager.addNewTab()
        tabManager.addNewTab()
        tabManager.addNewTab()
        XCTAssertEqual(tabManager.tabs.count, 4) // 1 init + 3 new
    }

    // MARK: - Close Tab

    func testCloseTab_removesTab() {
        let tab = tabManager.addNewTab()
        let countBefore = tabManager.tabs.count
        tabManager.closeTab(tab)
        XCTAssertEqual(tabManager.tabs.count, countBefore - 1)
    }

    func testCloseTab_selectsPreviousTab() {
        let tab1 = tabManager.tabs.first!
        let tab2 = tabManager.addNewTab()
        tabManager.closeTab(tab2)
        XCTAssertEqual(tabManager.selectedTabID, tab1.id)
    }

    func testCloseLastTab_createsNewTab() {
        // Close all existing tabs
        let allTabs = tabManager.tabs
        for tab in allTabs {
            tabManager.closeTab(tab)
        }
        // Should always have at least 1 tab
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertNotNil(tabManager.selectedTabID)
    }

    func testCloseTab_notSelected_keepsSelection() {
        let tab1 = tabManager.tabs.first!
        let tab2 = tabManager.addNewTab()
        tabManager.selectTab(tab1) // select tab1
        let tab3 = tabManager.addNewTab()
        tabManager.selectTab(tab2) // select tab2
        tabManager.closeTab(tab3) // close tab3 (not selected)
        XCTAssertEqual(tabManager.selectedTabID, tab2.id)
    }

    // MARK: - Select Tab

    func testSelectTab_updatesSelectedID() {
        let tab1 = tabManager.tabs.first!
        let tab2 = tabManager.addNewTab(url: URL(string: "https://test.com"))
        tabManager.selectTab(tab1)
        XCTAssertEqual(tabManager.selectedTabID, tab1.id)
        tabManager.selectTab(tab2)
        XCTAssertEqual(tabManager.selectedTabID, tab2.id)
    }

    func testSelectTab_updatesAddressText() {
        let url = URL(string: "https://example.com")!
        let tab = tabManager.addNewTab(url: url)
        tabManager.selectTab(tab)
        XCTAssertEqual(tabManager.addressText, url.absoluteString)
    }

    func testSelectTab_homePageClearsAddress() {
        let homeTab = tabManager.addNewTab()
        tabManager.selectTab(homeTab)
        XCTAssertEqual(tabManager.addressText, "")
    }

    // MARK: - Navigate

    func testNavigate_fullURL() {
        tabManager.addNewTab()
        tabManager.navigate(to: "https://example.com")
        // WebView load is async, just verify no crash
    }

    func testNavigate_domainOnly() {
        tabManager.addNewTab()
        tabManager.navigate(to: "example.com")
        // Should prepend https://
    }

    func testNavigate_searchQuery() {
        tabManager.addNewTab()
        tabManager.navigate(to: "swift tutorial")
        // Should create Google search URL
    }

    func testNavigate_httpURL() {
        tabManager.addNewTab()
        tabManager.navigate(to: "http://example.com")
        // Should allow (security delegate handles upgrade)
    }

    func testNavigate_emptySelectedTab() {
        // Edge case: no crash when no tab selected
        tabManager.selectedTabID = nil
        tabManager.navigate(to: "test") // Should not crash
    }

    // MARK: - isShowingHomePage

    func testIsShowingHomePage_true() {
        tabManager.addNewTab() // no URL = home
        XCTAssertTrue(tabManager.isShowingHomePage)
    }

    func testIsShowingHomePage_false() {
        tabManager.addNewTab(url: URL(string: "https://google.com"))
        XCTAssertFalse(tabManager.isShowingHomePage)
    }
}
