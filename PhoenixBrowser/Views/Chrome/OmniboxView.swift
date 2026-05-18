import SwiftUI

struct AddressBarView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @Binding var panelVisible: Bool
    @FocusState.Binding var isOmniboxFocused: Bool
    @State private var isOmniboxHovered = false

    var body: some View {
        HStack(spacing: 6) {
            chromeIconBtn("chevron.left", enabled: tabManager.selectedTab?.canGoBack == true) {
                tabManager.goBack()
            }
            chromeIconBtn("chevron.right", enabled: tabManager.selectedTab?.canGoForward == true) {
                tabManager.goForward()
            }
            chromeIconBtn(
                tabManager.selectedTab?.isLoading == true ? "xmark" : "arrow.clockwise"
            ) {
                if tabManager.selectedTab?.isLoading == true {
                    tabManager.stopLoading()
                } else {
                    tabManager.reload()
                }
            }
            chromeIconBtn("house") {
                _ = tabManager.addNewTab()
            }

            omnibox

            HStack(spacing: 2) {
                chromeIconBtn("scissors") {}
                chromeIconBtn(bookmarkManager.isBookmarked(url: tabManager.selectedTab?.url) ? "star.fill" : "star") {
                    if let tab = tabManager.selectedTab, let url = tab.url {
                        bookmarkManager.toggle(title: tab.title, url: url)
                    }
                }
                chromeIconBtn("doc.on.doc") {}
                chromeIconBtn("arrow.down.circle") {}
                chromeIconBtn("puzzlepiece.extension") {}

                ZStack {
                    Circle()
                        .fill(Edge.Colors.profileBlue)
                        .frame(width: 22, height: 22)
                    Text("E")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundStyle(.white)
                }

                chromeIconBtn("sparkles") {}
                chromeIconBtn("ellipsis") {}

                chromeIconBtn("sidebar.right") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        panelVisible.toggle()
                    }
                }
            }
        }
        .frame(height: Edge.Sizes.addressRowHeight)
        .padding(.horizontal, 7)
    }

    // MARK: - Omnibox

    private var omnibox: some View {
        HStack(spacing: 5.5) {
            securityIcon.frame(width: 20, height: 20)

            ZStack {
                TextField("Search or enter address", text: $tabManager.addressText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.2))
                    .foregroundStyle(Color(hex: 0x222222))
                    .focused($isOmniboxFocused)
                    .onSubmit {
                        tabManager.navigate(to: tabManager.addressText)
                        isOmniboxFocused = false
                    }
                    .opacity(isOmniboxFocused ? 1 : 0)

                if !isOmniboxFocused {
                    Text(displayURL)
                        .font(.system(size: 12.2))
                        .foregroundStyle(Edge.Colors.textSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { isOmniboxFocused = true }
                }
            }

            omniboxIcon("mic.fill") {}
            omniboxIcon("sparkle") {}
        }
        .padding(.horizontal, 4.5)
        .frame(height: Edge.Sizes.omniboxHeight)
        .frame(minWidth: 144)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.86))
                .shadow(color: Color.white.opacity(0.75), radius: 0, x: 0, y: 1)
        )
        .overlay(
            Capsule()
                .stroke(isOmniboxFocused ? Edge.Colors.omniboxBorder : Edge.Colors.omniboxBorder.opacity(0.5), lineWidth: 1)
        )
        .onHover { isOmniboxHovered = $0 }
        .overlay(alignment: .bottom) {
            if let tab = tabManager.selectedTab, tab.isLoading {
                GeometryReader { geo in
                    Capsule()
                        .fill(Edge.Colors.accentBlue)
                        .frame(width: geo.size.width * tab.estimatedProgress, height: 2)
                        .animation(.linear(duration: 0.2), value: tab.estimatedProgress)
                }
                .frame(height: 2)
                .offset(y: 2)
            }
        }
    }

    @ViewBuilder
    private var securityIcon: some View {
        if let tab = tabManager.selectedTab {
            switch tab.securityLevel {
            case .secure:
                Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(.green)
            case .insecure:
                Image(systemName: "lock.open.fill").font(.system(size: 9)).foregroundStyle(.orange)
            case .dangerous:
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 9)).foregroundStyle(.red)
            case .unknown:
                Image(systemName: "globe").font(.system(size: 10)).foregroundStyle(Edge.Colors.iconColor)
            }
        }
    }

    private var displayURL: String {
        guard let url = tabManager.selectedTab?.url else { return "Search or enter address" }
        return url.host() ?? url.absoluteString
    }

    private func omniboxIcon(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Edge.Colors.iconColor)
                .frame(width: 20, height: 20)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
