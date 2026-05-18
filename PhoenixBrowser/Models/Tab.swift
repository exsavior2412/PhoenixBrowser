import Foundation
import WebKit

final class Tab: Identifiable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var url: URL?
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var estimatedProgress: Double = 0
    @Published var favicon: NSImage?
    @Published var securityLevel: SecurityLevel = .unknown
    @Published var securityThreat: SecurityThreat?
    @Published var isPrivate: Bool

    let webView: WKWebView

    init(url: URL? = nil, isPrivate: Bool = false, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        self.id = UUID()
        self.title = isPrivate ? "Private Tab" : "New Tab"
        self.url = url
        self.isPrivate = isPrivate

        configuration.preferences.isElementFullscreenEnabled = true
        configuration.allowsInlinePredictions = true

        // Private browsing: non-persistent data store
        if isPrivate {
            configuration.websiteDataStore = .nonPersistent()
        }

        // Apply enhanced content blocking
        let securityManager = SecurityManager.shared
        Task {
            do {
                let ruleList = try await WKContentRuleListStore.default()
                    .compileContentRuleList(
                        forIdentifier: "PhoenixSecurity",
                        encodedContentRuleList: securityManager.enhancedBlockingRules
                    )
                if let ruleList {
                    await MainActor.run {
                        configuration.userContentController.add(ruleList)
                    }
                }
            } catch {
                print("SecurityRules: Failed to compile: \(error)")
            }
        }

        // Inject anti-fingerprint script
        if securityManager.antiFingerprint {
            let script = WKUserScript(
                source: securityManager.antiFingerprintScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            configuration.userContentController.addUserScript(script)
        }

        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.allowsMagnification = true

        // Use Safari's User-Agent so websites serve modern UI
        self.webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"

        if let url {
            self.webView.load(URLRequest(url: url))
        }
    }

    func updateSecurityState() {
        let manager = SecurityManager.shared
        securityLevel = manager.securityLevel(for: url)
        securityThreat = manager.checkURL(url ?? URL(string: "about:blank")!)
    }
}
