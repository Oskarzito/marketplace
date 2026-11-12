import SwiftUI

struct AdsListView: View {
    @Bindable var viewModel: AdsViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // Top aligned. Otherwise a shorter card (no price line) gets centered in its row and sits lower than its neighbour.
    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible(), alignment: .top)]
            : [GridItem(.adaptive(minimum: 160), spacing: 12, alignment: .top)]
    }

    var body: some View {
        NavigationStack {
            content
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationDestination(for: Ad.self) { ad in
                    AdDetailView(ad: ad, viewModel: viewModel)
                }
                .navigationTitle("Marketplace")
                // Inline, because a large title slid under the picker while scrolling.
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .top) {
                    filterPicker
                }
        }
        .task {
            // Favorites are a quick read from disk. Load them first so the hearts are right before the feed arrives.
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

    // Both lists stay alive and we only show one, so each keeps its scroll position.
    // An if/else would rebuild the list on every switch.
    private var content: some View {
        ZStack {
            allAdsContent
                .shown(viewModel.filter == .all)
            favoritesContent
                .shown(viewModel.filter == .favorites)
        }
    }

    @ViewBuilder
    private var allAdsContent: some View {
        switch viewModel.loadState {
        case .loading:
            // Fill the screen, otherwise the picker above attaches to the small spinner and ends up mid-screen.
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

private extension View {
    func shown(_ isShown: Bool) -> some View {
        opacity(isShown ? 1 : 0)
            .allowsHitTesting(isShown)
            .accessibilityHidden(!isShown)
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
