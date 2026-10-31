
import UIKit

/// Real "Plan" screen. The storyboard keeps using the class name PlanViewController, nothing to change there.
final class PlanViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let content = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.background

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        content.axis = .vertical
        content.spacing = Theme.Spacing.m
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Theme.Spacing.l),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Theme.Spacing.l),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Theme.Spacing.l),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Theme.Spacing.l),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * Theme.Spacing.l)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: DataStore.didChange, object: nil)
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Build

    @objc private func reload() {
        let store = DataStore.shared
        let summary = store.summary()
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }

        content.addArrangedSubview(makeHeader())
        content.addArrangedSubview(makeSalaryCard(summary))

        let split = makeSplitRow(summary)
        content.addArrangedSubview(split)
        content.setCustomSpacing(Theme.Spacing.xl, after: split)

        content.addArrangedSubview(makeSectionHeader())

        let bills = store.data.fixedExpenses.sorted { $0.dueDay < $1.dueDay }
        if bills.isEmpty {
            content.addArrangedSubview(makeEmptyBillsCard())
        } else {
            for (index, bill) in bills.enumerated() {
                content.addArrangedSubview(makeBillCard(bill, index: index))
            }
        }

        content.addArrangedSubview(makePaydayOrderCard(summary))
    }

    private func makeHeader() -> UIView {
        let column = UIStackView(arrangedSubviews: [
            UILabel.eyebrow(monthName(Date())),
            UILabel.make("Plan before you spend".tr, font: Theme.Font.bold(30), lines: 0)
        ])
        column.axis = .vertical
        column.spacing = 6
        return column
    }

    private func makeSalaryCard(_ s: BudgetSummary) -> UIView {
        let titleText = s.salary > 0 ? "Monthly salary".tr : "Tap here to set your monthly salary".tr
        let title = UILabel.make(titleText, font: Theme.Font.medium(14))
        let amount = UILabel.make(Money.string(s.salary), font: Theme.Font.bold(44))
        amount.adjustsFontSizeToFitWidth = true
        amount.minimumScaleFactor = 0.6

        let left = column(value: Money.string(s.fixedTotal), caption: "fixed bills".tr, alignment: .leading)
        let right = column(value: Money.string(s.emergency + s.savings), caption: "save first".tr, alignment: .trailing)
        let bottom = UIStackView(arrangedSubviews: [left, right])
        bottom.axis = .horizontal
        bottom.distribution = .equalSpacing

        let inner = UIStackView(arrangedSubviews: [title, amount, makeDivider(color: Theme.Color.ink.withAlphaComponent(0.15)), bottom])
        inner.axis = .vertical
        inner.spacing = 12
        inner.setCustomSpacing(20, after: amount)

        let card = makeCard(content: inner,
                            background: Theme.Color.lime,
                            bordered: false,
                            radius: 28,
                            insets: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24))
        card.onTap = { [weak self] in self?.editPlan() }   // tap to edit salary / percentages
        return card
    }

    private func column(value: String, caption: String, alignment: UIStackView.Alignment) -> UIView {
        let valueLabel = UILabel.make(value, font: Theme.Font.bold(17))
        let captionLabel = UILabel.make(caption, font: Theme.Font.regular(12),
                                        color: Theme.Color.ink.withAlphaComponent(0.65))
        let column = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
        column.axis = .vertical
        column.spacing = 2
        column.alignment = alignment
        return column
    }

    private func makeSplitRow(_ s: BudgetSummary) -> UIView {
        let profile = DataStore.shared.data.profile
        let items: [(String, Decimal, String, UIColor)] = [
            ("Emergency".tr, s.emergency, "\(profile.emergencyPercent)%", Theme.Color.ink),
            ("Savings".tr, s.savings, "\(profile.savingsPercent)%", Theme.Color.ink),
            ("Flexible".tr, s.flexible, "\(Money.percent(s.flexible, of: s.salary))%",
             s.flexible < 0 ? Theme.Color.orange : Theme.Color.ink)
        ]

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually

        for item in items {
            let caption = UILabel.make(item.0, font: Theme.Font.regular(12), color: Theme.Color.muted)
            let value = UILabel.make(Money.string(item.1), font: Theme.Font.bold(18), color: item.3)
            value.adjustsFontSizeToFitWidth = true
            value.minimumScaleFactor = 0.7
            let percent = UILabel.make(item.2, font: Theme.Font.regular(12), color: Theme.Color.muted)

            let inner = UIStackView(arrangedSubviews: [caption, value, percent])
            inner.axis = .vertical
            inner.spacing = 4
            row.addArrangedSubview(makeCard(content: inner,
                                            radius: 18,
                                            insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)))
        }
        return row
    }

    private func makeSectionHeader() -> UIView {
        let titles = UIStackView(arrangedSubviews: [
            UILabel.eyebrow("Repeats every month".tr),
            UILabel.make("Your fixed expenses".tr, font: Theme.Font.bold(22))
        ])
        titles.axis = .vertical
        titles.spacing = 4

        let add = UIButton(type: .system)
        add.setAttributedTitle(NSAttributedString(
            string: "+ Add bill".tr,
            attributes: [.font: Theme.Font.bold(12),
                         .foregroundColor: Theme.Color.ink,
                         .underlineStyle: NSUnderlineStyle.single.rawValue]), for: .normal)
        add.setContentHuggingPriority(.required, for: .horizontal)
        add.addTarget(self, action: #selector(addBillTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [titles, add])
        row.axis = .horizontal
        row.alignment = .bottom
        return row
    }

    private func makeBillCard(_ bill: FixedExpense, index: Int) -> UIView {
        let badgeColors = [Theme.Color.lime, Theme.Color.purple, Theme.Color.orange]
        let badgeColor = badgeColors[index % badgeColors.count]
        let isPurple = index % badgeColors.count == 1

        let badge = UIView()
        badge.backgroundColor = badgeColor
        badge.layer.cornerRadius = 16
        badge.layer.cornerCurve = .continuous
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: 52).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let day = UILabel.make("\(bill.dueDay)", font: Theme.Font.bold(18),
                               color: isPurple ? UIColor.white : Theme.Color.ink)
        day.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(day)
        day.centerXAnchor.constraint(equalTo: badge.centerXAnchor).isActive = true
        day.centerYAnchor.constraint(equalTo: badge.centerYAnchor).isActive = true

        let kind = bill.isEstimated ? "Estimated".tr : "Fixed".tr
        let name = UILabel.make(bill.title, font: Theme.Font.bold(17))
        let detail = UILabel.make(String(format: "Due on the %@ · %@".tr, AppLanguage.current == .en ? bill.dueDay.ordinal : "\(bill.dueDay)", kind),
                                  font: Theme.Font.regular(12), color: Theme.Color.muted)
        let texts = UIStackView(arrangedSubviews: [name, detail])
        texts.axis = .vertical
        texts.spacing = 3

        let amount = UILabel.make(Money.string(bill.amount), font: Theme.Font.bold(16))
        amount.setContentHuggingPriority(.required, for: .horizontal)
        amount.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [badge, texts, amount])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center

        let card = makeCard(content: row,
                            radius: 22,
                            insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 18))
        card.onTap = { [weak self] in self?.confirmDelete(bill) }
        return card
    }

    private func makeEmptyBillsCard() -> UIView {
        let label = UILabel.make("No fixed bills yet. Add your rent, utilities and subscriptions so we can plan around them.".tr,
                                 font: Theme.Font.regular(14), color: Theme.Color.muted, lines: 0)
        return makeCard(content: label, radius: 22)
    }

    private func makePaydayOrderCard(_ s: BudgetSummary) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = Theme.Color.lime
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let title = UILabel.make("Your simple payday order".tr, font: Theme.Font.bold(15), color: .white)
        let body = UILabel.make(String(format: "First bills, then %@ emergency money, then %@ savings. What remains is safe for daily life.".tr, Money.string(s.emergency), Money.string(s.savings)),
                                font: Theme.Font.regular(12),
                                color: UIColor.white.withAlphaComponent(0.75),
                                lines: 0)
        let texts = UIStackView(arrangedSubviews: [title, body])
        texts.axis = .vertical
        texts.spacing = 4

        let row = UIStackView(arrangedSubviews: [icon, texts])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top

        return makeCard(content: row,
                        background: Theme.Color.ink,
                        bordered: false,
                        radius: 24,
                        insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }

    // MARK: - Actions

    private func editPlan() {
        let vc = OnboardingViewController(isEditing: true)
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    @objc private func addBillTapped() {
        let alert = UIAlertController(title: "Add a fixed bill".tr,
                                      message: "Something that repeats every month.".tr,
                                      preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "Name (e.g. Rent)".tr
            $0.autocapitalizationType = .sentences
        }
        alert.addTextField {
            $0.placeholder = "Amount".tr
            $0.keyboardType = .decimalPad
        }
        alert.addTextField {
            $0.placeholder = "Due day (1-31)".tr
            $0.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Cancel".tr, style: .cancel))
        alert.addAction(UIAlertAction(title: "Add".tr, style: .default) { [weak self, weak alert] _ in
            let fields = alert?.textFields ?? []
            guard fields.count == 3 else { return }
            let name = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty,
                  let amount = Money.parse(fields[1].text ?? ""), amount > 0,
                  let day = Money.parseInt(fields[2].text ?? ""), (1...31).contains(day) else {
                self?.showMessage("Please enter a name, an amount and a day between 1 and 31.".tr)
                return
            }
            let category = PlanViewController.guessCategory(name)
            DataStore.shared.update {
                $0.fixedExpenses.append(FixedExpense(title: name, amount: amount, dueDay: day, category: category))
            }
        })
        present(alert, animated: true)
    }

    private func confirmDelete(_ bill: FixedExpense) {
        let sheet = UIAlertController(title: bill.title,
                                      message: String(format: "%@ every month".tr, Money.string(bill.amount)),
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Delete bill".tr, style: .destructive) { _ in
            DataStore.shared.update { $0.fixedExpenses.removeAll { $0.id == bill.id } }
        })
        sheet.addAction(UIAlertAction(title: "Cancel".tr, style: .cancel))
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        present(sheet, animated: true)
    }

    private func showMessage(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".tr, style: .default))
        present(alert, animated: true)
    }

    private static func guessCategory(_ name: String) -> ExpenseCategory {
        let lower = name.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { lower.contains($0) } }
        if has(["rent", "mortgage", "housing"]) { return .housing }
        if has(["internet", "electric", "water", "gas", "utilit", "phone"]) { return .utilities }
        if has(["netflix", "spotify", "subscri", "gym", "icloud"]) { return .subscriptions }
        return .other
    }
}
