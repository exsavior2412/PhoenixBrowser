import SwiftUI

enum DevToolsTab: String, CaseIterable {
    case console = "Console"
    case errors = "Errors"
    case network = "Network"
    case elements = "Elements"
}

struct DevToolsView: View {
    @ObservedObject var devTools: DevToolsManager
    @ObservedObject var tabManager: TabManager
    @Binding var isVisible: Bool
    @State private var activeTab: DevToolsTab = .console
    @State private var consoleInput = ""
    @State private var consoleFilter = ""
    @State private var networkFilter = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                ForEach(DevToolsTab.allCases, id: \.self) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: activeTab == tab ? .semibold : .regular))
                                .foregroundStyle(activeTab == tab ? .white : Color(hex: 0x9e9e9e))

                            // Badge for errors tab
                            if tab == .errors && errorCount > 0 {
                                Text("\(errorCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color(hex: 0xf44336)))
                            }
                            if tab == .console && warningCount > 0 {
                                Text("\(warningCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color(hex: 0xff9800)))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(activeTab == tab ? Color.white.opacity(0.1) : .clear)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Copy All
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: 0x9e9e9e))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let text: String
                        switch activeTab {
                        case .console:
                            text = devTools.consoleMessages.map { "[\($0.level.rawValue)] \($0.text)" }.joined(separator: "\n")
                        case .errors:
                            text = devTools.consoleMessages.filter { $0.level == .error || $0.level == .warn }
                                .map { "[\($0.level.rawValue)] \($0.text)" }.joined(separator: "\n")
                        case .network:
                            text = devTools.networkEntries.map { "\($0.method) \($0.url)" }.joined(separator: "\n")
                        case .elements:
                            text = devTools.consoleMessages.filter { $0.source == "__elements__" }.map(\.text).joined(separator: "\n")
                        }
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                    .help("Copy All")

                // Clear
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: 0x9e9e9e))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switch activeTab {
                        case .console: devTools.clearConsole()
                        case .errors: devTools.clearConsole()
                        case .network: devTools.clearNetwork()
                        case .elements: break
                        }
                    }
                    .help("Clear")

                // Close
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isVisible = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: 0x9e9e9e))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(Color(hex: 0x242424))

            Divider().background(Color.white.opacity(0.08))

            // Content
            switch activeTab {
            case .console:
                consoleView
            case .errors:
                errorsView
            case .network:
                networkView
            case .elements:
                elementsView
            }
        }
        .background(Color(hex: 0x1e1e1e))
    }

    // MARK: - Console

    private var consoleView: some View {
        VStack(spacing: 0) {
            // Filter
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: 0x888888))
                TextField("Filter", text: $consoleFilter)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color(hex: 0x2a2a2a))

            Divider().background(Color.white.opacity(0.06))

            // Messages
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredConsoleMessages) { msg in
                        consoleRow(msg)
                    }
                }
            }

            Divider().background(Color.white.opacity(0.06))

            // Input
            HStack(spacing: 6) {
                Text(">")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: 0x5da7ff))
                TextField("Execute JavaScript...", text: $consoleInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white)
                    .onSubmit {
                        executeJS(consoleInput)
                        consoleInput = ""
                    }
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Color(hex: 0x2a2a2a))
        }
    }

    // MARK: - Errors View

    private var errorCount: Int {
        devTools.consoleMessages.filter { $0.level == .error }.count
    }

    private var warningCount: Int {
        devTools.consoleMessages.filter { $0.level == .warn }.count
    }

    private var errorsView: some View {
        VStack(spacing: 0) {
            // Summary bar
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: 0xf48771))
                    Text("\(errorCount) errors")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0xf48771))
                }
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: 0xdba040))
                    Text("\(warningCount) warnings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: 0xdba040))
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background(Color(hex: 0x2a2a2a))

            Divider().background(Color.white.opacity(0.06))

            // Error + warning list
            if errorMessages.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: 0x4caf50))
                    Text("No errors")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0x888888))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(errorMessages) { msg in
                            errorRow(msg)
                        }
                    }
                }
            }
        }
    }

    private var errorMessages: [ConsoleMessage] {
        devTools.consoleMessages.filter { $0.level == .error || $0.level == .warn }
    }

    private func errorRow(_ msg: ConsoleMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: msg.level == .error ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(msg.level == .error ? Color(hex: 0xf48771) : Color(hex: 0xdba040))
                .frame(width: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(msg.text)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let source = msg.source, source != "__elements__" {
                    Text(source)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x5da7ff))
                        .lineLimit(1)
                }
            }

            // Copy
            Image(systemName: "doc.on.doc")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: 0x555555))
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
                .onTapGesture {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(msg.text, forType: .string)
                }

            Text(timeString(msg.timestamp))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color(hex: 0x666666))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(msg.level == .error ? Color.red.opacity(0.08) : Color.orange.opacity(0.06))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)
        }
    }

    // MARK: - Console Helpers

    private var filteredConsoleMessages: [ConsoleMessage] {
        if consoleFilter.isEmpty { return devTools.consoleMessages }
        return devTools.consoleMessages.filter {
            $0.text.localizedCaseInsensitiveContains(consoleFilter)
        }
    }

    private func consoleRow(_ msg: ConsoleMessage) -> some View {
        HStack(alignment: .top, spacing: 6) {
            // Level icon
            Image(systemName: msg.level == .error ? "xmark.circle.fill" :
                    msg.level == .warn ? "exclamationmark.triangle.fill" :
                    msg.level == .info ? "info.circle.fill" : "chevron.right")
                .font(.system(size: 9))
                .foregroundStyle(levelColor(msg.level))
                .frame(width: 14)

            // Text
            Text(msg.text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(levelColor(msg.level))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Copy button
            Image(systemName: "doc.on.doc")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: 0x555555))
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
                .onTapGesture {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(msg.text, forType: .string)
                }
                .help("Copy")

            // Timestamp
            Text(timeString(msg.timestamp))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color(hex: 0x666666))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(msg.level == .error ? Color.red.opacity(0.08) :
                        msg.level == .warn ? Color.orange.opacity(0.06) : .clear)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)
        }
    }

    private func levelColor(_ level: ConsoleMessage.Level) -> Color {
        switch level {
        case .log, .debug: return Color(hex: 0xd4d4d4)
        case .info: return Color(hex: 0x5da7ff)
        case .warn: return Color(hex: 0xdba040)
        case .error: return Color(hex: 0xf48771)
        }
    }

    private func executeJS(_ code: String) {
        guard !code.isEmpty, let webView = tabManager.selectedTab?.webView else { return }
        devTools.addConsoleMessage(level: "info", text: "> \(code)", source: nil)
        webView.evaluateJavaScript(code) { result, error in
            if let error {
                DevToolsManager.shared.addConsoleMessage(level: "error", text: error.localizedDescription, source: nil)
            } else if let result {
                DevToolsManager.shared.addConsoleMessage(level: "log", text: "\(result)", source: nil)
            } else {
                DevToolsManager.shared.addConsoleMessage(level: "log", text: "undefined", source: nil)
            }
        }
    }

    // MARK: - Network

    private var networkView: some View {
        VStack(spacing: 0) {
            // Filter
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: 0x888888))
                TextField("Filter URLs", text: $networkFilter)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(devTools.networkEntries.count) requests")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: 0x888888))
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color(hex: 0x2a2a2a))

            Divider().background(Color.white.opacity(0.06))

            // Header
            HStack(spacing: 0) {
                netHeader("URL", flex: true)
                netHeader("Type", width: 60)
                netHeader("Size", width: 60)
                netHeader("Time", width: 55)
            }
            .frame(height: 22)
            .background(Color(hex: 0x262626))

            Divider().background(Color.white.opacity(0.06))

            // Entries
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(filteredNetworkEntries) { entry in
                        networkRow(entry)
                    }
                }
            }
        }
    }

    private var filteredNetworkEntries: [NetworkEntry] {
        if networkFilter.isEmpty { return devTools.networkEntries }
        return devTools.networkEntries.filter {
            $0.url.localizedCaseInsensitiveContains(networkFilter)
        }
    }

    @ViewBuilder
    private func netHeader(_ title: String, width: CGFloat? = nil, flex: Bool = false) -> some View {
        if flex {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(hex: 0x999999))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
        } else {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(hex: 0x999999))
                .frame(width: width ?? 60, alignment: .leading)
                .padding(.horizontal, 6)
        }
    }

    private func networkRow(_ entry: NetworkEntry) -> some View {
        HStack(spacing: 0) {
            Text(shortURL(entry.url))
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Color(hex: 0xd4d4d4))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)

            Text(entry.mimeType ?? "-")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: 0x888888))
                .frame(width: 60, alignment: .leading)
                .padding(.horizontal, 6)

            Text(entry.size.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "-")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: 0x888888))
                .frame(width: 60, alignment: .trailing)
                .padding(.horizontal, 6)

            Text(entry.duration.map { String(format: "%.0fms", $0 * 1000) } ?? "-")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: 0x888888))
                .frame(width: 55, alignment: .trailing)
                .padding(.horizontal, 6)
        }
        .frame(height: 22)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)
        }
    }

    private func shortURL(_ url: String) -> String {
        if let u = URL(string: url) {
            return u.lastPathComponent.isEmpty ? (u.host() ?? url) : u.lastPathComponent
        }
        return url
    }

    // MARK: - Elements

    private var elementsView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    fetchDOM()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("Inspect DOM")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Color(hex: 0x5da7ff))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)

                Button {
                    getPageInfo()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("Page Info")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Color(hex: 0x5da7ff))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(8)

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(devTools.consoleMessages.filter { $0.source == "__elements__" }) { msg in
                        Text(msg.text)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color(hex: 0xd4d4d4))
                            .textSelection(.enabled)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private func fetchDOM() {
        let js = """
        (function() {
            const html = document.documentElement.outerHTML;
            const lines = html.substring(0, 3000);
            return lines;
        })();
        """
        tabManager.selectedTab?.webView.evaluateJavaScript(js) { result, error in
            if let html = result as? String {
                DevToolsManager.shared.addConsoleMessage(level: "log", text: html, source: "__elements__")
            }
        }
    }

    private func getPageInfo() {
        let js = """
        (function() {
            const info = {
                title: document.title,
                url: window.location.href,
                charset: document.characterSet,
                doctype: document.doctype ? document.doctype.name : 'none',
                scripts: document.scripts.length,
                stylesheets: document.styleSheets.length,
                images: document.images.length,
                links: document.links.length,
                forms: document.forms.length,
                cookies: document.cookie.split(';').filter(c => c.trim()).length,
                localStorage: Object.keys(localStorage).length,
                readyState: document.readyState
            };
            return JSON.stringify(info, null, 2);
        })();
        """
        tabManager.selectedTab?.webView.evaluateJavaScript(js) { result, error in
            if let json = result as? String {
                DevToolsManager.shared.addConsoleMessage(level: "info", text: json, source: "__elements__")
            }
        }
    }

    // MARK: - Helpers

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}
