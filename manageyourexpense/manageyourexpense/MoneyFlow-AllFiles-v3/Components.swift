import UIKit

// MARK: - Money helpers

extension Money {
    /// Accepts "1200", "1200.50" and "1200,50".
    /// Turns Arabic-Indic digits (٠١٢٣) and Arabic separators into normal ones.
    static func normalizeDigits(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for (index, digit) in Array("٠١٢٣٤٥٦٧٨٩").enumerated() {
            result = result.replacingOccurrences(of: String(digit), with: String(index))
        }
        return result
            .replacingOccurrences(of: "٫", with: ".")
            .replacingOccurrences(of: "٬", with: "")
    }

    static func parse(_ text: String) -> Decimal? {
        let cleaned = normalizeDigits(text).replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US"))
    }

    static func parseInt(_ text: String) -> Int? {
        Int(normalizeDigits(text))
    }

    static func percent(_ part: Decimal, of total: Decimal) -> Int {
        guard total > 0 else { return 0 }
        let value = Double(truncating: (part / total) as NSDecimalNumber) * 100
        return Int(value.rounded())
    }
}

extension Int {
    /// 1 -> "1st", 2 -> "2nd", 11 -> "11th"
    var ordinal: String {
        let ones = self % 10
        let tens = (self / 10) % 10
        if tens == 1 { return "\(self)th" }
        switch ones {
        case 1: return "\(self)st"
        case 2: return "\(self)nd"
        case 3: return "\(self)rd"
        default: return "\(self)th"
        }
    }
}

// MARK: - Labels & buttons

extension UILabel {
    static func make(_ text: String,
                     font: UIFont,
                     color: UIColor = Theme.Color.ink,
                     lines: Int = 1,
                     alignment: NSTextAlignment = .natural) -> UILabel {
        let label = UILabel()
        label.text = text.tr
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        label.textAlignment = alignment
        return label
    }

    /// Small spaced uppercase caption ("MAY 2025", "REPEATS EVERY MONTH")
    static func eyebrow(_ text: String) -> UILabel {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: text.tr.uppercased(),
            attributes: [.font: Theme.Font.bold(11),
                         .foregroundColor: Theme.Color.muted,
                         .kern: AppLanguage.current == .ar ? 0 : 1.4])

        return label
    }
}

extension UIButton {
    /// Dark pill button with lime text (like "Save expense" in the design).
    static func primary(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title.tr
        config.baseBackgroundColor = Theme.Color.ink
        config.baseForegroundColor = Theme.Color.lime
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 24, bottom: 18, trailing: 24)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Theme.Font.bold(16)
            return attributes
        }
        return UIButton(configuration: config)
    }
}

// MARK: - Cards

final class TappableView: UIView {
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { onTap?() }
}

func makeCard(content: UIView,
              background: UIColor = Theme.Color.card,
              bordered: Bool = true,
              radius: CGFloat = Theme.Radius.card,
              insets: UIEdgeInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)) -> TappableView {
    let card = TappableView()
    card.backgroundColor = background
    card.layer.cornerRadius = radius
    card.layer.cornerCurve = .continuous
    if bordered {
        card.layer.borderWidth = 1
        card.layer.borderColor = Theme.Color.border.cgColor
    }
    content.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(content)
    NSLayoutConstraint.activate([
        content.topAnchor.constraint(equalTo: card.topAnchor, constant: insets.top),
        content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: insets.left),
        content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -insets.right),
        content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -insets.bottom)
    ])
    return card
}

func makeDivider(color: UIColor = Theme.Color.border) -> UIView {
    let line = UIView()
    line.backgroundColor = color
    line.translatesAutoresizingMaskIntoConstraints = false
    line.heightAnchor.constraint(equalToConstant: 1).isActive = true
    return line
}
