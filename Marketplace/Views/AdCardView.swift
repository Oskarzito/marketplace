import SwiftUI

struct AdCardView: View {
    // The feed has no currency field; this is a Norwegian marketplace, so prices are NOK.
    private static let priceFormat = IntegerFormatStyle<Int>.Currency(code: "NOK", locale: Locale(identifier: "nb_NO"))
        .precision(.fractionLength(0))

    let ad: Ad
    let imageData: Data?
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        // The button sits beside the combined card element, not inside it, so VoiceOver keeps it as its own control.
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // The photo says nothing VoiceOver needs; the text below describes the ad.
                AdImageView(url: ad.imageURL, storedData: imageData, style: ad.imageStyle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    // Reserving two lines keeps card heights equal whatever the title length.
                    Text(ad.title)
                        .font(.subheadline)
                        .lineLimit(2, reservesSpace: true)

                    if let price = ad.price {
                        // `Text(_:format:)` would swap in the device locale and print "NOK" instead of "kr".
                        Text(price.formatted(Self.priceFormat))
                            .font(.subheadline.bold())
                    }

                    if let location = ad.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
            }
            // Fill the row height, so a card without a price line is as tall as its neighbour.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)

            favoriteButton
        }
    }

    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? .red : .primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .padding(6)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}

#Preview {
    AdCardView(
        ad: Ad(
            id: "1",
            title: "Opel Astra 1,6 Automat",
            location: "Halden",
            price: 40000,
            imageURL: nil,
            imageStyle: .photo
        ),
        imageData: nil,
        isFavorite: true,
        onToggleFavorite: {}
    )
    .padding()
}
