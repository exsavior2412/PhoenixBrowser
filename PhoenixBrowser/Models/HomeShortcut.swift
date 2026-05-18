import Foundation

struct HomeShortcut: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var url: URL
    var icon: String

    init(name: String, url: URL, icon: String = "globe") {
        self.id = UUID()
        self.name = name
        self.url = url
        self.icon = icon
    }
}
