import XCTest
@testable import PhoenixBrowser

final class SecurityAdvancedTests: XCTestCase {

    var sm: SecurityManager!

    override func setUp() {
        super.setUp()
        sm = SecurityManager.shared
    }

    // MARK: - Edge Cases: URL Parsing

    func testBlockedDomain_caseInsensitive() {
        sm.addBlockedDomain("EVIL-UPPER.COM")
        let url = URL(string: "https://evil-upper.com")!
        XCTAssertTrue(sm.isBlockedDomain(url))
    }

    func testBlockedDomain_withPort() {
        sm.addBlockedDomain("evil-port.com")
        let url = URL(string: "https://evil-port.com:8080/path")!
        XCTAssertTrue(sm.isBlockedDomain(url))
    }

    func testBlockedDomain_withPath() {
        let url = URL(string: "https://login-microsoftonline.com/oauth/login?redirect=evil")!
        XCTAssertTrue(sm.isBlockedDomain(url))
    }

    func testBlockedDomain_deepSubdomain() {
        sm.addBlockedDomain("phish.com")
        let url = URL(string: "https://a.b.c.phish.com")!
        XCTAssertTrue(sm.isBlockedDomain(url))
    }

    func testBlockedDomain_partialMatch_shouldNotBlock() {
        // "paypal.com" is NOT in blocklist, only "secure-paypal-login.com"
        let url = URL(string: "https://paypal.com.evil.com")!
        // This should NOT match "secure-paypal-login.com"
        XCTAssertFalse(sm.isBlockedDomain(url))
    }

    func testSecurityLevel_fileScheme() {
        let url = URL(string: "file:///tmp/test.html")!
        XCTAssertEqual(sm.securityLevel(for: url), .unknown)
    }

    func testSecurityLevel_aboutBlank() {
        let url = URL(string: "about:blank")!
        XCTAssertEqual(sm.securityLevel(for: url), .unknown)
    }

    func testSecurityLevel_dataScheme() {
        let url = URL(string: "data:text/html,<h1>test</h1>")!
        XCTAssertEqual(sm.securityLevel(for: url), .unknown)
    }

    // MARK: - HTTPS Upgrade Edge Cases

    func testHTTPSUpgrade_withFragment() {
        sm.httpsOnlyMode = true
        let url = URL(string: "http://example.com/page#section")!
        let upgraded = sm.upgradeToHTTPS(url)
        XCTAssertEqual(upgraded?.scheme, "https")
        XCTAssertTrue(upgraded?.absoluteString.contains("#section") == true)
    }

    func testHTTPSUpgrade_withAuth() {
        sm.httpsOnlyMode = true
        let url = URL(string: "http://user:pass@example.com")!
        let upgraded = sm.upgradeToHTTPS(url)
        XCTAssertEqual(upgraded?.scheme, "https")
    }

    func testHTTPSUpgrade_ftpScheme_ignored() {
        sm.httpsOnlyMode = true
        let url = URL(string: "ftp://files.example.com")!
        let upgraded = sm.upgradeToHTTPS(url)
        XCTAssertNil(upgraded, "Should not upgrade non-HTTP schemes")
    }

    // MARK: - Navigation Decision Edge Cases

    func testNavDecision_blockedDomainWithHTTP() {
        sm.httpsOnlyMode = true
        sm.addBlockedDomain("double-threat.com")
        let url = URL(string: "http://double-threat.com")!
        // Blocklist should take priority over HTTPS upgrade
        if case .block(let reason) = sm.shouldAllowNavigation(to: url) {
            XCTAssertEqual(reason, .phishing)
        } else {
            XCTFail("Blocklist should take priority over HTTPS upgrade")
        }
    }

    func testNavDecision_blockedSubdomain() {
        sm.addBlockedDomain("blocked-sub.com")
        let url = URL(string: "https://www.blocked-sub.com/login")!
        if case .block = sm.shouldAllowNavigation(to: url) {
            // pass
        } else {
            XCTFail("Subdomain of blocked domain should be blocked")
        }
    }

    // MARK: - Anti-Fingerprint Script Validation

    func testAntiFingerprintScript_isValidJS() {
        sm.antiFingerprint = true
        let script = sm.antiFingerprintScript
        // Check it's a self-invoking function
        XCTAssertTrue(script.contains("(function()"))
        XCTAssertTrue(script.contains("})();"))
        // Check key protections
        XCTAssertTrue(script.contains("HTMLCanvasElement"))
        XCTAssertTrue(script.contains("WebGLRenderingContext"))
        XCTAssertTrue(script.contains("getBattery"))
        XCTAssertTrue(script.contains("deviceMemory"))
        XCTAssertTrue(script.contains("maxTouchPoints"))
    }

