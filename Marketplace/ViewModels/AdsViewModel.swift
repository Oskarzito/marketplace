import Foundation
import Observation

@MainActor
@Observable
final class AdsViewModel {
    enum LoadState {
        case loading
        case loaded
        case failed(String)
    }

    enum Filter {
        case all
        case favorites
    }

    var filter: Filter = .all
    private(set) var ads: [Ad] = []
    private(set) var favorites: [Favorite] = []
    private(set) var loadState: LoadState = .loading

    private let service: any AdsService
    private let store: any FavoritesStore
    private let imageLoader: ImageLoader

    init(service: any AdsService, store: any FavoritesStore, imageLoader: ImageLoader = .shared) {
        self.service = service
        self.store = store
        self.imageLoader = imageLoader
    }

    func loadAds() async {
        // Pull-to-refresh shows its own spinner. Swapping the grid for a full-screen
        // spinner would also cancel the refresh task, because the view it hangs on disappears.
        if ads.isEmpty {
            loadState = .loading
        }
        do {
            ads = try await service.fetchAds()
            loadState = .loaded
        } catch {
            // A failed refresh keeps the ads already on screen.
            guard ads.isEmpty else {
                loadState = .loaded
                return
            }
            // A cancelled load (the view went away) is not an error worth showing.
            loadState = Task.isCancelled ? .loading : .failed(error.localizedDescription)
        }
    }

    func loadFavorites() async {
        favorites = await store.loadAll()
    }

    func isFavorite(_ ad: Ad) -> Bool {
        favorites.contains { $0.ad.id == ad.id }
    }

    /// The image saved with a favorite, so it can be shown without the network.
    func savedImageData(for ad: Ad) -> Data? {
        favorites.first { $0.ad.id == ad.id }?.imageData
    }

    func toggleFavorite(_ ad: Ad) {
        if isFavorite(ad) {
            removeFavorite(ad)
        } else {
            addFavorite(ad)
        }
    }

    // The heart flips immediately; saving to disk happens afterwards.
    private func addFavorite(_ ad: Ad) {
        favorites.insert(Favorite(ad: ad, imageData: nil), at: 0)
        Task {
            let imageData = await downloadImageData(for: ad)
            // The user may have tapped the heart again while the image was downloading.
            guard isFavorite(ad) else { return }
            do {
                try await store.add(ad, imageData: imageData)
                if let index = favorites.firstIndex(where: { $0.ad.id == ad.id }) {
                    favorites[index] = Favorite(ad: ad, imageData: imageData)
                }
            } catch {
                await loadFavorites()
            }
        }
    }

    private func removeFavorite(_ ad: Ad) {
        favorites.removeAll { $0.ad.id == ad.id }
        Task {
            do {
                try await store.remove(id: ad.id)
            } catch {
                await loadFavorites()
            }
        }
    }

    // A favorite is still saved without its image if the download fails; the card shows a placeholder.
    private func downloadImageData(for ad: Ad) async -> Data? {
        guard let url = ad.imageURL else { return nil }
        return try? await imageLoader.data(for: url)
    }
}
