import Foundation
import WebKit

final class SecurityManager: ObservableObject {
    static let shared = SecurityManager()

    @Published var httpsOnlyMode: Bool {
        didSet { UserDefaults.standard.set(httpsOnlyMode, forKey: "phoenix_https_only") }
    }
    @Published var blockThirdPartyCookies: Bool {
        didSet { UserDefaults.standard.set(blockThirdPartyCookies, forKey: "phoenix_block_3p_cookies") }
    }
    @Published var antiFingerprint: Bool {
        didSet { UserDefaults.standard.set(antiFingerprint, forKey: "phoenix_anti_fingerprint") }
    }
    @Published var blockPopups: Bool {
        didSet { UserDefaults.standard.set(blockPopups, forKey: "phoenix_block_popups") }
    }

    let blocklist = URLBlocklist()

    init() {
        self.httpsOnlyMode = UserDefaults.standard.bool(forKey: "phoenix_https_only")
        self.blockThirdPartyCookies = UserDefaults.standard.bool(forKey: "phoenix_block_3p_cookies")
        self.antiFingerprint = UserDefaults.standard.bool(forKey: "phoenix_anti_fingerprint")
        self.blockPopups = UserDefaults.standard.bool(forKey: "phoenix_block_popups")

        if !UserDefaults.standard.bool(forKey: "phoenix_security_initialized") {
            httpsOnlyMode = true
            blockThirdPartyCookies = true
            antiFingerprint = true
            blockPopups = true
            UserDefaults.standard.set(true, forKey: "phoenix_security_initialized")
        }
    }

    // MARK: - Delegates to micro services

    func securityLevel(for url: URL?) -> SecurityLevel {
        guard let url else { return .unknown }
        if isBlockedDomain(url) { return .dangerous }
        if url.scheme == "https" { return .secure }
        if url.scheme == "http" { return .insecure }
        return .unknown
    }

    func checkURL(_ url: URL) -> SecurityThreat? {
        if isBlockedDomain(url) { return .phishing }
        if url.scheme == "http" { return .httpSite }
        return nil
    }

    func isBlockedDomain(_ url: URL) -> Bool {
        blocklist.isBlocked(url)
    }

    func addBlockedDomain(_ domain: String) {
        blocklist.add(domain)
    }

    func upgradeToHTTPS(_ url: URL) -> URL? {
        guard httpsOnlyMode else { return nil }
        return HTTPSUpgrader.upgrade(url)
    }

    func shouldAllowNavigation(to url: URL) -> NavigationDecision {
        if isBlockedDomain(url) { return .block(reason: .phishing) }
        if httpsOnlyMode, url.scheme == "http" {
            if let httpsURL = upgradeToHTTPS(url) { return .upgrade(to: httpsURL) }
            return .warnHTTP
        }
        return .allow
    }

    func containsXSSPayload(_ input: String) -> Bool {
        XSSDetector.containsPayload(input)
    }

    func isHomographAttack(_ url: URL) -> Bool {
        HomographDetector.isAttack(url)
    }

    func isSuspiciousURL(_ url: URL) -> Bool {
        URLInspector.isSuspicious(url)
    }

    func isMaliciousDataURI(_ url: URL) -> Bool {
        URLInspector.isMaliciousDataURI(url)
    }

    var antiFingerprintScript: String {
        guard antiFingerprint else { return "" }
        return FingerprintProtection.script
    }

    var enhancedBlockingRules: String {
        ContentBlockingRules.json
    }

    func fullSecurityCheck(for url: URL) -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        if isBlockedDomain(url) { threats.append(.phishing) }
        if url.scheme == "http" { threats.append(.httpSite) }
        if isHomographAttack(url) { threats.append(.phishing) }
        if isSuspiciousURL(url) { threats.append(.unwanted) }
        if isMaliciousDataURI(url) { threats.append(.malware) }
        if containsXSSPayload(url.absoluteString) { threats.append(.malware) }
        return threats
    }
}
