import SwiftUI

@main struct MarketplaceApp: App {
    @State private var viewModel = AdsViewModel(service: URLSessionAdsService())

    var body: some Scene {
        WindowGroup {
            AdsListView(viewModel: viewModel)
        }
    }
}
