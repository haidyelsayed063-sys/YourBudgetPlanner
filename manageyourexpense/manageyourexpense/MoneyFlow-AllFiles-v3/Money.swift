import Foundation

enum Money {
    /// "€1,920" (or "€1,920.50" with showCents)
    static func string(_ amount: Decimal,
                       currency: Currency = DataStore.shared.data.profile.currency,
                       showCents: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")   // stable grouping: 1,920
        formatter.currencySymbol = currency.symbol
        formatter.minimumFractionDigits = showCents ? 2 : 0
        formatter.maximumFractionDigits = showCents ? 2 : 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)0"
    }
}
