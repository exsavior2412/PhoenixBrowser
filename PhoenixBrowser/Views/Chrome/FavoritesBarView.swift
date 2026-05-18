import SwiftUI

struct FavoritesBarView: View {
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var tabManager: TabManager

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
                    Button("Remove", role: .destructive) {
                        bookmarkManager.remove(bookmark)
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
    }
}
