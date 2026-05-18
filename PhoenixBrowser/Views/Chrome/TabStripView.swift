import SwiftUI

struct TabStripView: View {
    @ObservedObject var tabManager: TabManager
    @State private var hoveredTabID: UUID?

    var body: some View {
        HStack(spacing: 6) {
            Color.clear.frame(width: 68, height: Edge.Sizes.tabRowHeight)

            chromeIconBtn("sidebar.left") {}

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(tabManager.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == tabManager.selectedTabID,
                            isHovered: hoveredTabID == tab.id,
                            onSelect: { tabManager.selectTab(tab) },
                            onClose: {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    tabManager.closeTab(tab)
                                }
                            }
                        )
                        .onHover { h in hoveredTabID = h ? tab.id : nil }
                    }

                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            _ = tabManager.addNewTab()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Edge.Colors.iconColor)
                            .frame(width: Edge.Sizes.tabHeight, height: Edge.Sizes.tabHeight)
                            .background(Color.white.opacity(0.001))
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
            .frame(height: Edge.Sizes.tabRowHeight)
        }
        .frame(height: Edge.Sizes.tabRowHeight)
        .padding(.horizontal, 8)
    }
}
