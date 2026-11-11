import Foundation

// These types mirror the JSON field for field and do nothing else.
// The app only ever uses `Ad`; `Ad(response:)` below is the single mapping point.

nonisolated struct AdsResponse: Decodable, Sendable {
    let hasConsent: Bool?
    let isPersonal: Bool?
    let items: [AdResponse]
    let size: Int?
    let version: String?
}

nonisolated struct AdResponse: Decodable, Sendable {
    let id: String
    let adType: String
    let type: String?
    let description: String?
    let location: String?
    let price: Price?
    let image: Image?
    let favourite: Favourite?
    let score: Int?
    let url: String?
    let version: String?
    let content: Content?
    let categories: Categories?
    let overlay: Overlay?
    let shippingOption: ShippingOption?

    private enum CodingKeys: String, CodingKey {
        case id, type, description, location, price, image, favourite, score, url, version
        case content, categories, overlay, shippingOption
        case adType = "ad-type"
    }

    nonisolated struct Price: Decodable, Sendable {
        let value: Int?
        let total: Int?
    }

    nonisolated struct Image: Decodable, Sendable {
        let url: String?
        let type: String?
        let width: Int?
        let height: Int?
        let scalable: Bool?
    }

    nonisolated struct Favourite: Decodable, Sendable {
        let itemId: String?
        let itemType: String?
    }

    nonisolated struct Content: Decodable, Sendable {
        let companyName: String?
        let duration: String?
        let heading: String?
        let jobTitle: String?
        let published: String?
        let publishedRelative: String?
    }

    nonisolated struct Categories: Decodable, Sendable {
        let mainCategory: String?
        let prodCategory: String?
        let subCategory: String?
    }

    nonisolated struct Overlay: Decodable, Sendable {
        let easyapply: EasyApply?
        let label: String?
        let style: String?
    }

    nonisolated struct ShippingOption: Decodable, Sendable {
        let label: String?
    }

    nonisolated struct EasyApply: Decodable, Sendable {
        let label: String?
    }
}

nonisolated extension Ad {
    /// Image paths in the feed are relative to a CDN base. Photos use the base from the brief, which crops to 4:3.
    private static let photoBaseURL = URL(string: "https://images.finncdn.no/dynamic/480x360c/")!
    /// That crop clips wide logos, so they are requested at their own aspect ratio instead.
    /// Not in the brief: found by testing the CDN.
    private static let logoBaseURL = URL(string: "https://images.finncdn.no/dynamic/480w/")!

    init(response: AdResponse) {
        let imageStyle: ImageStyle = response.image?.type == "LOGO" ? .logo : .photo
        let imageBaseURL = imageStyle == .logo ? Self.logoBaseURL : Self.photoBaseURL
        self.init(
            id: response.id,
            // Only `id` and `ad-type` are guaranteed by the backend, so an untitled ad is shown rather than dropped.
            title: response.description ?? "",
            location: response.location,
            price: response.price?.value,
            imageURL: response.image?.url.map { imageBaseURL.appending(path: $0) },
            imageStyle: imageStyle
        )
    }
}
