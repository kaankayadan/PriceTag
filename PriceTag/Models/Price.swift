import Foundation

// MARK: - Price Model
public struct Price {
    // MARK: Properties
    public let value: Double
    public var currency: String  // currency artık değiştirilebilir
    
    // MARK: Initialization
    public init(value: Double, currency: String = "") {
        self.value = value
        self.currency = currency
    }
}

// MARK: - Formatting Helper
extension Price {
    var formatted: String {
        return "\(currency) \(String(format: "%.2f", value))"
    }
}

// MARK: - Currency Symbols
extension Price {
    static let availableCurrencies = ["USD", "EUR", "GBP", "JPY", "TRY"]
    
    static func currencySymbol(for currency: String) -> String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "TRY": return "₺"
        default: return currency
        }
    }
}

// MARK: - Protocol Conformance
extension Price: Equatable, Hashable {}
