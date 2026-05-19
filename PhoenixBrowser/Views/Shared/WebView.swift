import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let tab: Tab
    let styleManager: StyleManager

    func makeNSView(context: Context) -> WKWebView {
        tab.webView.navigationDelegate = context.coordinator
        tab.webView.uiDelegate = context.coordinator

        // Swizzle WKWebView menu to add custom items
        ContextMenuInjector.inject(into: tab.webView)

        return tab.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab, styleManager: styleManager)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
        let tab: Tab
        let styleManager: StyleManager
        let securityManager = SecurityManager.shared
        let permissionManager = PermissionManager.shared
        let downloadManager = DownloadManager.shared

        private var activeDownloadID: UUID?
        private var downloadDestination: URL?

        init(tab: Tab, styleManager: StyleManager) {
            self.tab = tab
            self.styleManager = styleManager
        }

        // MARK: - Navigation Policy (Security Gate)

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let decision = securityManager.shouldAllowNavigation(to: url)

            switch decision {
            case .allow:
                decisionHandler(.allow)

            case .block(let reason):
                decisionHandler(.cancel)
                DispatchQueue.main.async {
                    self.tab.securityThreat = reason
                    self.tab.securityLevel = .dangerous
                }

            case .upgrade(let httpsURL):
                decisionHandler(.cancel)
                webView.load(URLRequest(url: httpsURL))

            case .warnHTTP:
                // Allow but flag as insecure
                DispatchQueue.main.async {
                    self.tab.securityLevel = .insecure
                    self.tab.securityThreat = .httpSite
                }
                decisionHandler(.allow)
            }
        }

        // MARK: - Certificate Error Handling

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            let protectionSpace = challenge.protectionSpace

            if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                guard let serverTrust = protectionSpace.serverTrust else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    DispatchQueue.main.async {
                        self.tab.securityLevel = .dangerous
                        self.tab.securityThreat = .certError
                    }
                    return
                }

                // Evaluate certificate
                var error: CFError?
                let isValid = SecTrustEvaluateWithError(serverTrust, &error)

                if isValid {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    DispatchQueue.main.async {
                        self.tab.securityLevel = .secure
                        self.tab.securityThreat = nil
                    }
                } else {
                    // Invalid certificate — block
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    DispatchQueue.main.async {
                        self.tab.securityLevel = .dangerous
                        self.tab.securityThreat = .certError
                    }
                }
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }

        // MARK: - Navigation Events

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            styleManager.injectStyles(into: webView, for: webView.url)
            DispatchQueue.main.async {
                self.tab.updateSecurityState()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.tab.securityThreat = nil
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            // Certificate error codes
            if nsError.domain == NSURLErrorDomain &&
               (nsError.code == NSURLErrorServerCertificateUntrusted ||
                nsError.code == NSURLErrorServerCertificateHasBadDate ||
                nsError.code == NSURLErrorServerCertificateHasUnknownRoot ||
                nsError.code == NSURLErrorServerCertificateNotYetValid) {
                DispatchQueue.main.async {
                    self.tab.securityLevel = .dangerous
                    self.tab.securityThreat = .certError
                }
            }
        }

        // MARK: - New Window (target="_blank")

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        // MARK: - Permission Requests

        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            let domain = origin.host
            let permType: PermissionType = type == .camera ? .camera : .microphone

            // Check saved decision
            if let saved = permissionManager.decision(for: domain, permission: permType) {
                decisionHandler(saved ? .grant : .deny)
                return
            }

            // Ask user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "\(domain) wants to use your \(permType.rawValue)"
                alert.informativeText = "Do you want to allow this website to access your \(permType.rawValue.lowercased())?"
                alert.addButton(withTitle: "Allow")
                alert.addButton(withTitle: "Don't Allow")
                alert.addButton(withTitle: "Always Allow")

                let response = alert.runModal()
                switch response {
                case .alertFirstButtonReturn:
                    decisionHandler(.grant)
                case .alertThirdButtonReturn:
                    self.permissionManager.grant(domain: domain, permission: permType)
                    decisionHandler(.grant)
                default:
                    self.permissionManager.deny(domain: domain, permission: permType)
                    decisionHandler(.deny)
                }
            }
        }

        // MARK: - Download Response Policy

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            if !navigationResponse.canShowMIMEType {
                decisionHandler(.download)
                return
            }

            // Check for attachment Content-Disposition
            if let response = navigationResponse.response as? HTTPURLResponse,
               let contentDisposition = response.value(forHTTPHeaderField: "Content-Disposition"),
               contentDisposition.lowercased().contains("attachment") {
                decisionHandler(.download)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
            download.delegate = self
        }

        func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
            download.delegate = self
        }

        // MARK: - WKDownloadDelegate

        func download(
            _ download: WKDownload,
            decideDestinationUsing response: URLResponse,
            suggestedFilename: String,
            completionHandler: @escaping (URL?) -> Void
        ) {
            let downloadsDir = downloadManager.downloadDirectory
            var destination = downloadsDir.appendingPathComponent(suggestedFilename)

            // Avoid overwriting: add (1), (2)... if file exists
            var counter = 1
            let name = destination.deletingPathExtension().lastPathComponent
            let ext = destination.pathExtension
            while FileManager.default.fileExists(atPath: destination.path) {
                let newName = ext.isEmpty ? "\(name) (\(counter))" : "\(name) (\(counter)).\(ext)"
                destination = downloadsDir.appendingPathComponent(newName)
                counter += 1
            }

            downloadDestination = destination
            activeDownloadID = downloadManager.addDownload(
                filename: destination.lastPathComponent,
                url: download.originalRequest?.url ?? URL(string: "about:blank")!,
                destination: destination
            )

            completionHandler(destination)
        }

        func download(_ download: WKDownload, didReceive data: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            guard let id = activeDownloadID else { return }
            DispatchQueue.main.async {
                self.downloadManager.updateProgress(id: id, bytesReceived: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
            }
        }

        func downloadDidFinish(_ download: WKDownload) {
            guard let id = activeDownloadID else { return }
            DispatchQueue.main.async {
                self.downloadManager.completeDownload(id: id)
            }
            activeDownloadID = nil
        }

        func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
            guard let id = activeDownloadID else { return }
            DispatchQueue.main.async {
                self.downloadManager.failDownload(id: id, error: error.localizedDescription)
            }
            activeDownloadID = nil
        }

        // MARK: - JS Dialogs

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = NSAlert()
            alert.messageText = frame.securityOrigin.host
            alert.informativeText = message
            alert.runModal()
            completionHandler()
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = NSAlert()
            alert.messageText = frame.securityOrigin.host
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            completionHandler(alert.runModal() == .alertFirstButtonReturn)
        }
    }
}

