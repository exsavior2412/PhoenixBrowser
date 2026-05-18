import SwiftUI

struct EdgeLeftRailView: View {
    @Binding var panelVisible: Bool
    @State private var activeRailItem = "search"

    private let topItems: [(id: String, icon: String)] = [
        ("search", "magnifyingglass"),
        ("copilot", "sparkles"),
        ("compose", "square.and.pencil"),
    ]

    private let bottomItems: [(id: String, icon: String)] = [
        ("tools", "wrench.and.screwdriver"),
        ("games", "gamecontroller"),
        ("settings", "gearshape"),
    ]

    var body: some View {
        VStack(spacing: 5.5) {
            // Top icons
            ForEach(topItems, id: \.id) { item in
                railButton(item.icon, isActive: activeRailItem == item.id) {
                    activeRailItem = item.id
                }
            }

            Spacer()

            // Bottom icons
            ForEach(bottomItems, id: \.id) { item in
                railButton(item.icon, isActive: activeRailItem == item.id) {
                    activeRailItem = item.id
                }
            }
        }
        .padding(.vertical, 9)
        .frame(width: Edge.Sizes.railWidth)
        .frame(maxHeight: .infinity)
        .background(Edge.Colors.railBg)
    }

    private func railButton(_ icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: Edge.Sizes.iconSize, weight: .medium))
                .foregroundStyle(.white.opacity(0.84))
                .frame(width: Edge.Sizes.iconBtnSize, height: Edge.Sizes.iconBtnSize)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isActive ? Color.white.opacity(0.16) : .clear)
                )
        }
        .buttonStyle(.plain)
    }
}
