import SwiftUI

struct ProgressBarView: View {
    let isLoading: Bool
    let progress: Double

    @State private var displayProgress: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(Edge.Colors.accentBlue)
                .frame(width: geo.size.width * displayProgress, height: 2)
                .opacity(opacity)
        }
        .frame(height: 2)
        .onChange(of: isLoading) { _, loading in
            if loading {
                // Start loading: show bar, reset
                hideTask?.cancel()
                withAnimation(.easeOut(duration: 0.15)) {
                    opacity = 1
                    displayProgress = max(0.05, progress)
                }
            } else {
                // Finished: animate to full width, then fade out
                withAnimation(.easeOut(duration: 0.25)) {
                    displayProgress = 1.0
                }
                hideTask?.cancel()
                hideTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard !Task.isCancelled else { return }
                    displayProgress = 0
                }
            }
        }
        .onChange(of: progress) { _, newProgress in
            guard isLoading else { return }
            withAnimation(.linear(duration: 0.2)) {
                displayProgress = max(displayProgress, newProgress)
            }
        }
    }
}