// MARK: - Context Menu Injector (adds items to WKWebView's native menu)

enum ContextMenuInjector {
    private static var injectedWebViews = Set<ObjectIdentifier>()

    static func inject(into webView: WKWebView) {
        let id = ObjectIdentifier(webView)
        guard !injectedWebViews.contains(id) else { return }
        injectedWebViews.insert(id)

        // Use NSView willOpenMenu notification via delegate
        let helper = ContextMenuHelper(webView: webView)
        objc_setAssociatedObject(webView, &ContextMenuHelper.key, helper, .OBJC_ASSOCIATION_RETAIN)
    }
}

private final class ContextMenuHelper: NSObject {
    static var key: UInt8 = 0
    let webView: WKWebView
    var monitor: Any?

    init(webView: WKWebView) {
        self.webView = webView
        super.init()

        // Monitor right-click to modify menu after WKWebView creates it
        monitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self = self,
                  let window = self.webView.window,
                  event.window == window else { return event }

            // Check click is inside webview
            let loc = self.webView.convert(event.locationInWindow, from: nil)
            guard self.webView.bounds.contains(loc) else { return event }

            // Delay to let WKWebView build its menu, then modify
            DispatchQueue.main.async {
                self.modifyMenu()
            }
            return event
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }

    private func modifyMenu() {
        // Find the NSMenu currently displayed (WKWebView sets it on its internal view)
        guard let contentView = findWKContentView(in: webView) else { return }
        guard let menu = contentView.menu else { return }

        // Add separator + our items at the end
        menu.addItem(.separator())

        addItem(to: menu, title: "Copy Page URL", action: #selector(copyPageURL))
        addItem(to: menu, title: "View Page Source", action: #selector(viewSource))
        addItem(to: menu, title: "Inspect Element", action: #selector(inspectElement))

        menu.addItem(.separator())
        addItem(to: menu, title: "Save Page As...", action: #selector(savePageAs))
        addItem(to: menu, title: "Print...", action: #selector(printPage))
    }

    private func addItem(to menu: NSMenu, title: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    private func findWKContentView(in view: NSView) -> NSView? {
        for sub in view.subviews {
            if String(describing: type(of: sub)).contains("WKContentView") ||
               String(describing: type(of: sub)).contains("WKWebView") {
                if sub.menu != nil { return sub }
            }
            if let found = findWKContentView(in: sub) { return found }
        }
        return nil
    }

    @objc func copyPageURL() {
        guard let url = webView.url?.absoluteString else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
    }

    @objc func viewSource() {
        webView.evaluateJavaScript("document.documentElement.outerHTML") { result, _ in
            guard let html = result as? String else { return }
            DispatchQueue.main.async {
                let panel = NSPanel(
                    contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                    styleMask: [.titled, .closable, .resizable],
                    backing: .buffered, defer: false
                )
                panel.title = "View Source — \(self.webView.url?.host() ?? "")"
                let scroll = NSScrollView(frame: panel.contentView!.bounds)
                scroll.autoresizingMask = [.width, .height]
                scroll.hasVerticalScroller = true
                let tv = NSTextView(frame: scroll.bounds)
                tv.isEditable = false
                tv.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
                tv.string = html
                tv.textColor = .labelColor
                scroll.documentView = tv
                panel.contentView = scroll
                panel.center()
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }

    @objc func inspectElement() {
        NotificationCenter.default.post(name: .toggleDevTools, object: nil)
    }

    @objc func savePageAs() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = webView.title ?? "page"
        panel.allowedContentTypes = [.html]
        panel.beginSheetModal(for: webView.window!) { response in
            guard response == .OK, let dest = panel.url else { return }
            self.webView.evaluateJavaScript("document.documentElement.outerHTML") { result, _ in
                if let html = result as? String {
                    try? html.write(to: dest, atomically: true, encoding: .utf8)
                }
            }
        }
    }

    @objc func printPage() {
        webView.printOperation(with: .shared).run()
    }
}
