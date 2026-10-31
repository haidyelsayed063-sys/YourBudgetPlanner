import Foundation

enum Currency: String, Codable, CaseIterable {
    case eur, usd, gbp, egp, sar, aed, chf, cny, jpy, cad

    var symbol: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .gbp: return "£"
        case .egp: return "E£"
        case .sar: return "SAR"
        case .aed: return "AED"
        case .chf: return "CHF"
        case .cny: return "CN¥"
        case .jpy: return "JP¥"
        case .cad: return "C$"
        }
    }
    var code: String { rawValue.uppercased() }
}
    
enum ExpenseCategory: String, Codable, CaseIterable {
    case housing, groceries, dining, transport, utilities, subscriptions, shopping, other

    var title: String {
        switch self {
        case .housing:       return "Housing".tr
        case .groceries:     return "Groceries".tr
        case .dining:        return "Dining".tr
        case .transport:     return "Transport".tr
        case .utilities:     return "Utilities & internet".tr
        case .subscriptions: return "Subscriptions".tr
        case .shopping:      return "Shopping".tr
        case .other:         return "Other".tr
        }
    }

    /// SF Symbol name
    var symbolName: String {
        switch self {
        case .housing:       return "house"
        case .groceries:     return "cart"
        case .dining:        return "fork.knife"
        case .transport:     return "car"
        case .utilities:     return "bolt"
        case .subscriptions: return "play.rectangle"
        case .shopping:      return "bag"
        case .other:         return "ellipsis.circle"
        }
    }
}

struct Profile: Codable {
    var monthlySalary: Decimal = 0
    var payday: Int = 1
    var emergencyPercent: Int = 10
    var savingsPercent: Int = 15
    var currency: Currency = .eur
    var hasOnboarded: Bool = false
}

struct FixedExpense: Codable, Identifiable {
    var id = UUID()
    var title: String
    var amount: Decimal
    var dueDay: Int              // 1...31
    var category: ExpenseCategory
    var isEstimated: Bool = false
}

struct Transaction: Codable, Identifiable {
    var id = UUID()
    var title: String
    var amount: Decimal          // always positive; isIncome decides the sign
    var category: ExpenseCategory
    var date: Date = Date()
    var isIncome: Bool = false
    var isFixedBill: Bool = false
}

struct Goal: Codable, Identifiable {
    var id = UUID()
    var title: String
    var targetAmount: Decimal
    var savedAmount: Decimal = 0
    var symbolName: String = "target"
    var isPriority: Bool = false

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let value = Double(truncating: (savedAmount / targetAmount) as NSDecimalNumber)
        return min(max(value, 0), 1)
    }
}

struct AppData: Codable {
    var profile = Profile()
    var fixedExpenses: [FixedExpense] = []
    var transactions: [Transaction] = []
    var goals: [Goal] = []
}
