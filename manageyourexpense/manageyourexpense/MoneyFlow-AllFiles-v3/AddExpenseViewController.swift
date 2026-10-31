import UIKit

/// "Add an expense" bottom sheet (also supports income).
final class AddExpenseViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let titleLabel = UILabel.make("Add an expense", font: Theme.Font.bold(28))
    private let typeControl = UISegmentedControl(items: ["Expense".tr, "Income".tr])
    private let amountField = UITextField()
    private let descriptionField = UITextField()
    private let categoryContainer = UIView()
    private let categoryButton = UIButton(type: .system)
    private var selectedCategory: ExpenseCategory = .groceries

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = Theme.Color.background

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = Theme.Spacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 36),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Theme.Spacing.l),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Theme.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Theme.Spacing.l),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * Theme.Spacing.l)
        ])

        buildContent()
        refreshCategoryButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        amountField.becomeFirstResponder()
    }

    // MARK: - UI

    private func buildContent() {
        // Header with close button
        let titles = UIStackView(arrangedSubviews: [UILabel.eyebrow("New transaction"), titleLabel])
        titles.axis = .vertical
        titles.spacing = 6

        var closeConfig = UIButton.Configuration.filled()
        closeConfig.image = UIImage(systemName: "xmark",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        closeConfig.baseBackgroundColor = UIColor(hex: 0xECEEEA)
        closeConfig.baseForegroundColor = Theme.Color.ink
        closeConfig.cornerStyle = .capsule
        let close = UIButton(configuration: closeConfig)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.widthAnchor.constraint(equalToConstant: 44).isActive = true
        close.heightAnchor.constraint(equalToConstant: 44).isActive = true
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [titles, close])
        header.axis = .horizontal
        header.alignment = .top
        stack.addArrangedSubview(header)

        // Expense / Income
        typeControl.selectedSegmentIndex = 0
        typeControl.selectedSegmentTintColor = Theme.Color.ink
        typeControl.setTitleTextAttributes([.foregroundColor: Theme.Color.lime], for: .selected)
        typeControl.setTitleTextAttributes([.foregroundColor: Theme.Color.ink], for: .normal)
        typeControl.heightAnchor.constraint(equalToConstant: 40).isActive = true
        typeControl.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        stack.addArrangedSubview(typeControl)

        // Amount with currency prefix
        style(amountField, placeholder: "0.00", keyboard: .decimalPad)
        let symbol = UILabel.make(DataStore.shared.data.profile.currency.symbol,
                                  font: Theme.Font.medium(18), color: Theme.Color.muted, alignment: .center)
        symbol.sizeToFit()
        let symbolBox = UIView(frame: CGRect(x: 0, y: 0, width: symbol.bounds.width + 28, height: 56))
        symbol.frame.origin = CGPoint(x: 16, y: (56 - symbol.bounds.height) / 2)
        symbolBox.addSubview(symbol)
        amountField.leftView = symbolBox
        stack.addArrangedSubview(labeled("Amount", amountField))

        // Description
        style(descriptionField, placeholder: "What did you spend on?".tr, keyboard: .default)
        descriptionField.autocapitalizationType = .sentences
        stack.addArrangedSubview(labeled("Description", descriptionField))

        // Category menu
        categoryContainer.backgroundColor = Theme.Color.card
        categoryContainer.layer.cornerRadius = 16
        categoryContainer.layer.cornerCurve = .continuous
        categoryContainer.layer.borderWidth = 1
        categoryContainer.layer.borderColor = Theme.Color.border.cgColor
        categoryContainer.heightAnchor.constraint(equalToConstant: 56).isActive = true

        categoryButton.translatesAutoresizingMaskIntoConstraints = false
        categoryButton.showsMenuAsPrimaryAction = true
        categoryButton.contentHorizontalAlignment = .leading
        categoryContainer.addSubview(categoryButton)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.up.chevron.down"))
        chevron.tintColor = Theme.Color.muted
        chevron.isUserInteractionEnabled = false
        chevron.translatesAutoresizingMaskIntoConstraints = false
        categoryContainer.addSubview(chevron)

        NSLayoutConstraint.activate([
            categoryButton.topAnchor.constraint(equalTo: categoryContainer.topAnchor),
            categoryButton.bottomAnchor.constraint(equalTo: categoryContainer.bottomAnchor),
            categoryButton.leadingAnchor.constraint(equalTo: categoryContainer.leadingAnchor),
            categoryButton.trailingAnchor.constraint(equalTo: categoryContainer.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: categoryContainer.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: categoryContainer.trailingAnchor, constant: -16)
        ])
        stack.addArrangedSubview(labeled("Category", categoryContainer))

        // Save
        let save = UIButton.primary(title: "Save")
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stack.addArrangedSubview(save)
        stack.setCustomSpacing(Theme.Spacing.l, after: stack.arrangedSubviews[stack.arrangedSubviews.count - 2])
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

    private func labeled(_ caption: String, _ control: UIView) -> UIView {
        let label = UILabel.make(caption, font: Theme.Font.bold(13))
        let column = UIStackView(arrangedSubviews: [label, control])
        column.axis = .vertical
        column.spacing = Theme.Spacing.s
        return column
    }

    private func makeCategoryMenu() -> UIMenu {
        let actions = ExpenseCategory.allCases.map { category in
            UIAction(title: category.title,
                     image: UIImage(systemName: category.symbolName),
                     state: category == selectedCategory ? .on : .off) { [weak self] _ in
                self?.selectedCategory = category
                self?.refreshCategoryButton()
            }
        }
        return UIMenu(children: actions)
    }

    private func refreshCategoryButton() {
        var config = UIButton.Configuration.plain()
        config.title = selectedCategory.title
        config.baseForegroundColor = Theme.Color.ink
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 40)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Theme.Font.bold(16)
            return attributes
        }
        categoryButton.configuration = config
        categoryButton.menu = makeCategoryMenu()
    }

    // MARK: - Actions

    @objc private func typeChanged() {
        let isIncome = typeControl.selectedSegmentIndex == 1
        titleLabel.text = isIncome ? "Add income".tr : "Add an expense".tr
        descriptionField.placeholder = isIncome ? "Where did it come from?".tr : "What did you spend on?".tr
        categoryContainer.superview?.isHidden = isIncome
    }

    @objc private func saveTapped() {
        guard let amount = Money.parse(amountField.text ?? ""), amount > 0 else {
            let alert = UIAlertController(title: "Check the amount".tr,
                                          message: "Enter an amount greater than zero.".tr,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".tr, style: .default))
            present(alert, animated: true)
            return
        }
        let isIncome = typeControl.selectedSegmentIndex == 1
        var title = (descriptionField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty { title = isIncome ? "Income".tr : selectedCategory.title }

        DataStore.shared.addTransaction(Transaction(title: title,
                                                    amount: amount,
                                                    category: isIncome ? .other : selectedCategory,
                                                    date: Date(),
                                                    isIncome: isIncome,
                                                    isFixedBill: false))
        dismiss(animated: true)
    }
}
