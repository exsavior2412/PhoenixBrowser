import SwiftUI

struct EdgeChromeView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @Binding var panelVisible: Bool
    @FocusState.Binding var isOmniboxFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TabStripView(tabManager: tabManager)
            AddressBarView(
                tabManager: tabManager,
                bookmarkManager: bookmarkManager,
                panelVisible: $panelVisible,
                isOmniboxFocused: $isOmniboxFocused
            )
            FavoritesBarView(
                bookmarkManager: bookmarkManager,
                tabManager: tabManager
            )
        }
        .background(
            LinearGradient(
                colors: [Edge.Colors.chromeMain, Edge.Colors.chromeDark],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
