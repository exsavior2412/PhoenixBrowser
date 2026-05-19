import SwiftUI

struct BrowserView: View {
    @StateObject private var tabManager = TabManager()
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var styleManager = StyleManager()
    @StateObject private var devTools = DevToolsManager.shared
    @State private var panelVisible = false
    @State private var devToolsVisible = false
    @FocusState private var isOmniboxFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            EdgeChromeView(
                tabManager: tabManager,
                bookmarkManager: bookmarkManager,
                panelVisible: $panelVisible,
                isOmniboxFocused: $isOmniboxFocused
            )

            HStack(spacing: 0) {
                EdgeLeftRailView(panelVisible: $panelVisible)

                HStack(spacing: 0) {
                    // Main content + devtools
                    VStack(spacing: 0) {
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

                        // DevTools panel (bottom, like Chrome)
                        if devToolsVisible {
                            Divider().background(Color.white.opacity(0.08))
                            DevToolsView(
                                devTools: devTools,
                                tabManager: tabManager,
                                isVisible: $devToolsVisible
                            )
                            .frame(height: 280)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }

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
        .onAppear {
            if tabManager.selectedTab?.url == nil {
                focusOmnibox()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: panelVisible)
        .animation(.easeInOut(duration: 0.2), value: devToolsVisible)
        .onReceive(NotificationCenter.default.publisher(for: .newTabRequested)) { _ in
            tabManager.addNewTab()
            focusOmnibox()
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusOmnibox)) { _ in
            focusOmnibox()
        }
        .onReceive(NotificationCenter.default.publisher(for: .unfocusOmnibox)) { _ in
            isOmniboxFocused = false
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeCurrentTab)) { _ in
            withAnimation(.easeOut(duration: 0.15)) {
                tabManager.closeSelectedTab()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if tabManager.selectedTab?.url == nil {
                    focusOmnibox()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveSession)) { _ in
            tabManager.saveSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleDevTools)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                devToolsVisible.toggle()
            }
        }
    }

    private func focusOmnibox() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isOmniboxFocused = true
        }
    }
}
