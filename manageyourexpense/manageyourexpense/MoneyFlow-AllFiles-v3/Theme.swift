import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

/// Design tokens. Colors are approximate: replace the hex values with the exact ones from Figma.
enum Theme {

    enum Color {
        static let background = UIColor(hex: 0xF7F7F2)
        static let card       = UIColor.white
        static let ink        = UIColor(hex: 0x16211C)   // dark green/black
        static let lime       = UIColor(hex: 0xDFFF6B)   // main accent
        static let purple     = UIColor(hex: 0x7B6FD0)
        static let orange     = UIColor(hex: 0xE9A46A)
        static let muted      = UIColor(hex: 0x7A8580)
        static let border     = UIColor(hex: 0xE4E6E0)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat  = 8
        static let m: CGFloat  = 16
        static let l: CGFloat  = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat  = 12
        static let button: CGFloat = 20
        static let card: CGFloat   = 24
    }

    /// DM Sans (add the .ttf files + UIAppFonts in Info.plist). Falls back to the system font until then.
    enum Font {
        private static func font(_ name: String, _ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
        }
        static func regular(_ size: CGFloat) -> UIFont { font("DMSans-Regular", size, .regular) }
        static func medium(_ size: CGFloat) -> UIFont { font("DMSans-Medium", size, .medium) }
        static func bold(_ size: CGFloat) -> UIFont { font("DMSans-Bold", size, .bold) }
    }
}

extension UIView {
    /// White rounded card with a thin border, like in the design.
    func applyCardStyle(background: UIColor = Theme.Color.card) {
        backgroundColor = background
        layer.cornerRadius = Theme.Radius.card
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Theme.Color.border.cgColor
    }
}
