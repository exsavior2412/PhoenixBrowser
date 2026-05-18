import SwiftUI

enum PanelMode: String, CaseIterable {
    case openTabs = "Open tabs"
    case recentlyClosed = "Recently closed"
}

struct EdgeTabPanelView: View {
    @ObservedObject var tabManager: TabManager
    @Binding var isVisible: Bool
    @State private var panelMode: PanelMode = .openTabs
    @State private var panelSearch = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isVisible = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0xb8b8b8))
                        .frame(width: 26, height: 26)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.001)))
                }
                .buttonStyle(.plain)
            }
            .frame(height: 28)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x9f9f9f))

                TextField("Search tabs", text: $panelSearch)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0xe8e8e8))
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .frame(maxWidth: 400)
            .background(
                Capsule()
                    .fill(Color(hex: 0x2c2c2c))
                    .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
            .padding(.vertical, 18)

            // Mode tabs
            HStack(spacing: 29) {
                ForEach(PanelMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { panelMode = mode }
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 12.2, weight: .semibold))
                            .foregroundStyle(panelMode == mode ? .white : Color(hex: 0x9e9e9e))
                            .overlay(alignment: .bottom) {
                                if panelMode == mode {
                                    Rectangle()
                                        .fill(Edge.Colors.panelActiveBlue)
                                        .frame(height: 2)
                                        .offset(y: 7)
                                        .transition(.opacity)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 18)

            // Tab group label
            HStack(spacing: 6) {
                Text("\(tabManager.tabs.count) tabs")
                    .font(.system(size: 11.2, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xb9b9b9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: 0x4b4b4b)))
                Spacer()
            }
            .padding(.bottom, 10)

            // Tab list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 9) {
                    ForEach(filteredTabs) { tab in
                        panelTabCard(tab: tab)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .frame(minWidth: Edge.Sizes.panelMinWidth)
        .background(Edge.Colors.panelDark)
        .overlay(alignment: .leading) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1)
        }
    }

    private var filteredTabs: [Tab] {
        if panelSearch.isEmpty { return tabManager.tabs }
        return tabManager.tabs.filter {
            $0.title.localizedCaseInsensitiveContains(panelSearch) ||
            ($0.url?.absoluteString ?? "").localizedCaseInsensitiveContains(panelSearch)
        }
    }

    // MARK: - Tab Card

    private func panelTabCard(tab: Tab) -> some View {
        Button { tabManager.selectTab(tab) } label: {
            VStack(alignment: .leading, spacing: 7) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x667eea), Color(hex: 0x764ba2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(16.0 / 10.0, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.1))
                        )

                    // Globe placeholder
                    Image(systemName: "globe")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.3))
                }

                // Title + URL
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(.system(size: 10.9))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(tab.url?.host() ?? "New Tab")
                        .font(.system(size: 10.2))
                        .foregroundStyle(Color(hex: 0xb8b8b8))
                        .lineLimit(1)
                }
            }
            .padding(5.5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(tab.id == tabManager.selectedTabID ? Color(hex: 0x3b3b3b) : Color(hex: 0x343434))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tab.id == tabManager.selectedTabID ? Edge.Colors.tabPreviewActive : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 224)
    }
}
