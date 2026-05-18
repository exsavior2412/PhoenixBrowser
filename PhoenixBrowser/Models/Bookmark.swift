import Foundation

struct Bookmark: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var url: URL
    var dateAdded: Date

    init(title: String, url: URL) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.dateAdded = Date()
    }
}
