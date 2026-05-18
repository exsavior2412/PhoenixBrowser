import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let tab: Tab
    let styleManager: StyleManager

    func makeNSView(context: Context) -> WKWebView {
        tab.webView.navigationDelegate = context.coordinator
        tab.webView.uiDelegate = context.coordinator
        return tab.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab, styleManager: styleManager)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let tab: Tab
        let styleManager: StyleManager
        let securityManager = SecurityManager.shared
        let permissionManager = PermissionManager.shared

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
