import UIKit

/// First-launch setup. Also used (with isEditing: true) to change salary / percentages later.
final class OnboardingViewController: UIViewController {

    private let isEditingPlan: Bool
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let salaryField = UITextField()
    private let paydayField = UITextField()
    private let emergencyField = UITextField()
    private let savingsField = UITextField()
    private let currencyButton = UIButton(type: .system)
    private let languageButton = UIButton(type: .system)
    private var selectedCurrency: Currency = .eur
    private var selectedLanguage: AppLanguage = AppLanguage.current

    init(isEditing: Bool = false) {
        isEditingPlan = isEditing
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = Theme.Color.background

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = Theme.Spacing.l
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Theme.Spacing.l),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Theme.Spacing.l),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Theme.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Theme.Spacing.l),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * Theme.Spacing.l)
        ])

        buildContent()
        prefill()
    }

    // MARK: - UI

    private func buildContent() {
        if isEditingPlan {
            let cancel = UIButton(type: .system)
            cancel.setTitle("Cancel".tr, for: .normal)
            cancel.titleLabel?.font = Theme.Font.medium(16)
            cancel.tintColor = Theme.Color.ink
            cancel.contentHorizontalAlignment = .trailing
            cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
            stack.addArrangedSubview(cancel)
        }

        let header = UIStackView(arrangedSubviews: [
            UILabel.eyebrow(isEditingPlan ? "Your plan" : "Welcome to MoneyFlow"),
            UILabel.make(isEditingPlan ? "Update your plan" : "Let's set up your salary plan",
                         font: Theme.Font.bold(32), lines: 0),
            UILabel.make("Tell us what you earn. We split it for you: bills first, then savings, then what is safe to spend.",
                         font: Theme.Font.regular(15), color: Theme.Color.muted, lines: 0)
        ])
        header.axis = .vertical
        header.spacing = Theme.Spacing.s
        stack.addArrangedSubview(header)

        style(salaryField, placeholder: "0", keyboard: .decimalPad)
        style(paydayField, placeholder: "1", keyboard: .numberPad)
        style(emergencyField, placeholder: "10", keyboard: .numberPad)
        style(savingsField, placeholder: "15", keyboard: .numberPad)

        styleMenuButton(currencyButton)
        styleMenuButton(languageButton)
        refreshMenus()

        stack.addArrangedSubview(labeled("Currency", currencyButton))
        stack.addArrangedSubview(labeled("Language", languageButton))
        stack.addArrangedSubview(labeled("Monthly salary", salaryField))
        stack.addArrangedSubview(labeled("Payday (day of the month)", paydayField))
        stack.addArrangedSubview(labeled("Emergency fund (% of salary)", emergencyField))
        stack.addArrangedSubview(labeled("Savings (% of salary)", savingsField))

        let button = UIButton.primary(title: isEditingPlan ? "Save changes" : "Continue")
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stack.addArrangedSubview(button)
    }

    private func style(_ field: UITextField, placeholder: String, keyboard: UIKeyboardType) {
        field.placeholder = placeholder
        field.keyboardType = keyboard
        field.font = Theme.Font.medium(18)
        field.textColor = Theme.Color.ink
        field.backgroundColor = Theme.Color.card
        field.layer.cornerRadius = 16
        field.layer.cornerCurve = .continuous
        field.layer.borderWidth = 1
        field.layer.borderColor = Theme.Color.border.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    private func styleMenuButton(_ button: UIButton) {
        button.backgroundColor = Theme.Color.card
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = Theme.Color.border.cgColor
        button.contentHorizontalAlignment = .leading
        button.showsMenuAsPrimaryAction = true
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }

    private func labeled(_ caption: String, _ control: UIView) -> UIView {
        let label = UILabel.make(caption, font: Theme.Font.medium(13), color: Theme.Color.muted)
        let column = UIStackView(arrangedSubviews: [label, control])
        column.axis = .vertical
        column.spacing = Theme.Spacing.s
        return column
    }

    private func prefill() {
        let profile = DataStore.shared.data.profile
        if profile.monthlySalary > 0 {
            salaryField.text = NSDecimalNumber(decimal: profile.monthlySalary).stringValue
        }
        paydayField.text = String(profile.payday)
        emergencyField.text = String(profile.emergencyPercent)
        savingsField.text = String(profile.savingsPercent)
        selectedCurrency = profile.currency
        selectedLanguage = AppLanguage.current
        refreshMenus()
    }

    private func refreshMenus() {
        var currencyConfig = UIButton.Configuration.plain()
        currencyConfig.title = selectedCurrency.code + " (" + selectedCurrency.symbol + ")"
        currencyConfig.baseForegroundColor = Theme.Color.ink
        currencyConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        currencyButton.configuration = currencyConfig
        
        let currencyActions = Currency.allCases.map { c in
            UIAction(title: c.code + " (" + c.symbol + ")", state: c == selectedCurrency ? .on : .off) { [weak self] _ in
                self?.selectedCurrency = c
                self?.refreshMenus()
            }
        }
        currencyButton.menu = UIMenu(children: currencyActions)

        var langConfig = UIButton.Configuration.plain()
        langConfig.title = selectedLanguage.nativeName
        langConfig.baseForegroundColor = Theme.Color.ink
        langConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        languageButton.configuration = langConfig

        let langActions = AppLanguage.allCases.map { l in
            UIAction(title: l.nativeName, state: l == selectedLanguage ? .on : .off) { [weak self] _ in
                self?.selectedLanguage = l
                self?.refreshMenus()
            }
        }
        languageButton.menu = UIMenu(children: langActions)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let salary = Money.parse(salaryField.text ?? ""), salary > 0 else {
            showError("Enter your monthly salary.".tr)
            return
        }
        guard let payday = Money.parseInt(paydayField.text ?? ""), (1...31).contains(payday) else {
            showError("Payday must be a day between 1 and 31.".tr)
            return
        }
        guard let emergency = Money.parseInt(emergencyField.text ?? ""),
              let savings = Money.parseInt(savingsField.text ?? ""),
              emergency >= 0, savings >= 0, emergency + savings <= 100 else {
            showError("Emergency and savings percentages must be numbers, and together not more than 100.".tr)
            return
        }

        DataStore.shared.update { data in
            data.profile.monthlySalary = salary
            data.profile.payday = payday
            data.profile.emergencyPercent = emergency
            data.profile.savingsPercent = savings
            data.profile.currency = selectedCurrency
            data.profile.hasOnboarded = true
        }
        let languageChanged = selectedLanguage != AppLanguage.current
        AppLanguage.current = selectedLanguage
        dismiss(animated: true) {
            if languageChanged { LanguageManager.reloadUI() }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Check your details".tr, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".tr, style: .default))
        present(alert, animated: true)
    }
}
