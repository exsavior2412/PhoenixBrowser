import SwiftUI

struct FavoritesBarView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var tabManager: TabManager
    @State private var showAddBookmark = false
    @State private var editingBookmark: Bookmark?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(bookmarkManager.bookmarks.prefix(8)) { bookmark in
                Button {
                    tabManager.navigate(to: bookmark.url.absoluteString)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "globe")
                            .font(.system(size: 10))
                            .foregroundStyle(Edge.Colors.iconColor)
                        Text(bookmark.title)
                            .font(.system(size: 10.9))
                            .foregroundStyle(Edge.Colors.favText)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 19)
                    .frame(maxWidth: 168)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.001)))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    // Open
                    Button {
                        tabManager.navigate(to: bookmark.url.absoluteString)
                    } label: {
                        Label("Open", systemImage: "arrow.right")
                    }

                    Button {
                        _ = tabManager.addNewTab(url: bookmark.url)
                    } label: {
                        Label("Open in New Tab", systemImage: "plus.square")
                    }

                    Button {
                        _ = tabManager.addPrivateTab(url: bookmark.url)
                    } label: {
                        Label("Open in Private Tab", systemImage: "eye.slash")
                    }

                    Divider()

                    // Edit
                    Button {
                        editingBookmark = bookmark
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(bookmark.url.absoluteString, forType: .string)
                    } label: {
                        Label("Copy URL", systemImage: "doc.on.doc")
                    }

                    Divider()

                    // Remove
                    Button(role: .destructive) {
                        bookmarkManager.remove(bookmark)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }

            Spacer()
        }
        .frame(height: Edge.Sizes.favoritesRowHeight)
        .padding(.horizontal, 6)
        .overlay(alignment: .top) {
            Rectangle().fill(Color(hex: 0x8e7852, alpha: 0.18)).frame(height: 1)
        }
        // Right-click on empty area of favorites bar
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                if let tab = tabManager.selectedTab, let url = tab.url {
                    bookmarkManager.add(title: tab.title, url: url)
                }
            } label: {
                Label("Add Current Page", systemImage: "star.fill")
            }
            .disabled(tabManager.selectedTab?.url == nil)

            Divider()

            Button {
                showAddBookmark = true
            } label: {
                Label("Add Bookmark...", systemImage: "plus")
            }

            Button {
                NSPasteboard.general.clearContents()
                if let url = tabManager.selectedTab?.url {
                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                }
            } label: {
                Label("Copy Page URL", systemImage: "doc.on.doc")
            }
            .disabled(tabManager.selectedTab?.url == nil)

            Divider()

            if !bookmarkManager.bookmarks.isEmpty {
                Menu("Open All Bookmarks") {
                    Button("In Current Window") {
                        for bm in bookmarkManager.bookmarks {
                            _ = tabManager.addNewTab(url: bm.url)
                        }
                    }
                    Button("In Private Tabs") {
                        for bm in bookmarkManager.bookmarks {
                            _ = tabManager.addPrivateTab(url: bm.url)
                        }
                    }
                }
            }

            Divider()

            Toggle("Show Favorites Bar", isOn: .constant(true))
        }
        .sheet(isPresented: $showAddBookmark) {
            AddBookmarkSheet(bookmarkManager: bookmarkManager)
        }
        .sheet(item: $editingBookmark) { bookmark in
            EditBookmarkSheet(bookmarkManager: bookmarkManager, bookmark: bookmark)
        }
    }
}

// MARK: - Add Bookmark Sheet

struct AddBookmarkSheet: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var urlString = "https://"

    var body: some View {
        VStack(spacing: 14) {
            Text("Add Bookmark")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Bookmark name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("URL")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("https://example.com", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    if !name.isEmpty, let url = URL(string: urlString) {
                        bookmarkManager.add(title: name, url: url)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || URL(string: urlString) == nil)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

// MARK: - Edit Bookmark Sheet

struct EditBookmarkSheet: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    @Environment(\.dismiss) private var dismiss
    let bookmark: Bookmark
    @State private var name: String = ""
    @State private var urlString: String = ""

    var body: some View {
        VStack(spacing: 14) {
            Text("Edit Bookmark")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Bookmark name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("URL")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("https://example.com", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(role: .destructive) {
                    bookmarkManager.remove(bookmark)
                    dismiss()
                } label: {
                    Text("Delete")
                }
                Button("Save") {
                    if !name.isEmpty, let url = URL(string: urlString) {
                        bookmarkManager.remove(bookmark)
                        bookmarkManager.add(title: name, url: url)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || URL(string: urlString) == nil)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            name = bookmark.title
            urlString = bookmark.url.absoluteString
        }
    }
}
