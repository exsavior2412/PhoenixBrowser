import Foundation

enum HTTPSUpgrader {
    static func upgrade(_ url: URL) -> URL? {
        guard url.scheme == "http",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        components.scheme = "https"
        return components.url
    }
}
