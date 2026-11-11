import Foundation

extension Ad {
    // The feed has no currency field; this is a Norwegian marketplace, so prices are NOK.
    private static let priceFormat = IntegerFormatStyle<Int>.Currency(code: "NOK", locale: Locale(identifier: "nb_NO"))
        .precision(.fractionLength(0))

    /// Formatted to a String on purpose: `Text(_:format:)` would swap in the device locale
    /// and print "NOK" instead of "kr".
    var formattedPrice: String? {
        price?.formatted(Self.priceFormat)
    }
}
