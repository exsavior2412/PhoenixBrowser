import Foundation
import WebKit

enum PermissionType: String {
    case camera = "Camera"
    case microphone = "Microphone"
    case location = "Location"
    case notifications = "Notifications"
}

struct PermissionRecord: Codable, Hashable {
    let domain: String
    let permission: String
    var allowed: Bool
}

final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var records: [PermissionRecord] = []

    private let storageKey = "phoenix_permissions"

    init() {
        load()
    }

    func decision(for domain: String, permission: PermissionType) -> Bool? {
        records.first { $0.domain == domain && $0.permission == permission.rawValue }?.allowed
    }

    func grant(domain: String, permission: PermissionType) {
        removeRecord(domain: domain, permission: permission)
        records.append(PermissionRecord(domain: domain, permission: permission.rawValue, allowed: true))
        save()
    }

    func deny(domain: String, permission: PermissionType) {
        removeRecord(domain: domain, permission: permission)
        records.append(PermissionRecord(domain: domain, permission: permission.rawValue, allowed: false))
        save()
    }

    func reset(domain: String) {
        records.removeAll { $0.domain == domain }
        save()
    }

    func resetAll() {
        records.removeAll()
        save()
    }

    private func removeRecord(domain: String, permission: PermissionType) {
        records.removeAll { $0.domain == domain && $0.permission == permission.rawValue }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([PermissionRecord].self, from: data)
        else { return }
        records = saved
    }
}
