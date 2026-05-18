import SwiftUI

enum Edge {
    // MARK: - Colors
    enum Colors {
        static let chromeMain = Color(hex: 0xd7c6ac)
        static let chromeDark = Color(hex: 0xcbb796)
        static let chromeBorder = Color(hex: 0xb9a789)
        static let textPrimary = Color(hex: 0x1f2933)
        static let textSecondary = Color(hex: 0x6d6459)
        static let accentBlue = Color(hex: 0x1b73e8)
        static let panelDark = Color(hex: 0x292929)
        static let panelDarker = Color(hex: 0x1f1f1f)
        static let omniboxBorder = Color(hex: 0x7d67f2)
        static let iconColor = Color(hex: 0x4f514f)
        static let favText = Color(hex: 0x514d46)
        static let railBg = Color(hex: 0x5d6b6f)
        static let ntpBg = Color(hex: 0x83959b)
        static let profileBlue = Color(hex: 0x5c87ff)
        static let panelActiveBlue = Color(hex: 0x5da7ff)
        static let tabPreviewActive = Color(hex: 0x6bb3ff)
    }

    // MARK: - Sizes
    enum Sizes {
        static let chromeHeight: CGFloat = 91  // ~5.7rem
        static let tabRowHeight: CGFloat = 34  // 2.125rem
        static let addressRowHeight: CGFloat = 32 // 2rem
        static let favoritesRowHeight: CGFloat = 25 // 1.55rem
        static let tabHeight: CGFloat = 30 // 1.85rem
        static let tabMaxWidth: CGFloat = 288 // 18rem
        static let tabMinWidth: CGFloat = 176 // 11rem
        static let iconBtnSize: CGFloat = 28 // 1.75rem
        static let iconSize: CGFloat = 16 // 1rem
        static let omniboxHeight: CGFloat = 25 // 1.55rem
        static let railWidth: CGFloat = 42 // 2.6rem
        static let panelMinWidth: CGFloat = 320 // 20rem
    }
}
