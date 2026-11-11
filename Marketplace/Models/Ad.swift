import Foundation

/// What the app shows and later saves as a favorite. Deliberately independent of the
/// backend's JSON format, so an API change never breaks saved favorites.
nonisolated struct Ad: Identifiable, Hashable, Codable, Sendable {
    enum ImageStyle: String, Codable, Sendable {
        case photo
        case logo
    }

    let id: String
    let title: String
    let location: String?
    /// Whole NOK. `nil` for ads without a price, such as job ads.
    let price: Int?
    let imageURL: URL?
    let imageStyle: ImageStyle
}
