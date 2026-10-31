import UIKit

// MARK: - Extra colors & category look

extension Theme.Color {
    static let positive = UIColor(hex: 0x2E7D4F)
    static let positiveSoft = UIColor(hex: 0xE3F2E8)
}

extension ExpenseCategory {
    var tint: UIColor {
        switch self {
        case .housing, .utilities:       return UIColor(hex: 0x6F63C9)
        case .groceries, .subscriptions: return UIColor(hex: 0xD9803A)
        case .dining, .shopping:         return UIColor(hex: 0xC24D6B)
        case .transport:                 return UIColor(hex: 0x4A7F9E)
        case .other:                     return UIColor(hex: 0x5F6B66)
        }
    }
    var softBackground: UIColor {
        switch self {
        case .housing, .utilities:       return UIColor(hex: 0xECE9FA)
        case .groceries, .subscriptions: return UIColor(hex: 0xFBEBDD)
        case .dining, .shopping:         return UIColor(hex: 0xFBE4EA)
        case .transport:                 return UIColor(hex: 0xE0EEF5)
        case .other:                     return UIColor(hex: 0xECEEEA)
        }
    }
}

// MARK: - Spending groups (donut on Home)

enum SpendingGroup: CaseIterable {
    case housing, food, transport, other

    var title: String {
        switch self {
        case .housing:   return "Housing"
        case .food:      return "Food"
        case .transport: return "Transport"
        case .other:     return "Other"
        }
    }
    var color: UIColor {
        switch self {
        case .housing:   return Theme.Color.lime
        case .food:      return Theme.Color.purple
        case .transport: return Theme.Color.orange
        case .other:     return UIColor(hex: 0xDDE0DA)
        }
    }
    static func group(for category: ExpenseCategory) -> SpendingGroup {
        switch category {
        case .housing, .utilities:               return .housing
        case .groceries, .dining:                return .food
        case .transport:                         return .transport
        case .subscriptions, .shopping, .other:  return .other
        }
    }
}

extension DataStore {
    func expenses(inMonthOf date: Date = Date(), calendar: Calendar = .current) -> [Transaction] {
        data.transactions.filter {
            !$0.isIncome && calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
    }

    func spent(inMonthOf date: Date, calendar: Calendar = .current) -> Decimal {
        expenses(inMonthOf: date, calendar: calendar).reduce(Decimal(0)) { $0 + $1.amount }
    }

    func spendingByGroup(now: Date = Date()) -> [(group: SpendingGroup, amount: Decimal)] {
        let items = expenses(inMonthOf: now)
        return SpendingGroup.allCases.map { group -> (group: SpendingGroup, amount: Decimal) in
            let total = items
                .filter { SpendingGroup.group(for: $0.category) == group }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return (group: group, amount: total)
        }
    }
}

// MARK: - Date helpers

func relativeDayString(_ date: Date, calendar: Calendar = .current) -> String {
    if calendar.isDateInToday(date) { return "Today".tr }
    if calendar.isDateInYesterday(date) { return "Yesterday".tr }
    let formatter = DateFormatter()
    formatter.locale = AppLanguage.current.locale
    formatter.dateFormat = "MMM dd"
    return formatter.string(from: date)
}

func monthName(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = AppLanguage.current.locale
    formatter.dateFormat = "LLLL"
    return formatter.string(from: date)
}

// MARK: - Headers & links

func makeScreenHeader(eyebrow: String, title: String) -> UIView {
    let column = UIStackView(arrangedSubviews: [
        UILabel.eyebrow(eyebrow),
        UILabel.make(title, font: Theme.Font.bold(30), lines: 0)
    ])
    column.axis = .vertical
    column.spacing = 6
    return column
}

func makeLinkButton(_ title: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setAttributedTitle(NSAttributedString(
        string: title.tr,
        attributes: [.font: Theme.Font.bold(12),
                     .foregroundColor: Theme.Color.ink,
                     .underlineStyle: NSUnderlineStyle.single.rawValue]), for: .normal)
    button.setContentHuggingPriority(.required, for: .horizontal)
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
}

func makeSectionHeader(eyebrow: String, title: String, actionTitle: String?, action: (() -> Void)?) -> UIView {
    let titles = UIStackView(arrangedSubviews: [
        UILabel.eyebrow(eyebrow),
        UILabel.make(title, font: Theme.Font.bold(22))
    ])
    titles.axis = .vertical
    titles.spacing = 4

    let row = UIStackView(arrangedSubviews: [titles])
    row.axis = .horizontal
    row.alignment = .bottom
    if let actionTitle = actionTitle, let action = action {
        row.addArrangedSubview(makeLinkButton(actionTitle, action: action))
    }
    return row
}

// MARK: - Progress bar

final class ProgressBarView: UIView {
    private let fillView = UIView()

