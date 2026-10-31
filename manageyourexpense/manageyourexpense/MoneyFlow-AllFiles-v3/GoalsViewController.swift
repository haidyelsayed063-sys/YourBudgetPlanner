import UIKit

final class GoalsViewController: ScrollScreenViewController {

    override func reload() {
        let store = DataStore.shared
        let s = store.summary()
        let goals = store.data.goals
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }

        content.addArrangedSubview(makeScreenHeader(eyebrow: "Your safety net", title: "Save with a purpose"))

        let hero = goals.first(where: { $0.isPriority }) ?? goals.first
        if let hero = hero {
            content.addArrangedSubview(makeHeroCard(hero, fixedTotal: s.fixedTotal))
            if let tip = makeTipCard(hero, summary: s) {
                content.addArrangedSubview(tip)
            }
        } else {
            let label = UILabel.make("No goals yet. Create your first one, for example an emergency fund of 3 months of fixed expenses.",
                                     font: Theme.Font.regular(14), color: Theme.Color.muted, lines: 0)
            content.addArrangedSubview(makeCard(content: label, radius: 22))
        }

        let header = makeSectionHeader(eyebrow: "Next up", title: "More goals", actionTitle: "+ New goal") { [weak self] in
            self?.presentNewGoal()
        }
        if let last = content.arrangedSubviews.last {
            content.setCustomSpacing(Theme.Spacing.xl, after: last)
        }
        content.addArrangedSubview(header)

