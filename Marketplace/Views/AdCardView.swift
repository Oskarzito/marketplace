import SwiftUI

struct AdCardView: View {
    // The feed has no currency field; this is a Norwegian marketplace, so prices are NOK.
    private static let priceFormat = IntegerFormatStyle<Int>.Currency(code: "NOK", locale: Locale(identifier: "nb_NO"))
        .precision(.fractionLength(0))

    let ad: Ad

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // The photo says nothing VoiceOver needs; the text below describes the ad.
            AdImageView(url: ad.imageURL, style: ad.imageStyle)
                .accessibilityHidden(true)

            // Reserving two lines keeps card heights equal whatever the title length.
            Text(ad.title)
                .font(.subheadline)
                .lineLimit(2, reservesSpace: true)

            if let price = ad.price {
                Text(price, format: Self.priceFormat)
                    .font(.subheadline.bold())
            }

            if let location = ad.location {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
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
        )
    )
    .padding()
}
