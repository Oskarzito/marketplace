import SwiftUI

struct AdDetailView: View {
    let ad: Ad
    let viewModel: AdsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AdImageView(url: ad.imageURL, storedData: viewModel.savedImageData(for: ad), style: ad.imageStyle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(ad.title)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)

                    if let price = ad.formattedPrice {
                        Text(price)
                            .font(.title3.bold())
                    }

                    if let location = ad.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FavoriteButton(isFavorite: viewModel.isFavorite(ad)) {
                    viewModel.toggleFavorite(ad)
                }
            }
        }
    }
}
