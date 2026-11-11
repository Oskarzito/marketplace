import SwiftUI

@main struct MarketplaceApp: App {
    @State private var viewModel = AdsViewModel(service: URLSessionAdsService(), store: FileFavoritesStore())

    var body: some Scene {
        WindowGroup {
            AdsListView(viewModel: viewModel)
        }
    }
}
