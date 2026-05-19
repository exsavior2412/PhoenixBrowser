import SwiftUI

// MARK: - Safari-style Download Toolbar Icon

struct DownloadToolbarIcon: View {
    @ObservedObject var downloadManager: DownloadManager
    @Binding var showPopover: Bool
    @State private var bounceAmount: CGFloat = 0
    @State private var prevCount = 0

    private var activeDownloads: [DownloadItem] {
        downloadManager.downloads.filter { !$0.isComplete && $0.error == nil }
    }

    private var overallProgress: Double {
        let items = activeDownloads
        guard !items.isEmpty else { return 0 }
        let total = items.reduce(0.0) { $0 + $1.progress }
        return total / Double(items.count)
    }

    private var isDownloading: Bool { !activeDownloads.isEmpty }

    var body: some View {
        ZStack {
            // Circular progress ring (Safari-style)
            if isDownloading {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 2)
                    .frame(width: 22, height: 22)

                Circle()
                    .trim(from: 0, to: overallProgress)
                    .stroke(Edge.Colors.accentBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: overallProgress)
            }

            // Arrow icon
            Image(systemName: isDownloading ? "arrow.down" : "arrow.down.circle")
                .font(.system(size: isDownloading ? 10 : Edge.Sizes.iconSize, weight: .semibold))
                .foregroundStyle(isDownloading ? Edge.Colors.accentBlue : Edge.Colors.iconColor)
                .offset(y: bounceAmount)

            // Badge count
            if downloadManager.downloads.contains(where: { $0.isComplete }) && !isDownloading {
                let completedCount = downloadManager.downloads.filter(\.isComplete).count
                Text("\(completedCount)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 13, height: 13)
                    .background(Circle().fill(Edge.Colors.accentBlue))
                    .offset(x: 8, y: -8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: Edge.Sizes.iconBtnSize, height: Edge.Sizes.iconBtnSize)
        .contentShape(Rectangle())
        .onTapGesture {
            showPopover.toggle()
        }
        .onChange(of: downloadManager.downloads.count) { old, new in
            if new > old {
                // New download started — bounce animation
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 8)) {
                    bounceAmount = -4
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 8)) {
                        bounceAmount = 0
                    }
                }
            }
        }
    }
}

// MARK: - Downloads Popover

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
                    Text("Clear")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                downloadManager.clearCompleted()
                            }
                        }
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
                            DownloadRowView(item: item, downloadManager: downloadManager)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Open downloads folder
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                Text("Open Downloads Folder")
                    .font(.system(size: 11))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
            .onTapGesture {
                downloadManager.openDownloadsFolder()
            }
        }
        .frame(width: 300)
    }
}

// MARK: - Download Row with Animation

struct DownloadRowView: View {
    let item: DownloadItem
    let downloadManager: DownloadManager
    @State private var showCheckmark = false
    @State private var progressWidth: CGFloat = 0

    var body: some View {
        HStack(spacing: 10) {
            // Animated icon
            ZStack {
                if item.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)
                        .scaleEffect(showCheckmark ? 1 : 0.3)
                        .opacity(showCheckmark ? 1 : 0)
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                showCheckmark = true
                            }
                        }
                } else if item.error != nil {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.red)
                } else {
                    // Downloading — circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 2.5)
                            .frame(width: 20, height: 20)
                        Circle()
                            .trim(from: 0, to: item.progress)
                            .stroke(Edge.Colors.accentBlue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.3), value: item.progress)
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Edge.Colors.accentBlue)
                    }
                }
            }
            .frame(width: 24, height: 24)

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
                    Text("Done — \(item.sizeText)")
                        .font(.system(size: 10))
                        .foregroundStyle(.green.opacity(0.8))
                } else {
                    // Progress text
                    HStack(spacing: 4) {
                        Text("\(Int(item.progress * 100))%")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Edge.Colors.accentBlue)
                        Text(item.sizeText)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if item.isComplete {
                // Show in Finder
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .contentShape(Circle())
                    .onTapGesture {
                        downloadManager.openInFinder(item)
                    }
                    .transition(.scale.combined(with: .opacity))
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
