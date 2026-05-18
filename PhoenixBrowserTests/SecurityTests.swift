import XCTest
@testable import PhoenixBrowser

final class SecurityTests: XCTestCase {

    var securityManager: SecurityManager!

    override func setUp() {
        super.setUp()
        securityManager = SecurityManager.shared
    }

    // MARK: - 1. HTTPS Upgrade

    func testHTTPSUpgrade_httpToHTTPS() {
        securityManager.httpsOnlyMode = true
        let httpURL = URL(string: "http://example.com")!
        let upgraded = securityManager.upgradeToHTTPS(httpURL)
        XCTAssertEqual(upgraded?.scheme, "https")
        XCTAssertEqual(upgraded?.host(), "example.com")
    }

    func testHTTPSUpgrade_alreadyHTTPS() {
        securityManager.httpsOnlyMode = true
        let httpsURL = URL(string: "https://example.com")!
        let upgraded = securityManager.upgradeToHTTPS(httpsURL)
        XCTAssertNil(upgraded, "Already HTTPS should return nil (no upgrade needed)")
    }

    func testHTTPSUpgrade_disabledMode() {
        securityManager.httpsOnlyMode = false
        let httpURL = URL(string: "http://example.com")!
        let upgraded = securityManager.upgradeToHTTPS(httpURL)
        XCTAssertNil(upgraded, "Should not upgrade when HTTPS-only is disabled")
    }

    func testHTTPSUpgrade_preservesPath() {
        securityManager.httpsOnlyMode = true
        let url = URL(string: "http://example.com/path/to/page?q=test&lang=en")!
        let upgraded = securityManager.upgradeToHTTPS(url)
        XCTAssertEqual(upgraded?.absoluteString, "https://example.com/path/to/page?q=test&lang=en")
    }

    // MARK: - 2. Security Level Detection

    func testSecurityLevel_HTTPS() {
        let url = URL(string: "https://google.com")!
        XCTAssertEqual(securityManager.securityLevel(for: url), .secure)
    }

    func testSecurityLevel_HTTP() {
        let url = URL(string: "http://example.com")!
        XCTAssertEqual(securityManager.securityLevel(for: url), .insecure)
    }

    func testSecurityLevel_blockedDomain() {
        let url = URL(string: "https://login-microsoftonline.com")!
        XCTAssertEqual(securityManager.securityLevel(for: url), .dangerous)
    }

    func testSecurityLevel_nil() {
        XCTAssertEqual(securityManager.securityLevel(for: nil), .unknown)
    }

    // MARK: - 3. Blocklist / Phishing Detection

    func testBlockedDomain_exact() {
        let url = URL(string: "https://secure-paypal-login.com/login")!
        XCTAssertTrue(securityManager.isBlockedDomain(url))
    }

    func testBlockedDomain_subdomain() {
        let url = URL(string: "https://www.apple-id-verify.com")!
        XCTAssertTrue(securityManager.isBlockedDomain(url))
    }

    func testBlockedDomain_safe() {
        let url = URL(string: "https://www.google.com")!
        XCTAssertFalse(securityManager.isBlockedDomain(url))
    }

    func testBlockedDomain_safeSimilar() {
        // Real PayPal should NOT be blocked
        let url = URL(string: "https://www.paypal.com")!
        XCTAssertFalse(securityManager.isBlockedDomain(url))
    }

    func testAddBlockedDomain() {
        securityManager.addBlockedDomain("evil-site.com")
        let url = URL(string: "https://evil-site.com")!
        XCTAssertTrue(securityManager.isBlockedDomain(url))
    }

    // MARK: - 4. Navigation Decision

    func testNavDecision_allowHTTPS() {
        securityManager.httpsOnlyMode = true
        let url = URL(string: "https://google.com")!
        if case .allow = securityManager.shouldAllowNavigation(to: url) {
            // pass
        } else {
            XCTFail("HTTPS should be allowed")
        }
    }

    func testNavDecision_upgradeHTTP() {
        securityManager.httpsOnlyMode = true
        let url = URL(string: "http://example.com")!
        if case .upgrade(let httpsURL) = securityManager.shouldAllowNavigation(to: url) {
            XCTAssertEqual(httpsURL.scheme, "https")
        } else {
            XCTFail("HTTP should be upgraded")
        }
    }

