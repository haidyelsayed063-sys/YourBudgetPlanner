
import UIKit

final class HomeViewController: ScrollScreenViewController {
    
    override var bottomInset: CGFloat { 110 }
    override var showsAddButton: Bool { true }
    
    
    override func reload() {
        let store = DataStore.shared
        let s = store.summary()
        let profile = store.data.profile
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        content.addArrangedSubview(makeScreenHeader(
            eyebrow: String(format: "%@ money snapshot".tr, monthName(Date())),
            title: String(format: "Know where every %@ goes.".tr, currencyNoun(profile.currency))))
        
        let balance = makeBalanceCard(s)
        content.addArrangedSubview(balance)
        content.addArrangedSubview(makeSmartMoveCard(s, profile: profile))
        
        let sectionOne = makeSectionHeader(eyebrow: "This month".tr, title: "Where it went".tr,
                                           actionTitle: "View plan".tr) { [weak self] in self?.goToTab(1) }
        content.addArrangedSubview(sectionOne)
        content.setCustomSpacing(Theme.Spacing.xl, after: content.arrangedSubviews[content.arrangedSubviews.count - 2])
        content.addArrangedSubview(makeBreakdownCard(s))
        
        let sectionTwo = makeSectionHeader(eyebrow: "Recent".tr, title: "Latest activity".tr,
                                           actionTitle: "See all".tr) { [weak self] in self?.goToTab(2) }
        content.setCustomSpacing(Theme.Spacing.xl, after: content.arrangedSubviews[content.arrangedSubviews.count - 1])
        content.addArrangedSubview(sectionTwo)
        
        let latest = Array(store.data.transactions.sorted { $0.date > $1.date }.prefix(3))
        if latest.isEmpty {
            let label = UILabel.make("No transactions yet. Tap the + button to add your first expense.".tr,
                                     font: Theme.Font.regular(14), color: Theme.Color.muted, lines: 0)
            content.addArrangedSubview(makeCard(content: label, radius: 22))
        } else {
            content.addArrangedSubview(makeTransactionsCard(latest) { [weak self] transaction in
                guard let self = self else { return }
                presentDeleteTransaction(transaction, from: self)
            })
        }
    }
    
    private func currencyNoun(_ currency: Currency) -> String {
        switch currency {
        case .eur: return "euro".tr
        case .usd, .cad: return "dollar".tr
        case .gbp: return "pound".tr
        case .egp: return "Egyptian pound".tr
        case .sar: return "riyal".tr
        case .aed: return "dirham".tr
        case .chf: return "franc".tr
        case .cny: return "yuan".tr
        case .jpy: return "yen".tr
        }
    }
    
    // MARK: - Cards
    
