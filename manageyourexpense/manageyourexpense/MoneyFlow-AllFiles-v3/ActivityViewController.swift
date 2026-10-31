
import UIKit

final class ActivityViewController: ScrollScreenViewController {

    private enum Filter: String, CaseIterable {
        case all = "All"
        case expenses = "Expenses"
        case income = "Income"
        case recurring = "Recurring"
    }

    private var filter: Filter = .all

    override var bottomInset: CGFloat { 110 }
    override var showsAddButton: Bool { true }

    override func reload() {
        let store = DataStore.shared
        let s = store.summary()
        let calendar = Calendar.current
        let now = Date()
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }

        content.addArrangedSubview(makeScreenHeader(eyebrow: "All transactions".tr, title: "Exactly where it went".tr))

        let stats = makeStatsRow(s, store: store, calendar: calendar, now: now)
        content.addArrangedSubview(stats)
        content.addArrangedSubview(makeChips())

        let sorted = store.data.transactions.sorted { $0.date > $1.date }
        let filtered = sorted.filter { t -> Bool in
            switch filter {
            case .all:       return true
            case .expenses:  return !t.isIncome
            case .income:    return t.isIncome
            case .recurring: return t.isFixedBill
            }
        }

        let today = filtered.filter { calendar.isDateInToday($0.date) }
        let earlier = filtered.filter {
            !calendar.isDateInToday($0.date) && calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        let older = filtered.filter { !calendar.isDate($0.date, equalTo: now, toGranularity: .month) }

        let sections: [(String, [Transaction])] = [("Today".tr, today), ("Earlier this month".tr, earlier), ("Older".tr, older)]
        var addedAny = false
        for (title, items) in sections where !items.isEmpty {
            addedAny = true
            content.addArrangedSubview(UILabel.eyebrow(title))
            content.addArrangedSubview(makeTransactionsCard(items) { [weak self] transaction in
                guard let self = self else { return }
                presentDeleteTransaction(transaction, from: self)
            })
        }
        if !addedAny {
            let label = UILabel.make("Nothing here yet. Tap the + button to add a transaction.".tr,
                                     font: Theme.Font.regular(14), color: Theme.Color.muted, lines: 0)
            content.addArrangedSubview(makeCard(content: label, radius: 22))
        }
    }

    private func makeStatsRow(_ s: BudgetSummary, store: DataStore, calendar: Calendar, now: Date) -> UIView {
        let previous = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let previousSpent = store.spent(inMonthOf: previous, calendar: calendar)

        var deltaText = "This month so far".tr
        var deltaColor = Theme.Color.muted
        if previousSpent > 0 {
            let change = (s.spent - previousSpent) / previousSpent * 100
            let rounded = Int(Double(truncating: change as NSDecimalNumber).rounded())
            let arrow = rounded <= 0 ? "↓" : "↑"
            deltaText = String(format: "%@ %d%% vs. %@".tr, arrow, abs(rounded), monthName(previous))
            deltaColor = rounded <= 0 ? Theme.Color.positive : UIColor(hex: 0xC2562F)
        }

        let row = UIStackView(arrangedSubviews: [
            statCard(caption: String(format: "Spent in %@".tr, monthName(now)), value: Money.string(s.spent),
                     note: deltaText, noteColor: deltaColor),
            statCard(caption: "Still available".tr, value: Money.string(s.left),
                     note: String(format: "%d days left".tr, s.daysLeft), noteColor: Theme.Color.positive)
        ])
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually
        return row
    }

    private func statCard(caption: String, value: String, note: String, noteColor: UIColor) -> UIView {
        let valueLabel = UILabel.make(value, font: Theme.Font.bold(26))
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6
        let column = UIStackView(arrangedSubviews: [
            UILabel.make(caption, font: Theme.Font.regular(12), color: Theme.Color.muted),
            valueLabel,
            UILabel.make(note, font: Theme.Font.medium(11), color: noteColor)
        ])
        column.axis = .vertical
        column.spacing = 6
        return makeCard(content: column, radius: 22,
                        insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
    }

    private func makeChips() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8

        for option in Filter.allCases {
            let selected = option == filter
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = selected ? Theme.Color.ink : Theme.Color.card
            config.baseForegroundColor = selected ? UIColor.white : Theme.Color.ink
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            config.background.strokeColor = Theme.Color.border
            config.titleLineBreakMode = .byClipping
            
            // الترجمة التلقائية لخيارات الفلتر
            let translatedTitle: String
            switch option {
            case .all: translatedTitle = "All".tr
            case .expenses: translatedTitle = "Expenses".tr
            case .income: translatedTitle = "Income".tr
            case .recurring: translatedTitle = "Recurring".tr
            }
            config.title = translatedTitle

            config.background.strokeWidth = selected ? 0 : 1
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = Theme.Font.medium(13)
                return attributes
            }
            let button = UIButton(configuration: config)
            button.addAction(UIAction { [weak self] _ in
                self?.filter = option
                self?.reload()
            }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        row.translatesAutoresizingMaskIntoConstraints = false
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            row.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 44)
        ])
        return scroll
    }
}