    func testNavDecision_blockPhishing() {
        let url = URL(string: "https://login-microsoftonline.com/fake")!
        if case .block(let reason) = securityManager.shouldAllowNavigation(to: url) {
            XCTAssertEqual(reason, .phishing)
        } else {
            XCTFail("Phishing should be blocked")
        }
    }

    func testNavDecision_allowHTTPWhenDisabled() {
        securityManager.httpsOnlyMode = false
        let url = URL(string: "http://example.com")!
        if case .allow = securityManager.shouldAllowNavigation(to: url) {
            // pass
        } else {
            XCTFail("HTTP should be allowed when HTTPS-only is off")
        }
    }

    // MARK: - 5. URL Threat Check

    func testCheckURL_phishing() {
        let url = URL(string: "https://amazon-security-alert.com")!
        XCTAssertEqual(securityManager.checkURL(url), .phishing)
    }

    func testCheckURL_httpSite() {
        let url = URL(string: "http://example.com")!
        XCTAssertEqual(securityManager.checkURL(url), .httpSite)
    }

    func testCheckURL_safe() {
        let url = URL(string: "https://github.com")!
        XCTAssertNil(securityManager.checkURL(url))
    }

    // MARK: - 6. Anti-Fingerprint Script

    func testAntiFingerprintScript_enabled() {
        securityManager.antiFingerprint = true
        let script = securityManager.antiFingerprintScript
        XCTAssertFalse(script.isEmpty)
        XCTAssertTrue(script.contains("screen"))
        XCTAssertTrue(script.contains("Canvas"))
        XCTAssertTrue(script.contains("WebGLRenderingContext"))
        XCTAssertTrue(script.contains("hardwareConcurrency"))
    }

    func testAntiFingerprintScript_disabled() {
        securityManager.antiFingerprint = false
        let script = securityManager.antiFingerprintScript
        XCTAssertTrue(script.isEmpty)
    }

    // MARK: - 7. Content Blocking Rules

    func testEnhancedBlockingRules_validJSON() {
        let rules = securityManager.enhancedBlockingRules
        let data = rules.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    func testEnhancedBlockingRules_containsTrackers() {
        let rules = securityManager.enhancedBlockingRules
        XCTAssertTrue(rules.contains("doubleclick"))
        XCTAssertTrue(rules.contains("facebook"))
        XCTAssertTrue(rules.contains("analytics"))
        XCTAssertTrue(rules.contains("hotjar"))
        XCTAssertTrue(rules.contains("mixpanel"))
    }

    // MARK: - 8. Permission Manager

    func testPermission_grantAndCheck() {
        let pm = PermissionManager.shared
        pm.grant(domain: "test.com", permission: .camera)
        XCTAssertEqual(pm.decision(for: "test.com", permission: .camera), true)
        pm.reset(domain: "test.com")
    }

    func testPermission_denyAndCheck() {
        let pm = PermissionManager.shared
        pm.deny(domain: "test.com", permission: .microphone)
        XCTAssertEqual(pm.decision(for: "test.com", permission: .microphone), false)
        pm.reset(domain: "test.com")
    }

    func testPermission_noDecision() {
        let pm = PermissionManager.shared
        pm.reset(domain: "unknown.com")
        XCTAssertNil(pm.decision(for: "unknown.com", permission: .camera))
    }

    func testPermission_resetDomain() {
        let pm = PermissionManager.shared
        pm.grant(domain: "reset-test.com", permission: .camera)
        pm.deny(domain: "reset-test.com", permission: .microphone)
        pm.reset(domain: "reset-test.com")
        XCTAssertNil(pm.decision(for: "reset-test.com", permission: .camera))
        XCTAssertNil(pm.decision(for: "reset-test.com", permission: .microphone))
    }

    func testPermission_resetAll() {
        let pm = PermissionManager.shared
        pm.grant(domain: "a.com", permission: .camera)
        pm.grant(domain: "b.com", permission: .microphone)
        pm.resetAll()
        XCTAssertNil(pm.decision(for: "a.com", permission: .camera))
        XCTAssertNil(pm.decision(for: "b.com", permission: .microphone))
    }
}
