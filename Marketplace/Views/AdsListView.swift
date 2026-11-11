import SwiftUI

struct AdsListView: View {
    let viewModel: AdsViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // At accessibility text sizes two columns are too narrow for the text, so use one.
    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 160), spacing: 12)]
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Marketplace")
        }
        .task {
            // Favorites come from disk and are quick; load them first so hearts are right before the network answers.
            await viewModel.loadFavorites()
            await viewModel.loadAds()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load ads", systemImage: "wifi.slash")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task { await viewModel.loadAds() }
                }
            }
        case .loaded:
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.ads) { ad in
                        AdCardView(
                            ad: ad,
                            isFavorite: viewModel.isFavorite(ad),
                            onToggleFavorite: { viewModel.toggleFavorite(ad) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                await viewModel.loadAds()
            }
        }
    }
}

#Preview {
    nonisolated struct StubAdsService: AdsService {
        func fetchAds() async throws -> [Ad] {
            [
                Ad(id: "1", title: "Opel Astra 1,6 Automat", location: "Halden", price: 40000, imageURL: nil, imageStyle: .photo),
                Ad(id: "2", title: "Juridisk skadebehandler", location: "Lysaker", price: nil, imageURL: nil, imageStyle: .logo),
                Ad(id: "3", title: "Rundt spisebord", location: "Oslo", price: 500, imageURL: nil, imageStyle: .photo),
            ]
        }
    }

    nonisolated struct StubFavoritesStore: FavoritesStore {
        func loadAll() async -> [Favorite] { [] }
        func add(_ ad: Ad, imageData: Data?) async throws {}
        func remove(id: Ad.ID) async throws {}
    }

    return AdsListView(viewModel: AdsViewModel(service: StubAdsService(), store: StubFavoritesStore()))
}
