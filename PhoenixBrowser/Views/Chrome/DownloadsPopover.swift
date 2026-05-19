import SwiftUI

struct DownloadsPopover: View {
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Downloads")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if !downloadManager.downloads.isEmpty {
                    Button("Clear") {
                        downloadManager.clearCompleted()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if downloadManager.downloads.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("No downloads")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 1) {
                        ForEach(downloadManager.downloads) { item in
                            downloadRow(item)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Open downloads folder
            Button {
                downloadManager.openDownloadsFolder()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                    Text("Open Downloads Folder")
                        .font(.system(size: 11))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .frame(width: 300)
    }

    private func downloadRow(_ item: DownloadItem) -> some View {
        HStack(spacing: 10) {
            // File icon
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : (item.error != nil ? "exclamationmark.circle.fill" : "arrow.down.circle"))
                .font(.system(size: 16))
                .foregroundStyle(item.isComplete ? .green : (item.error != nil ? .red : Edge.Colors.accentBlue))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)

                if let error = item.error {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else if item.isComplete {
                    Text("Complete — \(item.sizeText)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                } else {
                    // Progress bar
                    VStack(alignment: .leading, spacing: 2) {
                        ProgressView(value: item.progress)
                            .progressViewStyle(.linear)
                            .frame(height: 3)
                        Text(item.sizeText)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if item.isComplete {
                Button {
                    downloadManager.openInFinder(item)
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.isComplete {
                NSWorkspace.shared.open(item.destinationURL)
            }
        }
    }
}
