import UIKit

/// Custom class of the Tab Bar Controller in Main.storyboard.
/// Tabs are found by screen type, so the order in the storyboard does not matter.
final class MainTabBarController: UITabBarController {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Arabic = right-to-left. Must run before the screens are created.
        LanguageManager.applyDirection()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light   // remove when Dark Mode colors are ready

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.Color.card

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = Theme.Color.muted
        normal.titleTextAttributes = [.foregroundColor: Theme.Color.muted, .font: Theme.Font.medium(11)]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = Theme.Color.ink
        selected.titleTextAttributes = [.foregroundColor: Theme.Color.ink, .font: Theme.Font.bold(11)]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = Theme.Color.ink

        configureTabs()
    }

    private func configureTabs() {
        func root(of controller: UIViewController) -> UIViewController {
            (controller as? UINavigationController)?.viewControllers.first ?? controller
        }

        // Wanted order: Home, Plan, Activity, Goals
        let order: [(type: UIViewController.Type, title: String, symbol: String)] = [
            (HomeViewController.self, "Home", "house"),
            (PlanViewController.self, "Plan", "list.bullet.rectangle"),
            (ActivityViewController.self, "Activity", "chart.bar"),
            (GoalsViewController.self, "Goals", "scope")
        ]

        let current = viewControllers ?? []
        var sorted: [UIViewController] = []
        for item in order {
            if let controller = current.first(where: { type(of: root(of: $0)) == item.type }) {
                controller.tabBarItem = UITabBarItem(title: item.title.tr,
                                                     image: UIImage(systemName: item.symbol),
                                                     selectedImage: nil)
                sorted.append(controller)
            }
        }
        if sorted.count == current.count { viewControllers = sorted }
    }
}
