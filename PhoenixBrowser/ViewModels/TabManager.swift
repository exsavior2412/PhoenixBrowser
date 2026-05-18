import Foundation
import WebKit
import Combine

final class TabManager: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var selectedTabID: UUID?
    @Published var addressText: String = ""

    private var cancellables = Set<AnyCancellable>()
    private var tabObservers = [UUID: Set<AnyCancellable>]()

    var selectedTab: Tab? {
        tabs.first { $0.id == selectedTabID }
    }

    init() {
        addNewTab()  // Open home page by default
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

    func goBack() { selectedTab?.webView.goBack() }
    func goForward() { selectedTab?.webView.goForward() }
    func reload() { selectedTab?.webView.reload() }
    func stopLoading() { selectedTab?.webView.stopLoading() }

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
            }
            .store(in: &observers)

        tab.webView.publisher(for: \.isLoading)
            .receive(on: RunLoop.main)
            .sink { [weak tab] isLoading in
                tab?.isLoading = isLoading
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
            .sink { [weak tab] progress in
                tab?.estimatedProgress = progress
            }
            .store(in: &observers)

        tabObservers[tab.id] = observers
    }
}