    var progress: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    init(fill: UIColor, track: UIColor, height: CGFloat = 8) {
        super.init(frame: .zero)
        backgroundColor = track
        fillView.backgroundColor = fill
        addSubview(fillView)
        layer.cornerRadius = height / 2
        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let clamped = min(max(progress, 0), 1)
        fillView.frame = CGRect(x: 0, y: 0, width: bounds.width * clamped, height: bounds.height)
        fillView.layer.cornerRadius = bounds.height / 2
    }
}

// MARK: - Donut chart

final class DonutView: UIView {
    var segments: [(value: Double, color: UIColor)] = [] {
        didSet { setNeedsLayout() }
    }

    private let valueLabel = UILabel.make("", font: Theme.Font.bold(26), alignment: .center)
    private let captionLabel = UILabel.make("", font: Theme.Font.regular(11), color: Theme.Color.muted, alignment: .center)
    private var arcLayers: [CAShapeLayer] = []

    var centerValue: String {
        get { valueLabel.text ?? "" }
        set { valueLabel.text = newValue }
    }
    var centerCaption: String {
        get { captionLabel.text ?? "" }
        set { captionLabel.text = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        arcLayers.forEach { $0.removeFromSuperlayer() }
        arcLayers.removeAll()

        let lineWidth: CGFloat = 24
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        addArc(center: center, radius: radius, from: 0, to: 1, color: Theme.Color.border, lineWidth: lineWidth)

        let total = segments.reduce(0) { $0 + $1.value }
        guard total > 0 else { return }
        var start: CGFloat = 0
        for segment in segments where segment.value > 0 {
            let fraction = CGFloat(segment.value / total)
            addArc(center: center, radius: radius, from: start, to: start + fraction,
                   color: segment.color, lineWidth: lineWidth)
            start += fraction
        }
    }

    private func addArc(center: CGPoint, radius: CGFloat, from: CGFloat, to: CGFloat,
                        color: UIColor, lineWidth: CGFloat) {
        let startAngle = -CGFloat.pi / 2 + 2 * CGFloat.pi * from
        let endAngle = -CGFloat.pi / 2 + 2 * CGFloat.pi * to
        let path = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: startAngle, endAngle: endAngle, clockwise: true)
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = lineWidth
        layer.addSublayer(shape)
        arcLayers.append(shape)
    }
}

// MARK: - Transaction rows

func makeTransactionRow(_ t: Transaction) -> TappableView {
    let symbol = t.isIncome ? "arrow.down.left" : t.category.symbolName
    let tint = t.isIncome ? Theme.Color.positive : t.category.tint
    let soft = t.isIncome ? Theme.Color.positiveSoft : t.category.softBackground

    let icon = UIImageView(image: UIImage(systemName: symbol))
    icon.tintColor = tint
    icon.contentMode = .center
    icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    icon.translatesAutoresizingMaskIntoConstraints = false

    let box = UIView()
    box.backgroundColor = soft
    box.layer.cornerRadius = 16
    box.layer.cornerCurve = .continuous
    box.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(icon)
    NSLayoutConstraint.activate([
        box.widthAnchor.constraint(equalToConstant: 48),
        box.heightAnchor.constraint(equalToConstant: 48),
        icon.topAnchor.constraint(equalTo: box.topAnchor),
        icon.bottomAnchor.constraint(equalTo: box.bottomAnchor),
        icon.leadingAnchor.constraint(equalTo: box.leadingAnchor),
        icon.trailingAnchor.constraint(equalTo: box.trailingAnchor)
    ])

    let kind = t.isIncome ? "Income".tr : t.category.title
    let name = UILabel.make(t.title, font: Theme.Font.bold(15))
    let detail = UILabel.make("\(kind) · \(relativeDayString(t.date))",
                              font: Theme.Font.regular(12), color: Theme.Color.muted)
    let texts = UIStackView(arrangedSubviews: [name, detail])
    texts.axis = .vertical
    texts.spacing = 3

    let sign = t.isIncome ? "+ " : "- "
    let amount = UILabel.make(sign + Money.string(t.amount),
                              font: Theme.Font.bold(14),
                              color: t.isIncome ? Theme.Color.positive : Theme.Color.ink,
                              alignment: .right)
    amount.setContentHuggingPriority(.required, for: .horizontal)
    amount.setContentCompressionResistancePriority(.required, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [box, texts, amount])
    row.axis = .horizontal
    row.spacing = 14
    row.alignment = .center
    row.translatesAutoresizingMaskIntoConstraints = false

    let wrapper = TappableView()
    wrapper.addSubview(row)
    NSLayoutConstraint.activate([
        row.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 12),
        row.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -12),
        row.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
        row.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor)
    ])
    return wrapper
}

