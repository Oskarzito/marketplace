import SwiftUI

struct AdCardView: View {
    let ad: Ad

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // The clear 4:3 shape fixes the size up front, so the layout doesn't jump as images arrive.
            Color.clear
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    AsyncImage(url: ad.imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.secondary.opacity(0.15)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(ad.title)
                .font(.subheadline)
                .lineLimit(2)

            if let price = ad.price {
                Text("\(price) kr")
                    .font(.subheadline.bold())
            }

            if let location = ad.location {
                Text(location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
