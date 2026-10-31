import Foundation

//What the Home / Plan / Activity screens show. Everything is computed from real data.
struct BudgetSummary {
    let salary: Decimal
    let fixedTotal: Decimal
    let emergency: Decimal       // salary * emergencyPercent
    let savings: Decimal         // salary * savingsPercent
    let flexible: Decimal        // salary - fixed - emergency - savings
    let spent: Decimal           // all expenses this month
    let left: Decimal            // salary - spent
    let flexibleLeft: Decimal    // flexible budget not yet spent
    let daysLeft: Int
    let dailyLimit: Decimal
    let spentFraction: Double    // 0...1
}

final class DataStore {
    static let shared = DataStore()
    static let didChange = Notification.Name("DataStore.didChange")

    private(set) var data: AppData
    private let fileURL: URL

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("moneyflow.json")
        fileURL = url
        if let raw = try? Data(contentsOf: url),
           let decoded = try? DataStore.decoder.decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }
    }

    // MARK: - Writing

    /// Single entry point for every change: edits data, saves to disk, notifies the screens.
    func update(_ change: (inout AppData) -> Void) {
        change(&data)
        save()
        NotificationCenter.default.post(name: DataStore.didChange, object: nil)
    }

    func addTransaction(_ transaction: Transaction) {
        update { $0.transactions.append(transaction) }
    }

    func deleteTransaction(id: UUID) {
        update { $0.transactions.removeAll { $0.id == id } }
    }

    private func save() {
        do {
            let raw = try DataStore.encoder.encode(data)
            try raw.write(to: fileURL, options: [.atomic])
        } catch {
            print("DataStore save failed:", error)
        }
    }

    // MARK: - Calculations

    func summary(now: Date = Date(), calendar: Calendar = .current) -> BudgetSummary {
        let profile = data.profile
        let salary = profile.monthlySalary
        let fixedTotal = data.fixedExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let emergency = salary * Decimal(profile.emergencyPercent) / 100
        let savings = salary * Decimal(profile.savingsPercent) / 100
        let flexible = salary - fixedTotal - emergency - savings

        let expenses = data.transactions.filter {
            !$0.isIncome && calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        let spent = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let flexibleSpent = expenses.filter { !$0.isFixedBill }.reduce(Decimal(0)) { $0 + $1.amount }
        let flexibleLeft = max(flexible - flexibleSpent, Decimal(0))
        let income = data.transactions.filter {
            $0.isIncome && calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }.reduce(Decimal(0)) { $0 + $1.amount }

        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let today = calendar.component(.day, from: now)
        let daysLeft = max(1, daysInMonth - today + 1)   // includes today

        var fraction = 0.0
        if salary > 0 {
            fraction = Double(truncating: (spent / salary) as NSDecimalNumber)
        }

        return BudgetSummary(salary: salary,
                             fixedTotal: fixedTotal,
                             emergency: emergency,
                             savings: savings,
                             flexible: flexible,
                             spent: spent,
                             left: salary + income - spent,
                             flexibleLeft: flexibleLeft,
                             daysLeft: daysLeft,
                             dailyLimit: flexibleLeft / Decimal(daysLeft),
                             spentFraction: min(max(fraction, 0), 1))
    }
}

#if DEBUG
extension DataStore {
    /// Fake data to preview the screens. Debug builds only, remove once onboarding exists.
    func loadSampleData(calendar: Calendar = .current) {
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now

        update { d in
            d.profile = Profile(monthlySalary: 4200, payday: 1, emergencyPercent: 10,
                                savingsPercent: 15, currency: .eur, hasOnboarded: true)
            d.fixedExpenses = [
                FixedExpense(title: "Rent", amount: 1400, dueDay: 1, category: .housing),
                FixedExpense(title: "Utilities & internet", amount: 160, dueDay: 8, category: .utilities, isEstimated: true),
                FixedExpense(title: "Subscriptions", amount: 90, dueDay: 15, category: .subscriptions)
            ]
            d.transactions = [
                Transaction(title: "Green Market", amount: 68, category: .groceries, date: now),
                Transaction(title: "Metro & taxi", amount: 24, category: .transport, date: yesterday),
                Transaction(title: "Apartment rent", amount: 1400, category: .housing, date: monthStart, isFixedBill: true)
            ]
            d.goals = [
                Goal(title: "Emergency fund", targetAmount: 5040, savedAmount: 2100, symbolName: "shield", isPriority: true),
                Goal(title: "Summer trip", targetAmount: 1200, savedAmount: 840, symbolName: "airplane"),
                Goal(title: "New laptop", targetAmount: 2200, savedAmount: 380, symbolName: "laptopcomputer")
            ]
        }
    }
}
#endif