    func testAntiFingerprintScript_normalizesValues() {
        sm.antiFingerprint = true
        let script = sm.antiFingerprintScript
        XCTAssertTrue(script.contains("1920"))   // normalized width
        XCTAssertTrue(script.contains("1080"))   // normalized height
        XCTAssertTrue(script.contains("24"))     // color depth
    }

    // MARK: - Content Rules Validation

    func testBlockingRules_allHaveRequiredFields() throws {
        let data = sm.enhancedBlockingRules.data(using: .utf8)!
        let rules = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]

        for (index, rule) in rules.enumerated() {
            XCTAssertNotNil(rule["trigger"], "Rule \(index) missing trigger")
            XCTAssertNotNil(rule["action"], "Rule \(index) missing action")

            let trigger = rule["trigger"] as! [String: Any]
            XCTAssertNotNil(trigger["url-filter"], "Rule \(index) missing url-filter")

            let action = rule["action"] as! [String: Any]
            XCTAssertEqual(action["type"] as? String, "block", "Rule \(index) action should be 'block'")
        }
    }

    func testBlockingRules_count() throws {
        let data = sm.enhancedBlockingRules.data(using: .utf8)!
        let rules = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        XCTAssertGreaterThanOrEqual(rules.count, 25, "Should have at least 25 blocking rules")
    }

    // MARK: - Settings Persistence

    func testHTTPSOnlyMode_togglePersists() {
        sm.httpsOnlyMode = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "phoenix_https_only"))
        sm.httpsOnlyMode = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "phoenix_https_only"))
    }

    func testAntiFingerprint_togglePersists() {
        sm.antiFingerprint = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "phoenix_anti_fingerprint"))
        sm.antiFingerprint = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "phoenix_anti_fingerprint"))
    }

    // MARK: - Permission Manager Advanced

    func testPermission_overwriteDecision() {
        let pm = PermissionManager.shared
        pm.grant(domain: "overwrite.com", permission: .camera)
        XCTAssertEqual(pm.decision(for: "overwrite.com", permission: .camera), true)
        pm.deny(domain: "overwrite.com", permission: .camera)
        XCTAssertEqual(pm.decision(for: "overwrite.com", permission: .camera), false)
        pm.reset(domain: "overwrite.com")
    }

    func testPermission_multipleDomainsIsolated() {
        let pm = PermissionManager.shared
        pm.grant(domain: "a.com", permission: .camera)
        pm.deny(domain: "b.com", permission: .camera)
        XCTAssertEqual(pm.decision(for: "a.com", permission: .camera), true)
        XCTAssertEqual(pm.decision(for: "b.com", permission: .camera), false)
        XCTAssertNil(pm.decision(for: "c.com", permission: .camera))
        pm.reset(domain: "a.com")
        pm.reset(domain: "b.com")
    }

    func testPermission_differentTypesIndependent() {
        let pm = PermissionManager.shared
        pm.grant(domain: "mixed.com", permission: .camera)
        pm.deny(domain: "mixed.com", permission: .microphone)
        XCTAssertEqual(pm.decision(for: "mixed.com", permission: .camera), true)
        XCTAssertEqual(pm.decision(for: "mixed.com", permission: .microphone), false)
        pm.reset(domain: "mixed.com")
    }

    // MARK: - Tab Security State

    func testTab_defaultSecurityLevel() {
        let tab = Tab()
        XCTAssertEqual(tab.securityLevel, .unknown)
        XCTAssertNil(tab.securityThreat)
    }

    func testTab_privateTab_isPrivate() {
        let tab = Tab(isPrivate: true)
        XCTAssertTrue(tab.isPrivate)
        XCTAssertEqual(tab.title, "Private Tab")
    }

    func testTab_regularTab_notPrivate() {
        let tab = Tab()
        XCTAssertFalse(tab.isPrivate)
        XCTAssertEqual(tab.title, "New Tab")
    }

    func testTab_updateSecurityState_https() {
        let tab = Tab(url: URL(string: "https://secure.com"))
        tab.url = URL(string: "https://secure.com") // simulate navigation
        tab.updateSecurityState()
        XCTAssertEqual(tab.securityLevel, .secure)
    }

    func testTab_updateSecurityState_http() {
        let tab = Tab()
        tab.url = URL(string: "http://insecure.com")
        tab.updateSecurityState()
        XCTAssertEqual(tab.securityLevel, .insecure)
    }

    func testTab_updateSecurityState_blocked() {
        let tab = Tab()
        tab.url = URL(string: "https://login-microsoftonline.com")
        tab.updateSecurityState()
        XCTAssertEqual(tab.securityLevel, .dangerous)
        XCTAssertEqual(tab.securityThreat, .phishing)
    }

    func testTab_userAgent() {
        let tab = Tab()
        XCTAssertTrue(tab.webView.customUserAgent?.contains("Safari") == true)
        XCTAssertTrue(tab.webView.customUserAgent?.contains("Version/18.0") == true)
    }
}
