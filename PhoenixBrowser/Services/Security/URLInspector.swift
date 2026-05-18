import Foundation

enum URLInspector {
    static func isSuspicious(_ url: URL) -> Bool {
        guard let host = url.host()?.lowercased() else { return false }

        let parts = host.split(separator: ".")
        if parts.count > 5 { return true }

        let brands = ["paypal", "apple", "google", "microsoft", "amazon",
                       "facebook", "netflix", "instagram", "binance", "coinbase", "bank"]
        let tld = parts.suffix(2).joined(separator: ".")
        let sub = parts.dropLast(2).joined(separator: ".")
        for brand in brands {
            if sub.contains(brand) && !tld.contains(brand) { return true }
        }

        let ipPattern = #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"#
        if host.range(of: ipPattern, options: .regularExpression) != nil { return true }

        if host.count > 50 { return true }

        if url.absoluteString.contains("@") && url.user != nil { return true }

        return false
    }

    static func isMaliciousDataURI(_ url: URL) -> Bool {
        let str = url.absoluteString.lowercased()
        guard str.hasPrefix("data:") else { return false }
        if str.contains("data:text/html") { return true }
        if str.contains("data:application/javascript") { return true }
        if str.contains("data:application/x-javascript") { return true }
        if str.contains("base64") && str.contains("text/html") { return true }
        return false
    }
}
