import Foundation

final class URLBlocklist {
    private var domains: Set<String> = []

    init() {
        domains = [
            "malware.testing.google.test",
            "phishing.testing.google.test",
            "testsafebrowsing.appspot.com",
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
    }

    func isBlocked(_ url: URL) -> Bool {
        guard let host = url.host()?.lowercased() else { return false }
        return domains.contains(host) ||
               domains.contains(where: { host.hasSuffix(".\($0)") })
    }

    func add(_ domain: String) {
        domains.insert(domain.lowercased())
    }
}
