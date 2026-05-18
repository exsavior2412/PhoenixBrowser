import SwiftUI

struct TabItemView: View {
    @ObservedObject var tab: Tab
    let isActive: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 7) {
                ZStack {
                    if tab.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.5)
                    } else if let favicon = tab.favicon {
                        Image(nsImage: favicon)
                            .resizable()
                            .frame(width: 14, height: 14)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                            .foregroundStyle(Edge.Colors.iconColor)
                    }
                }
                .frame(width: 16, height: 16)

                Text(tab.title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Edge.Colors.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isActive || isHovered {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(Edge.Colors.iconColor.opacity(0.6))
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 7)
            .frame(height: Edge.Sizes.tabHeight)
            .frame(minWidth: Edge.Sizes.tabMinWidth, maxWidth: Edge.Sizes.tabMaxWidth)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 8)
                    .fill(isActive ? Color.white.opacity(0.86) : (isHovered ? Color.white.opacity(0.52) : Color.white.opacity(0.42)))
            )
            .overlay(
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 8)
                    .stroke(Color(hex: 0x817052, alpha: 0.38), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
