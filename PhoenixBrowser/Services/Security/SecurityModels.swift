import Foundation

enum SecurityLevel: String {
    case secure = "secure"
    case insecure = "insecure"
    case dangerous = "dangerous"
    case unknown = "unknown"
}

enum SecurityThreat: String, Codable {
    case phishing
    case malware
    case unwanted
    case httpSite
    case certError
}

enum NavigationDecision {
    case allow
    case block(reason: SecurityThreat)
    case upgrade(to: URL)
    case warnHTTP
}
