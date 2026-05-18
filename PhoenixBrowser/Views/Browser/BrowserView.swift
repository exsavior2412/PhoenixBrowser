import SwiftUI

struct BrowserView: View {
    @StateObject private var tabManager = TabManager()
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var styleManager = StyleManager()
    @State private var panelVisible = false
    @FocusState private var isOmniboxFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Edge Chrome (tabs + address + favorites)
            EdgeChromeView(
                tabManager: tabManager,
                bookmarkManager: bookmarkManager,
                panelVisible: $panelVisible,
                isOmniboxFocused: $isOmniboxFocused
            )

            // Workspace (rail + content + panel)
            HStack(spacing: 0) {
                // Left rail
                EdgeLeftRailView(panelVisible: $panelVisible)

                // Split area
                HStack(spacing: 0) {
                    // Main content
                    ZStack {
                        if let tab = tabManager.selectedTab {
                            if tab.securityThreat == .phishing || tab.securityThreat == .malware || tab.securityThreat == .certError {
                                SecurityWarningView(
                                    threat: tab.securityThreat!,
                                    url: tab.url ?? URL(string: "about:blank")!,
                                    onProceed: { tab.securityThreat = nil },
                                    onGoBack: { tabManager.goBack() }
                                )
                            } else if tab.url == nil {
                                EdgeNewTabView(
                                    tabManager: tabManager,
                                    bookmarkManager: bookmarkManager
                                )
                            } else {
                                WebView(tab: tab, styleManager: styleManager)
                                    .id(tab.id)
                            }
                        } else {
                            EdgeNewTabView(
                                tabManager: tabManager,
                                bookmarkManager: bookmarkManager
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Right panel
                    if panelVisible {
                        EdgeTabPanelView(
                            tabManager: tabManager,
                            isVisible: $panelVisible
                        )
                        .frame(minWidth: Edge.Sizes.panelMinWidth, maxWidth: 500)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .background(Edge.Colors.panelDarker)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.2), value: panelVisible)
        .onReceive(NotificationCenter.default.publisher(for: .newTabRequested)) { _ in
            tabManager.addNewTab()
        }
    }
}
