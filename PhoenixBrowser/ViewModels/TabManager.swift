import Foundation
import WebKit
import Combine

final class TabManager: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var selectedTabID: UUID?
    @Published var addressText: String = ""

    private var cancellables = Set<AnyCancellable>()
    private var tabObservers = [UUID: Set<AnyCancellable>]()
    private let sessionKey = "phoenix_session_tabs"
    private let selectedKey = "phoenix_session_selected"

    var selectedTab: Tab? {
        tabs.first { $0.id == selectedTabID }
    }

    init() {
        if !restoreSession() {
            addNewTab()
        }
    }

    var isShowingHomePage: Bool {
        selectedTab?.url == nil
    }

    @discardableResult
    func addNewTab(url: URL? = nil, isPrivate: Bool = false) -> Tab {
        let tab = Tab(url: url, isPrivate: isPrivate)
        tabs.append(tab)
        selectTab(tab)
        observeTab(tab)
        saveSession()
        return tab
    }

    @discardableResult
    func addPrivateTab(url: URL? = nil) -> Tab {
        addNewTab(url: url, isPrivate: true)
    }

    func closeTab(_ tab: Tab) {
        tabObservers.removeValue(forKey: tab.id)
        tabs.removeAll { $0.id == tab.id }

        if selectedTabID == tab.id {
            selectedTabID = tabs.last?.id
            if let selected = selectedTab {
                addressText = selected.url?.absoluteString ?? ""
            }
        }

        if tabs.isEmpty {
            addNewTab()
        }
        saveSession()
    }

    func selectTab(_ tab: Tab) {
        selectedTabID = tab.id
        addressText = tab.url?.absoluteString ?? ""
    }

    func navigate(to input: String) {
        guard let tab = selectedTab else { return }

        let url: URL?
        if input.hasPrefix("http://") || input.hasPrefix("https://") {
            url = URL(string: input)
        } else if input.contains(".") && !input.contains(" ") {
            url = URL(string: "https://\(input)")
        } else {
            let query = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            url = URL(string: "https://www.google.com/search?q=\(query)")
        }

        if let url {
            tab.webView.load(URLRequest(url: url))
        }
    }

    func closeSelectedTab() {
        guard let tab = selectedTab else { return }
        closeTab(tab)
    }

    func goBack() { selectedTab?.webView.goBack() }
    func goForward() { selectedTab?.webView.goForward() }
    func reload() { selectedTab?.webView.reload() }
    func stopLoading() { selectedTab?.webView.stopLoading() }

    // MARK: - Session Persistence

    private var isRestoring = false

    func saveSession() {
        guard !isRestoring else { return }
        let session: [String] = tabs.map { $0.url?.absoluteString ?? "" }
        guard !session.isEmpty else { return }
        let selectedIndex = tabs.firstIndex(where: { $0.id == selectedTabID }) ?? 0

        let defaults = UserDefaults.standard
        defaults.set(session, forKey: sessionKey)
        defaults.set(selectedIndex, forKey: selectedKey)
        defaults.synchronize()

        NSLog("[Phoenix] Session saved: \(session.count) tabs, selected=\(selectedIndex)")
    }

    @discardableResult
    private func restoreSession() -> Bool {
        let defaults = UserDefaults.standard
        guard let session = defaults.stringArray(forKey: sessionKey),
              !session.isEmpty,
              // Don't restore if only empty home tabs
              session.contains(where: { !$0.isEmpty })
        else {
            NSLog("[Phoenix] No session to restore")
            return false
        }

        NSLog("[Phoenix] Restoring \(session.count) tabs")
        isRestoring = true

        let selectedIndex = defaults.integer(forKey: selectedKey)

        for urlString in session {
            if urlString.isEmpty {
                let tab = Tab()
                tabs.append(tab)
                observeTab(tab)
            } else if let url = URL(string: urlString) {
                let tab = Tab(url: url)
                tabs.append(tab)
                observeTab(tab)
            }
        }

        // Select the previously active tab
        let safeIndex = min(selectedIndex, tabs.count - 1)
        if safeIndex >= 0, safeIndex < tabs.count {
            selectTab(tabs[safeIndex])
        }

        isRestoring = false
        NSLog("[Phoenix] Restored \(tabs.count) tabs, selected=\(safeIndex)")
        return !tabs.isEmpty
    }

    private func observeTab(_ tab: Tab) {
        var observers = Set<AnyCancellable>()

        tab.webView.publisher(for: \.title)
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .receive(on: RunLoop.main)
            .sink { [weak tab] title in
                tab?.title = title
            }
            .store(in: &observers)

        tab.webView.publisher(for: \.url)
            .receive(on: RunLoop.main)
            .sink { [weak self, weak tab] url in
                tab?.url = url
                if tab?.id == self?.selectedTabID {
                    self?.addressText = url?.absoluteString ?? ""
                }
                // Auto-save session whenever any tab navigates
                self?.saveSession()
            }
            .store(in: &observers)

        tab.webView.publisher(for: \.isLoading)
            .receive(on: RunLoop.main)
            .sink { [weak self, weak tab] isLoading in
                tab?.isLoading = isLoading
                if tab?.id == self?.selectedTabID {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &observers)

        tab.webView.publisher(for: \.canGoBack)
            .receive(on: RunLoop.main)
            .sink { [weak tab] canGoBack in
                tab?.canGoBack = canGoBack
            }
            .store(in: &observers)

        tab.webView.publisher(for: \.canGoForward)
            .receive(on: RunLoop.main)
            .sink { [weak tab] canGoForward in
                tab?.canGoForward = canGoForward
            }
            .store(in: &observers)

        tab.webView.publisher(for: \.estimatedProgress)
            .receive(on: RunLoop.main)
            .sink { [weak self, weak tab] progress in
                tab?.estimatedProgress = progress
                // Force SwiftUI to re-render progress bar for selected tab
                if tab?.id == self?.selectedTabID {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &observers)

        tabObservers[tab.id] = observers
    }
}
