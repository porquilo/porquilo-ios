import SwiftUI

/// The Porquilo compass mark — concentric rings with an accent needle.
/// Reproduces the web app's `LogoMark.tsx` (viewBox 0–64) as a native vector view.
struct LogoMarkView: View {
    var size: CGFloat = 28

    private var scale: CGFloat { size / 64 }

    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * scale, y: y * scale)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignTokens.textPrimary, lineWidth: 2.5 * scale)
                .frame(width: 52 * scale, height: 52 * scale)

            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1 * scale, dash: [1 * scale, 3 * scale]))
                .foregroundStyle(DesignTokens.textPrimary.opacity(0.4))
                .frame(width: 40 * scale, height: 40 * scale)

            Circle()
                .fill(DesignTokens.textPrimary)
                .frame(width: 4 * scale, height: 4 * scale)

            Path { path in
                path.move(to: point(32, 32))
                path.addLine(to: point(36.5, 9.5))
            }
            .stroke(DesignTokens.accent, style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round))

            Path { path in
                path.move(to: point(32, 3))
                path.addLine(to: point(32, 7))
            }
            .stroke(DesignTokens.textPrimary, style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}
