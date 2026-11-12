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
        // Only the first load gets a full-screen spinner. Doing that during a pull-to-refresh would cancel the refresh.
        if ads.isEmpty {
            loadState = .loading
        }
        do {
            ads = try await service.fetchAds()
            loadState = .loaded
        } catch {
            // If a refresh fails, keep showing the ads we already have.
            guard ads.isEmpty else {
                loadState = .loaded
                return
            }
            // A cancelled load (the view went away) isn't an error, so don't show one.
            loadState = Task.isCancelled ? .loading : .failed(error.localizedDescription)
        }
    }

    func loadFavorites() async {
        favorites = await store.loadAll()
    }

    func isFavorite(_ ad: Ad) -> Bool {
        favorites.contains { $0.ad.id == ad.id }
    }

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

    private func addFavorite(_ ad: Ad) {
        favorites.insert(Favorite(ad: ad, imageData: nil), at: 0)
        Task {
            let imageData = await downloadImageData(for: ad)
            // If the heart was tapped off again while the image downloaded, skip saving.
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

    // If the download fails we still save the favorite, just without an image.
    private func downloadImageData(for ad: Ad) async -> Data? {
        guard let url = ad.imageURL else { return nil }
        return try? await imageLoader.data(for: url)
    }
}
