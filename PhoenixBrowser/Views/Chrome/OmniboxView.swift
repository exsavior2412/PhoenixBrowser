import SwiftUI
import AppKit

struct AddressBarView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @Binding var panelVisible: Bool
    @FocusState.Binding var isOmniboxFocused: Bool
    @State private var isOmniboxHovered = false
    @State private var showDownloads = false
    @StateObject private var downloadManager = DownloadManager.shared

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
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: Edge.Sizes.iconSize, weight: .medium))
                    .foregroundStyle(Edge.Colors.iconColor)
                    .frame(width: Edge.Sizes.iconBtnSize, height: Edge.Sizes.iconBtnSize)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showDownloads.toggle()
                    }
                    .popover(isPresented: $showDownloads, arrowEdge: .bottom) {
                        DownloadsPopover(downloadManager: downloadManager)
                            .frame(width: 300, height: 200)
                    }
                Image(systemName: "hammer.fill")
                    .font(.system(size: Edge.Sizes.iconSize, weight: .medium))
                    .foregroundStyle(Edge.Colors.iconColor)
                    .frame(width: Edge.Sizes.iconBtnSize, height: Edge.Sizes.iconBtnSize)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NotificationCenter.default.post(name: .toggleDevTools, object: nil)
                    }
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

            OmniboxTextField(
                text: $tabManager.addressText,
                displayText: displayURL,
                isFocused: $isOmniboxFocused,
                onSubmit: {
                    tabManager.navigate(to: tabManager.addressText)
                }
            )

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
            ProgressBarView(
                isLoading: tabManager.selectedTab?.isLoading == true,
                progress: tabManager.selectedTab?.estimatedProgress ?? 0
            )
            .offset(y: 2)
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

// MARK: - Native NSTextField wrapper for proper focus control

struct OmniboxTextField: NSViewRepresentable {
    @Binding var text: String
    var displayText: String
    var isFocused: FocusState<Bool>.Binding
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.font = .systemFont(ofSize: 12.2)
        field.textColor = .init(hex: 0x222222)
        field.placeholderString = "Search or enter address"
        field.focusRingType = .none
        field.lineBreakMode = .byTruncatingTail
        field.cell?.truncatesLastVisibleLine = true
        field.delegate = context.coordinator
        field.stringValue = displayText
        field.textColor = NSColor(Edge.Colors.textSecondary)

        // Global click monitor: resign when clicking outside omnibox
        context.coordinator.mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak field] event in
            guard let field = field, let window = field.window else { return event }
            let isEditing = window.firstResponder == field.currentEditor()
            guard isEditing else { return event }

            // Check if click is inside the text field
            let locationInField = field.convert(event.locationInWindow, from: nil)
            if !field.bounds.contains(locationInField) {
                // Click outside — resign
                window.makeFirstResponder(nil)
            }
            return event
        }

        return field
    }

    static func dismantleNSView(_ nsView: NSTextField, coordinator: Coordinator) {
        if let monitor = coordinator.mouseMonitor {
            NSEvent.removeMonitor(monitor)
            coordinator.mouseMonitor = nil
        }
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        let isEditing = field.window?.firstResponder == field.currentEditor()

        if !isEditing {
            // Display mode: show domain only
            field.stringValue = displayText
            field.textColor = NSColor(Edge.Colors.textSecondary)
        }

        // Handle programmatic focus request (Cmd+T, click +)
        if isFocused.wrappedValue && !isEditing {
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
                field.stringValue = self.text
                field.textColor = .init(hex: 0x222222)
                field.selectText(nil)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: OmniboxTextField
        var mouseMonitor: Any?

        init(_ parent: OmniboxTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                // Resign focus after submit
                DispatchQueue.main.async {
                    control.window?.makeFirstResponder(nil)
                    self.parent.isFocused.wrappedValue = false
                }
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                // Escape: resign focus
                DispatchQueue.main.async {
                    control.window?.makeFirstResponder(nil)
                    self.parent.isFocused.wrappedValue = false
                }
                return true
            }
            return false
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.isFocused.wrappedValue = true
            // Show full URL on begin edit
            if let field = obj.object as? NSTextField {
                field.stringValue = parent.text
                field.textColor = .init(hex: 0x222222)
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            parent.isFocused.wrappedValue = false
            // Show display text on end edit
            if let field = obj.object as? NSTextField {
                field.stringValue = parent.displayText
                field.textColor = NSColor(Edge.Colors.textSecondary)
            }
        }
    }
}

// MARK: - NSColor hex helper

private extension NSColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}