func makeTransactionsCard(_ items: [Transaction], onTap: @escaping (Transaction) -> Void) -> UIView {
    let list = UIStackView()
    list.axis = .vertical
    for (index, item) in items.enumerated() {
        if index > 0 { list.addArrangedSubview(makeDivider()) }
        let row = makeTransactionRow(item)
        row.onTap = { onTap(item) }
        list.addArrangedSubview(row)
    }
    return makeCard(content: list, insets: UIEdgeInsets(top: 4, left: 18, bottom: 4, right: 18))
}

func presentDeleteTransaction(_ t: Transaction, from controller: UIViewController) {
    let sheet = UIAlertController(title: t.title,
                                  message: Money.string(t.amount),
                                  preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "Delete".tr, style: .destructive) { _ in
        DataStore.shared.deleteTransaction(id: t.id)
    })
    sheet.addAction(UIAlertAction(title: "Cancel".tr, style: .cancel))
    sheet.popoverPresentationController?.sourceView = controller.view
    sheet.popoverPresentationController?.sourceRect = CGRect(x: controller.view.bounds.midX,
                                                             y: controller.view.bounds.midY,
                                                             width: 0, height: 0)
    controller.present(sheet, animated: true)
}

// MARK: - Base class for scrolling screens

class ScrollScreenViewController: UIViewController {

    let scrollView = UIScrollView()
    let content = UIStackView()

    /// Extra room at the bottom (so the floating + button never hides content).
    var bottomInset: CGFloat { 24 }
    var showsAddButton: Bool { false }

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
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -bottomInset),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Theme.Spacing.l),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Theme.Spacing.l),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * Theme.Spacing.l)
        ])

        if showsAddButton { addFloatingAddButton() }

        NotificationCenter.default.addObserver(self, selector: #selector(reloadScreen),
                                               name: DataStore.didChange, object: nil)
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    @objc private func reloadScreen() { reload() }

    /// Override: rebuild the screen from DataStore.
    func reload() {}

    func goToTab(_ index: Int) {
        tabBarController?.selectedIndex = index
    }

    func presentAddExpense() {
        let vc = AddExpenseViewController()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    private func addFloatingAddButton() {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .bold))
        config.baseBackgroundColor = Theme.Color.lime
        config.baseForegroundColor = Theme.Color.ink
        config.cornerStyle = .large
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowRadius = 10
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.addAction(UIAction { [weak self] _ in self?.presentAddExpense() }, for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 60),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}
