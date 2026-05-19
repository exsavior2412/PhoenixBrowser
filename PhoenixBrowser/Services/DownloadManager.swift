import Foundation
import AppKit

struct DownloadItem: Identifiable {
    let id = UUID()
    let filename: String
    let url: URL
    let destinationURL: URL
    var bytesReceived: Int64 = 0
    var totalBytes: Int64 = -1
    var isComplete: Bool = false
    var error: String?

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesReceived) / Double(totalBytes)
    }

    var sizeText: String {
        if totalBytes > 0 {
            let received = ByteCountFormatter.string(fromByteCount: bytesReceived, countStyle: .file)
            let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            return "\(received) / \(total)"
        }
        if bytesReceived > 0 {
            return ByteCountFormatter.string(fromByteCount: bytesReceived, countStyle: .file)
        }
        return ""
    }
}

final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var downloads: [DownloadItem] = []
    @Published var hasNewDownload = false

    var downloadDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }

    func addDownload(filename: String, url: URL, destination: URL) -> UUID {
        let item = DownloadItem(filename: filename, url: url, destinationURL: destination)
        downloads.insert(item, at: 0)
        hasNewDownload = true
        return item.id
    }

    func updateProgress(id: UUID, bytesReceived: Int64, totalBytes: Int64) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].bytesReceived = bytesReceived
            downloads[idx].totalBytes = totalBytes
        }
    }

    func completeDownload(id: UUID) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].isComplete = true
            downloads[idx].bytesReceived = downloads[idx].totalBytes
        }
    }

    func failDownload(id: UUID, error: String) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].error = error
        }
    }

    func openInFinder(_ item: DownloadItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.destinationURL])
    }

    func openDownloadsFolder() {
        NSWorkspace.shared.open(downloadDirectory)
    }

    func clearCompleted() {
        downloads.removeAll { $0.isComplete || $0.error != nil }
    }
}
