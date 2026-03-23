import SwiftUI

struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = AppTheme(colorScheme)

        ZStack {
            LinearGradient(
                colors: [
                    theme.palette.canvasSecondary,
                    theme.palette.canvas
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Ellipse()
                .fill(theme.palette.warmGlow)
                .frame(width: 520, height: 360)
                .blur(radius: 80)
                .offset(x: 360, y: -260)

            Ellipse()
                .fill(theme.palette.coolGlow)
                .frame(width: 420, height: 300)
                .blur(radius: 70)
                .offset(x: -320, y: 260)

            Rectangle()
                .fill(.clear)
                .overlay {
                    Canvas { context, size in
                        let spacing: CGFloat = 34
                        let majorSpacing = spacing * 4
                        let minorLine = theme.palette.divider.opacity(colorScheme == .dark ? 0.08 : 0.16)
                        let majorLine = theme.palette.divider.opacity(colorScheme == .dark ? 0.14 : 0.22)

                        for x in stride(from: 0, through: size.width, by: spacing) {
                            let color = x.truncatingRemainder(dividingBy: majorSpacing) == 0 ? majorLine : minorLine
                            context.fill(
                                Path(CGRect(x: x, y: 0, width: 1, height: size.height)),
                                with: .color(color)
                            )
                        }

                        for y in stride(from: 0, through: size.height, by: spacing) {
                            let color = y.truncatingRemainder(dividingBy: majorSpacing) == 0 ? majorLine : minorLine
                            context.fill(
                                Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                                with: .color(color)
                            )
                        }
                    }
                }
                .blendMode(colorScheme == .dark ? .overlay : .multiply)
                .opacity(colorScheme == .dark ? 0.45 : 0.32)
        }
        .ignoresSafeArea()
    }
}
