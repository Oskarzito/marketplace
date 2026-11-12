import SwiftUI

struct AdCardView: View {
    let ad: Ad
    let imageData: Data?
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        // The heart sits beside the link, not inside it: tapping it favorites the ad instead of
        // opening it, and VoiceOver keeps it as its own control.
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: ad) {
                VStack(alignment: .leading, spacing: 0) {
                    // The photo says nothing VoiceOver needs; the text below describes the ad.
                    AdImageView(url: ad.imageURL, storedData: imageData, style: ad.imageStyle)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        // Reserving two lines keeps card heights equal whatever the title length.
                        Text(ad.title)
                            .font(.subheadline)
                            .lineLimit(2, reservesSpace: true)

                        if let price = ad.formattedPrice {
                            Text(price)
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
            }
            .buttonStyle(CardPressStyle())

            FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
                .background(.regularMaterial, in: Circle())
                .padding(6)
        }
    }
}

/// The plain button style shows almost nothing while pressed, so the card gives its own feedback.
private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
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
}
