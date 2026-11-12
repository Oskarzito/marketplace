import Foundation

nonisolated struct Ad: Identifiable, Hashable, Codable, Sendable {
    enum ImageStyle: String, Codable, Sendable {
        case photo
        case logo
    }

    let id: String
    let title: String
    let location: String?
    // Whole NOK. `nil` when the ad has no price, like job ads.
    let price: Int?
    let imageURL: URL?
    let imageStyle: ImageStyle
}
