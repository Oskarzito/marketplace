import Foundation

extension Ad {
    // The feed has no currency field and this is a Norwegian marketplace, so NOK it is.
    private static let priceFormat = IntegerFormatStyle<Int>.Currency(code: "NOK", locale: Locale(identifier: "nb_NO"))
        .precision(.fractionLength(0))

    // A String on purpose: `Text(_:format:)` uses the device locale and would print "NOK" instead of "kr".
    var formattedPrice: String? {
        price?.formatted(Self.priceFormat)
    }
}
