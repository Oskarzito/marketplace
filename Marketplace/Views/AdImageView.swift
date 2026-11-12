import SwiftUI

struct AdImageView: View {
    private enum Phase {
        case loading
        case loaded(UIImage)
        case failed
    }

    let url: URL?
    let storedData: Data?
    let style: Ad.ImageStyle

    @State private var phase: Phase = .loading

    var body: some View {
        // The tile fixes the 4:3 size up front, so the layout doesn't jump as images arrive.
        tileColor
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay { content }
            // A "fill" image can overflow its tile. The card rounds the corners.
            .clipped()
            .task(id: url) {
                await load()
            }
    }

    // Logos are drawn for light backgrounds, so they always sit on white.
    private var tileColor: Color {
        style == .logo ? .white : Color(uiColor: .tertiarySystemGroupedBackground)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            EmptyView()
        case .loaded(let image):
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: style == .logo ? .fit : .fill)
                .padding(style == .logo ? 12 : 0)
        case .failed:
            Image(systemName: "photo")
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }

    private func load() async {
        do {
            phase = .loaded(try await ImageLoader.shared.image(for: url, storedData: storedData))
        } catch {
            // The row scrolled away mid-load; that is not a failed image.
            guard !Task.isCancelled else { return }
            phase = .failed
        }
    }
}
