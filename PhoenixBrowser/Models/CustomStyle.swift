import Foundation

struct CustomStyle: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var css: String
    var urlPattern: String  // "*" for all sites, or domain pattern like "*.github.com"
    var isEnabled: Bool

    init(name: String, css: String, urlPattern: String = "*", isEnabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.css = css
        self.urlPattern = urlPattern
        self.isEnabled = isEnabled
    }

    func matchesURL(_ url: URL?) -> Bool {
        guard let host = url?.host() else { return false }
        if urlPattern == "*" { return true }

        let pattern = urlPattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")

        return host.range(of: "^\(pattern)$", options: .regularExpression) != nil
    }
}