        let others = goals.filter { $0.id != hero?.id }
        for (index, goal) in others.enumerated() {
            content.addArrangedSubview(makeGoalRow(goal, index: index))
        }
    }

    // MARK: - Cards

    private func makeHeroCard(_ goal: Goal, fixedTotal: Decimal) -> UIView {
        // Illustration
        let art = UIView()
        art.backgroundColor = UIColor(hex: 0xD3DFE5)
        art.clipsToBounds = true
        art.translatesAutoresizingMaskIntoConstraints = false
        art.heightAnchor.constraint(equalToConstant: 170).isActive = true

        let safe = UILabel.make("SAFE", font: Theme.Font.bold(80), color: UIColor.white.withAlphaComponent(0.6))
        safe.translatesAutoresizingMaskIntoConstraints = false

        let circle = UIView()
        circle.backgroundColor = Theme.Color.lime
        circle.layer.cornerRadius = 55
        circle.translatesAutoresizingMaskIntoConstraints = false

        let square = UIView()
        square.backgroundColor = Theme.Color.ink
        square.layer.cornerRadius = 24
        square.layer.cornerCurve = .continuous
        square.transform = CGAffineTransform(rotationAngle: -0.12)
        square.translatesAutoresizingMaskIntoConstraints = false

        let sparkle = UIImageView(image: UIImage(systemName: "sparkle"))
        sparkle.tintColor = Theme.Color.lime
        sparkle.contentMode = .center
        sparkle.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 34, weight: .bold)
        sparkle.translatesAutoresizingMaskIntoConstraints = false
        square.addSubview(sparkle)

        art.addSubview(safe)
        art.addSubview(circle)
        art.addSubview(square)
        NSLayoutConstraint.activate([
            safe.leadingAnchor.constraint(equalTo: art.leadingAnchor, constant: 16),
            safe.bottomAnchor.constraint(equalTo: art.bottomAnchor, constant: 16),
            circle.widthAnchor.constraint(equalToConstant: 110),
            circle.heightAnchor.constraint(equalToConstant: 110),
            circle.centerXAnchor.constraint(equalTo: art.centerXAnchor, constant: 92),
            circle.centerYAnchor.constraint(equalTo: art.centerYAnchor, constant: -10),
            square.widthAnchor.constraint(equalToConstant: 96),
            square.heightAnchor.constraint(equalToConstant: 96),
            square.centerXAnchor.constraint(equalTo: art.centerXAnchor),
            square.centerYAnchor.constraint(equalTo: art.centerYAnchor, constant: -10),
            sparkle.centerXAnchor.constraint(equalTo: square.centerXAnchor),
            sparkle.centerYAnchor.constraint(equalTo: square.centerYAnchor)
        ])

        // Info
        let percent = Int(goal.progress * 100)
        var caption = String(format: "%d%% there".tr, percent)
        if fixedTotal > 0 { caption += " · 3 months of fixed expenses is your target".tr }

        let saved = UILabel.make(Money.string(goal.savedAmount), font: Theme.Font.bold(24))
        let target = UILabel.make(String(format: "of %@".tr, Money.string(goal.targetAmount)), font: Theme.Font.regular(12),
                                  color: Theme.Color.muted, alignment: .right)
        let amounts = UIStackView(arrangedSubviews: [saved, target])
        amounts.axis = .horizontal
        amounts.alignment = .lastBaseline
        amounts.distribution = .equalSpacing

        let bar = ProgressBarView(fill: Theme.Color.lime, track: Theme.Color.border, height: 10)
        bar.progress = CGFloat(goal.progress)

        let info = UIStackView(arrangedSubviews: [
            UILabel.eyebrow("Top priority"),
            UILabel.make(goal.title, font: Theme.Font.bold(24)),
            amounts,
            bar,
            UILabel.make(caption, font: Theme.Font.regular(11), color: Theme.Color.muted, lines: 0)
        ])
        info.axis = .vertical
        info.spacing = 10
        info.isLayoutMarginsRelativeArrangement = true
        info.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        let column = UIStackView(arrangedSubviews: [art, info])
        column.axis = .vertical

        let card = makeCard(content: column, radius: 28, insets: .zero)
        card.clipsToBounds = true
        card.onTap = { [weak self] in self?.presentGoalActions(goal) }
        return card
    }

    private func makeTipCard(_ goal: Goal, summary s: BudgetSummary) -> UIView? {
        let remaining = goal.targetAmount - goal.savedAmount
        guard s.emergency > 0, remaining > 0 else { return nil }
        let months = Int(ceil(Double(truncating: (remaining / s.emergency) as NSDecimalNumber)))
        let percent = DataStore.shared.data.profile.emergencyPercent

        let badge = UILabel.make("\(percent)%", font: Theme.Font.bold(14), color: Theme.Color.ink, alignment: .center)
        let badgeBox = UIView()
        badgeBox.backgroundColor = Theme.Color.lime
        badgeBox.layer.cornerRadius = 24
        badgeBox.translatesAutoresizingMaskIntoConstraints = false
        badge.translatesAutoresizingMaskIntoConstraints = false
        badgeBox.addSubview(badge)
        NSLayoutConstraint.activate([
            badgeBox.widthAnchor.constraint(equalToConstant: 48),
            badgeBox.heightAnchor.constraint(equalToConstant: 48),
            badge.centerXAnchor.constraint(equalTo: badgeBox.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: badgeBox.centerYAnchor)
        ])

        let monthsText = months == 1 ? "1 month".tr : String(format: "%d months".tr, months)
        let texts = UIStackView(arrangedSubviews: [
            UILabel.make(String(format: "Move %@ here on payday".tr, Money.string(s.emergency)), font: Theme.Font.bold(14), color: .white, lines: 0),
            UILabel.make(String(format: "At this pace, your safety net will be ready in %@.".tr, monthsText),
                         font: Theme.Font.regular(11), color: UIColor.white.withAlphaComponent(0.7), lines: 0)
        ])
        texts.axis = .vertical
        texts.spacing = 3

        let sparkles = UIImageView(image: UIImage(systemName: "sparkles"))
        sparkles.tintColor = Theme.Color.lime
        sparkles.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [badgeBox, texts, sparkles])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center

        return makeCard(content: row, background: Theme.Color.ink, bordered: false, radius: 24,
                        insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 20))
    }

    private func makeGoalRow(_ goal: Goal, index: Int) -> UIView {
        let looks: [(UIColor, UIColor)] = [
            (UIColor(hex: 0x4A7F9E), UIColor(hex: 0xE0EEF5)),
            (UIColor(hex: 0xC24D6B), UIColor(hex: 0xFBE4EA)),
            (UIColor(hex: 0x6F63C9), UIColor(hex: 0xECE9FA))
        ]
        let look = looks[index % looks.count]

        let icon = UIImageView(image: UIImage(systemName: goal.symbolName))
        icon.tintColor = look.0
        icon.contentMode = .center
        icon.translatesAutoresizingMaskIntoConstraints = false
        let box = UIView()
        box.backgroundColor = look.1
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

        let name = UILabel.make(goal.title, font: Theme.Font.bold(15))
        let percent = UILabel.make("\(Int(goal.progress * 100))%", font: Theme.Font.bold(13), alignment: .right)
        percent.setContentHuggingPriority(.required, for: .horizontal)
        let top = UIStackView(arrangedSubviews: [name, percent])
        top.axis = .horizontal

        let detail = UILabel.make(String(format: "%@ of %@".tr, Money.string(goal.savedAmount), Money.string(goal.targetAmount)),
                                  font: Theme.Font.regular(12), color: Theme.Color.muted)
        let bar = ProgressBarView(fill: Theme.Color.purple, track: Theme.Color.border, height: 6)
        bar.progress = CGFloat(goal.progress)

        let texts = UIStackView(arrangedSubviews: [top, detail, bar])
        texts.axis = .vertical
        texts.spacing = 6

        let row = UIStackView(arrangedSubviews: [box, texts])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center

        let card = makeCard(content: row, radius: 22,
                            insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 18))
        card.onTap = { [weak self] in self?.presentGoalActions(goal) }
        return card
    }

    // MARK: - Actions

    private func presentNewGoal() {
        let alert = UIAlertController(title: "New goal".tr, message: "What are you saving for?".tr, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "Name (e.g. Summer trip)".tr
            $0.autocapitalizationType = .sentences
        }
        alert.addTextField {
            $0.placeholder = "Target amount".tr
            $0.keyboardType = .decimalPad
        }
        alert.addTextField {
            $0.placeholder = "Already saved (optional)".tr
            $0.keyboardType = .decimalPad
        }
        alert.addAction(UIAlertAction(title: "Cancel".tr, style: .cancel))
        alert.addAction(UIAlertAction(title: "Create".tr, style: .default) { [weak self, weak alert] _ in
            let fields = alert?.textFields ?? []
            guard fields.count == 3 else { return }
            let name = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, let target = Money.parse(fields[1].text ?? ""), target > 0 else {
                self?.showMessage("Please enter a name and a target amount.".tr)
                return
            }
            let saved = Money.parse(fields[2].text ?? "") ?? 0
            DataStore.shared.update { data in
                let isFirst = data.goals.isEmpty
                data.goals.append(Goal(title: name, targetAmount: target, savedAmount: saved,
                                       symbolName: "target", isPriority: isFirst))
            }
        })
        present(alert, animated: true)
    }

    private func presentGoalActions(_ goal: Goal) {
        let sheet = UIAlertController(title: goal.title,
                                      message: String(format: "%@ of %@".tr, Money.string(goal.savedAmount), Money.string(goal.targetAmount)),
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Add money".tr, style: .default) { [weak self] _ in
            self?.presentAddMoney(goal)
        })
        if !goal.isPriority {
            sheet.addAction(UIAlertAction(title: "Make top priority".tr, style: .default) { _ in
                DataStore.shared.update { data in
                    for index in data.goals.indices {
                        data.goals[index].isPriority = (data.goals[index].id == goal.id)
                    }
                }
            })
        }
        sheet.addAction(UIAlertAction(title: "Delete goal".tr, style: .destructive) { _ in
            DataStore.shared.update { data in
                data.goals.removeAll { $0.id == goal.id }
            }
        })
        sheet.addAction(UIAlertAction(title: "Cancel".tr, style: .cancel))
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        present(sheet, animated: true)
    }

    private func presentAddMoney(_ goal: Goal) {
        let alert = UIAlertController(title: String(format: "Add to %@".tr, goal.title), message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "Amount".tr
            $0.keyboardType = .decimalPad
        }
        alert.addAction(UIAlertAction(title: "Cancel".tr, style: .cancel))
        alert.addAction(UIAlertAction(title: "Add".tr, style: .default) { [weak self, weak alert] _ in
            guard let amount = Money.parse(alert?.textFields?.first?.text ?? ""), amount > 0 else {
                self?.showMessage("Please enter an amount greater than zero.".tr)
                return
            }
            DataStore.shared.update { data in
                for index in data.goals.indices where data.goals[index].id == goal.id {
                    data.goals[index].savedAmount += amount
                }
            }
        })
        present(alert, animated: true)
    }

    private func showMessage(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".tr, style: .default))
        present(alert, animated: true)
    }
}
