import SwiftUI

struct EdgeNewTabView: View {
    @ObservedObject var tabManager: TabManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @StateObject private var homeManager = HomePageManager.shared
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var showImagePicker = false

    var body: some View {
        ZStack {
            // Background
            Edge.Colors.ntpBg.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    // Hero card
                    heroCard(size: geo.size)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Page toolbar overlay
            VStack {
                HStack {
                    Spacer()
                    Button { showImagePicker = true } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 38)
                .padding(.horizontal, 10)

                Spacer()
            }
        }
        .contextMenu {
            Button("Change Background...") { showImagePicker = true }
            Button("Reset Background") { homeManager.resetBackground() }
        }
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                homeManager.setBackgroundImage(from: url)
            }
        }
    }

    // MARK: - Hero Card

    private func heroCard(size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Hero art circle/shape
                heroArt(size: size)

                // Search overlay
                VStack {
                    searchBox
                        .padding(.top, size.height * 0.12)
                    Spacer()
                }
            }
            .frame(width: min(672, size.width * 0.92))
            .frame(height: min(672, size.width * 0.92))

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    // MARK: - Hero Art

    private func heroArt(size: CGSize) -> some View {
        ZStack {
            // Background image or gradient
            if let bgImage = homeManager.backgroundImage {
                Image(nsImage: bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Default gradient simulating landscape
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: 0xffecd2),
                            Color(hex: 0xfcb69f),
                            Color(hex: 0xa18cd1),
                            Color(hex: 0x667eea)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Sun
                    RadialGradient(
                        colors: [.white.opacity(0.9), .clear],
                        center: .init(x: 0.5, y: 0.3),
                        startRadius: 20,
                        endRadius: 200
                    )
                }
            }
        }
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 999,
            bottomLeadingRadius: 22,
            bottomTrailingRadius: 22,
            topTrailingRadius: 999
        ))
        .shadow(color: Color(hex: 0x121e22, alpha: 0.28), radius: 64, y: 24)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 999,
                bottomLeadingRadius: 22,
                bottomTrailingRadius: 22,
                topTrailingRadius: 999
            )
            .stroke(.white.opacity(0.36), lineWidth: 1)
        )
    }

    // MARK: - Search Box

    private var searchBox: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: 0x73716e))

            TextField("Search the web", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundStyle(Color(hex: 0x343434))
                .focused($isSearchFocused)
                .onSubmit {
                    if !searchText.isEmpty {
                        tabManager.navigate(to: searchText)
                        searchText = ""
                    }
                }

            Spacer()

            // Mic
            Button {} label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x73716e))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            // Copilot
            Button {} label: {
                Image(systemName: "sparkle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x73716e))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(width: min(352, 340), height: 35)
        .background(
            Capsule()
                .fill(.white.opacity(0.82))
                .shadow(color: Color(hex: 0x554733, alpha: 0.16), radius: 32, y: 12)
        )
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
    }
}
