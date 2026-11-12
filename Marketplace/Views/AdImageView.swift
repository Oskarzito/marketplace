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
        tileColor
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay { content }
            .clipped()
            .task(id: url) {
                await load()
            }
    }

    private var tileColor: Color {
        style == .logo ? .white : Color(uiColor: .systemGray5)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            ProgressView()
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
            guard !Task.isCancelled else { return }
            phase = .failed
        }
    }
}
