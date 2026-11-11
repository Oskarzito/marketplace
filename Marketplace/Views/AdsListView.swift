import SwiftUI

struct AdsListView: View {
    @Bindable var viewModel: AdsViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // At accessibility text sizes two columns are too narrow for the text, so use one.
    // Top alignment: by default a card shorter than its row (an ad without a price) is centered,
    // which pushes its image and heart below its neighbour's.
    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible(), alignment: .top)]
            : [GridItem(.adaptive(minimum: 160), spacing: 12, alignment: .top)]
    }

    var body: some View {
        NavigationStack {
            content
                // Cards sit on a grouped background so they stand out, whatever colour their image has.
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle("Marketplace")
                .safeAreaInset(edge: .top) {
                    filterPicker
                }
        }
        .task {
            // Favorites come from disk and are quick; load them first so hearts are right before the network answers.
            await viewModel.loadFavorites()
            await viewModel.loadAds()
        }
    }

    private var filterPicker: some View {
        Picker("Show", selection: $viewModel.filter) {
            Text("All").tag(AdsViewModel.Filter.all)
            Text("Favorites").tag(AdsViewModel.Filter.favorites)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.filter {
        case .all:
            allAdsContent
        case .favorites:
            favoritesContent
        }
    }

    @ViewBuilder
    private var allAdsContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            // Without filling the screen the picker inset attaches to the small spinner, mid-screen.
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            grid(of: viewModel.ads)
                .refreshable {
                    await viewModel.loadAds()
                }
        }
    }

    // Favorites are saved on the device, so this tab never depends on the load state of the feed.
    @ViewBuilder
    private var favoritesContent: some View {
        if viewModel.favorites.isEmpty {
            ContentUnavailableView(
                "No favorites yet",
                systemImage: "heart",
                description: Text("Tap the heart on an ad to save it here.")
            )
        } else {
            grid(of: viewModel.favorites.map(\.ad))
        }
    }

    private func grid(of ads: [Ad]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ads) { ad in
                    AdCardView(
                        ad: ad,
                        imageData: viewModel.savedImageData(for: ad),
                        isFavorite: viewModel.isFavorite(ad),
                        onToggleFavorite: { viewModel.toggleFavorite(ad) }
                    )
                }
            }
            .padding(.horizontal, 16)
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
