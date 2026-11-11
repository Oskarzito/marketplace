import Foundation
import Observation

@MainActor
@Observable
final class AdsViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var ads: [Ad] = []
    private(set) var loadState: LoadState = .idle

    private let service: any AdsService

    init(service: any AdsService) {
        self.service = service
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
            loadState = Task.isCancelled ? .idle : .failed(error.localizedDescription)
        }
    }
}
