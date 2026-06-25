import SwiftUI

extension Color {
    init(light: String, dark: String) {
        self.init(uiColor: UIColor(light: light, dark: dark))
    }

    /// For tokens whose dark variant carries alpha (e.g. a translucent accent wash)
    /// that the plain hex-string initializer above can't represent.
    init(light: String, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(hex: light)
        })
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
    static let accentSoftBackground = Color(
        light: "#FBE3D5",
        dark: Color(.sRGB, red: 224 / 255, green: 117 / 255, blue: 83 / 255, opacity: 0.14)
    )

    // Text
    static let textPrimary = Color(light: "#1A140C", dark: "#F5EDDD")
    static let textSecondary = Color(light: "#2C2317", dark: "#D6CCB6")
    static let textTertiary = Color(light: "#6B6353", dark: "#A29888")
    static let textMuted = Color(light: "#9E9684", dark: "#6A6155")
    static let textOnAccent = Color(light: "#FAFAF5", dark: "#0E0B08")

    // Borders
    static let border = Color(light: "#BFB6A0", dark: "#3A2F22")
    static let borderStrong = Color(light: "#8A8273", dark: "#524432")
    static let borderSoft = border.opacity(0.5)

    // Shadows
    static let shadowColor = Color(light: "#1A140C", dark: "#000000")

    // Status — danger
    static let dangerForeground = Color(light: "#6F2818", dark: "#E89478")
    static let dangerBackground = Color(
        light: "#F8D9D1",
        dark: Color(.sRGB, red: 216 / 255, green: 105 / 255, blue: 73 / 255, opacity: 0.18)
    )

    // Status — success
    static let successForeground = Color(light: "#455A1C", dark: "#C8DC75")
    static let successBackground = Color(
        light: "#E5EBC8",
        dark: Color(.sRGB, red: 165 / 255, green: 188 / 255, blue: 73 / 255, opacity: 0.18)
    )

    // Status — warning
    static let warningForeground = Color(light: "#7E5A05", dark: "#F0C46A")
    static let warningBackground = Color(light: "#FAE6B3", dark: "#3A2E12")
    static let warningBorder = Color(light: "#E8C572", dark: "#5A4520")

    // Confidence — Measured (scale only)
    static let confidenceMeasuredFg = Color(light: "#455A1C", dark: "#C8DC75")
    static let confidenceMeasuredBg = Color(light: "#E5EBC8", dark: "#2A331A")
    static let confidenceMeasuredDot = Color(light: "#6A8530", dark: "#B5C765")

    // Confidence — Estimated (everything else)
    static let confidenceEstimatedFg = Color(light: "#7E5A05", dark: "#F0C46A")
    static let confidenceEstimatedBg = Color(light: "#FAE6B3", dark: "#3A2E12")
    static let confidenceEstimatedDot = Color(light: "#C18A0F", dark: "#E8B556")

    // Macro nutrients
    static let herb500 = Color(light: "#6A8530", dark: "#B5C765")
    static let honey500 = Color(light: "#C18A0F", dark: "#E8B556")
    static let clay500 = Color(light: "#B8431D", dark: "#E07553")

    // Accent — soft variants (e.g. Quick log card)
    static let accentSoftForeground = accentHover
    static let accentSoftBorder = Color(light: "#F0C9AE", dark: "#4A2A1D")
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

/// Approximates the design system's `--shadow-2` token (a two-layer box-shadow that,
/// in dark mode, also adds an `inset` highlight). SwiftUI has no inset-shadow primitive,
/// so the inset layer is intentionally dropped here rather than faked — only the
/// dominant outer-shadow layer is applied per color scheme.
private struct Shadow2Modifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 2)
        } else {
            content
                .shadow(color: Color(red: 26 / 255, green: 18 / 255, blue: 11 / 255, opacity: 0.08), radius: 4, x: 0, y: 2)
                .shadow(color: Color(red: 26 / 255, green: 18 / 255, blue: 11 / 255, opacity: 0.05), radius: 0, x: 0, y: 1)
        }
    }
}

/// Approximates the design system's `--shadow-1` token — a single, lighter outer shadow
/// used for smaller surfaces like diary entry rows.
private struct Shadow1Modifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
        } else {
            content.shadow(color: Color(red: 26 / 255, green: 18 / 255, blue: 11 / 255, opacity: 0.06), radius: 2, x: 0, y: 1)
        }
    }
}

extension View {
    func applyShadow2() -> some View {
        modifier(Shadow2Modifier())
    }

    func applyShadow1() -> some View {
        modifier(Shadow1Modifier())
    }
}
