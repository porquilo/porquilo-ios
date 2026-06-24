import SwiftUI

extension Color {
    init(light: String, dark: String) {
        self.init(uiColor: UIColor(light: light, dark: dark))
    }
}

private extension UIColor {
    convenience init(light: String, dark: String) {
        self.init { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }

    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

enum DesignTokens {
    // Surfaces
    static let background = Color(light: "#F2F0E8", dark: "#0E0B08")
    static let backgroundElevated = Color(light: "#FAFAF5", dark: "#1F1B15")
    static let backgroundSunken = Color(light: "#E9E5D8", dark: "#060403")

    // Accent
    static let accent = Color(light: "#B8431D", dark: "#E07553")
    static let accentHover = Color(light: "#8C2F11", dark: "#EF8869")

    // Text
    static let textPrimary = Color(light: "#1A140C", dark: "#F5EDDD")
    static let textSecondary = Color(light: "#2C2317", dark: "#D6CCB6")
    static let textTertiary = Color(light: "#6B6353", dark: "#A29888")
    static let textMuted = Color(light: "#9E9684", dark: "#6A6155")

    // Borders
    static let border = Color(light: "#BFB6A0", dark: "#3A2F22")
    static let borderStrong = Color(light: "#8A8273", dark: "#524432")

    // Confidence — Measured (scale only)
    static let confidenceMeasuredFg = Color(light: "#455A1C", dark: "#C8DC75")
    static let confidenceMeasuredBg = Color(light: "#E5EBC8", dark: "#2A331A")
    static let confidenceMeasuredDot = Color(light: "#6A8530", dark: "#B5C765")

    // Confidence — Estimated (everything else)
    static let confidenceEstimatedFg = Color(light: "#7E5A05", dark: "#F0C46A")
    static let confidenceEstimatedBg = Color(light: "#FAE6B3", dark: "#3A2E12")
    static let confidenceEstimatedDot = Color(light: "#C18A0F", dark: "#E8B556")
}

extension Font {
    /// Newsreader 38pt light — optical size 36. Falls back to system serif until
    /// Newsreader .ttf assets are added to the bundle.
    static var porqDisplay: Font {
        .custom("Newsreader", size: 38, relativeTo: .largeTitle).weight(.light)
    }

    static var porqHeading: Font {
        .custom("Newsreader", size: 22, relativeTo: .title2)
    }

    static var porqBody: Font {
        .custom("Geist", size: 16, relativeTo: .body)
    }

    static var porqSmall: Font {
        .custom("Geist", size: 14, relativeTo: .footnote)
    }

    static var porqCaption: Font {
        .custom("Geist", size: 12, relativeTo: .caption)
    }

    static var porqMono: Font {
        .custom("Geist Mono", size: 15, relativeTo: .body)
    }

    /// Scale-readout numeral.
    static var porqWeight: Font {
        .custom("Geist Mono", size: 44, relativeTo: .largeTitle).weight(.medium)
    }
}
