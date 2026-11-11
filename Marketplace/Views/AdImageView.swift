import SwiftUI

extension EnvironmentValues {
    @Entry var imageLoader = ImageLoader.shared
}

struct AdImageView: View {
    private enum Phase {
        case loading
        case loaded(UIImage)
        case failed
    }

    let url: URL?
    /// Bytes saved with a favorite. When present they are used instead of the network, so the image works offline.
    let storedData: Data?
    let style: Ad.ImageStyle

    @Environment(\.imageLoader) private var imageLoader
    @State private var phase: Phase = .loading

    var body: some View {
        // The tile fixes the 4:3 size up front, so the layout doesn't jump as images arrive.
        tileColor
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay { content }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .task(id: url) {
                await load()
            }
    }

    // Logos are drawn for light backgrounds, so they always sit on white.
    private var tileColor: Color {
        style == .logo ? .white : Color(uiColor: .secondarySystemBackground)
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
            if let storedData {
                phase = .loaded(try await imageLoader.image(from: storedData))
            } else if let url {
                phase = .loaded(try await imageLoader.image(for: url))
            } else {
                phase = .failed
            }
        } catch {
            // The row scrolled away mid-load; that is not a failed image.
            guard !Task.isCancelled else { return }
            phase = .failed
        }
    }
}
