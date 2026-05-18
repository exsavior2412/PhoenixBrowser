import SwiftUI

func chromeIconBtn(_ icon: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: icon)
            .font(.system(size: Edge.Sizes.iconSize, weight: .medium))
            .foregroundStyle(Edge.Colors.iconColor)
            .frame(width: Edge.Sizes.iconBtnSize, height: Edge.Sizes.iconBtnSize)
            .background(Color.white.opacity(0.001))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .opacity(enabled ? 1 : 0.35)
}