    private func makeBalanceCard(_ s: BudgetSummary) -> UIView {
        let soft = UIColor.white.withAlphaComponent(0.7)
        
        let title = UILabel.make("Left this month".tr, font: Theme.Font.medium(14), color: soft)
        let amount = UILabel.make(Money.string(s.left), font: Theme.Font.bold(52), color: .white)
        amount.adjustsFontSizeToFitWidth = true
        amount.minimumScaleFactor = 0.5
        
        let formatSub = "After savings, spend up to %@ per day".tr
        let fullSubText = String(format: formatSub, Money.string(s.dailyLimit))
        
        let subLabel = UILabel()
        subLabel.font = Theme.Font.regular(14)
        subLabel.textColor = soft
        subLabel.text = fullSubText
        subLabel.numberOfLines = 0
        
        let bar = ProgressBarView(fill: Theme.Color.lime, track: UIColor.white.withAlphaComponent(0.15))
        bar.progress = CGFloat(s.spentFraction)
        
        let spentText = String(format: "%@ spent".tr, Money.string(s.spent))
        let salaryText = String(format: "%@ salary".tr, Money.string(s.salary))
        
        let spent = UILabel.make(spentText, font: Theme.Font.regular(11), color: soft)
        let salary = UILabel.make(salaryText, font: Theme.Font.regular(11), color: soft)
        let labels = UIStackView(arrangedSubviews: [spent, salary])
        labels.axis = .horizontal
        labels.distribution = .equalSpacing
        
        let inner = UIStackView(arrangedSubviews: [title, amount, subLabel, bar, labels])
        inner.axis = .vertical
        inner.spacing = 10
        inner.setCustomSpacing(22, after: title)
        inner.setCustomSpacing(22, after: subLabel)
        
        let card = makeCard(content: inner,
                            background: Theme.Color.ink,
                            bordered: false,
                            radius: 32,
                            insets: UIEdgeInsets(top: 26, left: 24, bottom: 24, right: 24))
        card.clipsToBounds = true
        
        let decor = UIView()
        decor.backgroundColor = Theme.Color.lime
        decor.layer.cornerRadius = 70
        decor.translatesAutoresizingMaskIntoConstraints = false
        card.insertSubview(decor, at: 0)
        
        let daysFormat = "%d days left".tr
        let days = UILabel.make(String(format: daysFormat, s.daysLeft), font: Theme.Font.bold(11), color: Theme.Color.ink)
        days.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(days)
        
        NSLayoutConstraint.activate([
            decor.widthAnchor.constraint(equalToConstant: 140),
            decor.heightAnchor.constraint(equalToConstant: 140),
            decor.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 50),
            decor.topAnchor.constraint(equalTo: card.topAnchor, constant: -50),
            days.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            days.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22)
        ])
        return card
    }
    
    private func makeSmartMoveCard(_ s: BudgetSummary, profile: Profile) -> UIView {
        let hasSalary = s.salary > 0
        let titleFormat = "Set aside %@ for emergencies".tr
        let titleText = hasSalary ? String(format: titleFormat, Money.string(s.emergency)) : "Set your monthly salary".tr
        
        let subtitleFormat = "That's %d%% of your salary, before extra spending.".tr
        let subtitleText = hasSalary
        ? String(format: subtitleFormat, profile.emergencyPercent)
        : "Add it in the Plan tab and we will build your plan.".tr
        
        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = Theme.Color.ink
        icon.contentMode = .center
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let box = UIView()
        box.backgroundColor = Theme.Color.lime
        box.layer.cornerRadius = 16
        box.layer.cornerCurve = .continuous
        box.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(icon)
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: 52),
            box.heightAnchor.constraint(equalToConstant: 52),
            icon.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
        
        let texts = UIStackView(arrangedSubviews: [
            UILabel.eyebrow("Smart move".tr),
            UILabel.make(titleText, font: Theme.Font.bold(15), lines: 0),
            UILabel.make(subtitleText, font: Theme.Font.regular(12), color: Theme.Color.muted, lines: 0)
        ])
        texts.axis = .vertical
        texts.spacing = 3
        
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = Theme.Color.muted
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        
        let row = UIStackView(arrangedSubviews: [box, texts, chevron])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        
        let card = makeCard(content: row, radius: 24,
                            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 18))
        card.onTap = { [weak self] in self?.goToTab(1) }
        return card
    }
    
    private func makeBreakdownCard(_ s: BudgetSummary) -> UIView {
        let groups = DataStore.shared.spendingByGroup()
        
        let donut = DonutView()
        donut.translatesAutoresizingMaskIntoConstraints = false
        donut.widthAnchor.constraint(equalToConstant: 150).isActive = true
        donut.heightAnchor.constraint(equalToConstant: 150).isActive = true
        donut.segments = groups.map { (value: Double(truncating: $0.amount as NSDecimalNumber), color: $0.group.color) }
        donut.centerValue = "\(Money.percent(s.spent, of: s.salary))%"
        donut.centerCaption = "used".tr
        
        let legend = UIStackView(arrangedSubviews: groups.map { legendRow($0.group, $0.amount) })
        legend.axis = .vertical
        legend.spacing = 14
        
        let row = UIStackView(arrangedSubviews: [donut, legend])
        row.axis = .horizontal
        row.spacing = 20
        row.alignment = .center
        
        return makeCard(content: row, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }
    
    private func legendRow(_ group: SpendingGroup, _ amount: Decimal) -> UIView {
        let dot = UIView()
        dot.backgroundColor = group.color
        dot.layer.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        let name = UILabel.make(group.title.tr, font: Theme.Font.regular(13))
        name.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let value = UILabel.make(Money.string(amount), font: Theme.Font.bold(13), alignment: .right)
        value.setContentHuggingPriority(.required, for: .horizontal)
        
        let row = UIStackView(arrangedSubviews: [dot, name, value])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }
}
