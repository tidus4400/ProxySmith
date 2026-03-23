import SwiftUI

struct AppPalette {
    let canvas: Color
    let canvasSecondary: Color
    let rail: Color
    let panel: Color
    let raisedPanel: Color
    let insetPanel: Color
    let stagePanel: Color
    let divider: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let primaryAction: Color
    let supportAction: Color
    let highlight: Color
    let destructive: Color
    let shadow: Color
    let warmGlow: Color
    let coolGlow: Color

    static let light = AppPalette(
        canvas: Color(hex: 0xEEE5D6),
        canvasSecondary: Color(hex: 0xF4ECDE),
        rail: Color(hex: 0xD9C9B0),
        panel: Color(hex: 0xFBF6EC),
        raisedPanel: Color(hex: 0xE5D8C2),
        insetPanel: Color(hex: 0xF2E9DB),
        stagePanel: Color(hex: 0xFFF9F0),
        divider: Color(hex: 0xC9BCA8),
        primaryText: Color(hex: 0x1F1A14),
        secondaryText: Color(hex: 0x61564B),
        tertiaryText: Color(hex: 0x7B6F62),
        primaryAction: Color(hex: 0xC8652A),
        supportAction: Color(hex: 0x1F6A66),
        highlight: Color(hex: 0xB89332),
        destructive: Color(hex: 0xA53C30),
        shadow: Color.black.opacity(0.12),
        warmGlow: Color(hex: 0xC8652A).opacity(0.12),
        coolGlow: Color(hex: 0x1F6A66).opacity(0.08)
    )

    static let dark = AppPalette(
        canvas: Color(hex: 0x161311),
        canvasSecondary: Color(hex: 0x1E1815),
        rail: Color(hex: 0x1B1816),
        panel: Color(hex: 0x211C18),
        raisedPanel: Color(hex: 0x2B241F),
        insetPanel: Color(hex: 0x312923),
        stagePanel: Color(hex: 0x1A1613),
        divider: Color(hex: 0x4B4037),
        primaryText: Color(hex: 0xF7EBDD),
        secondaryText: Color(hex: 0xC8B8A4),
        tertiaryText: Color(hex: 0x9F907D),
        primaryAction: Color(hex: 0xE08847),
        supportAction: Color(hex: 0x56A8A0),
        highlight: Color(hex: 0xD4B35D),
        destructive: Color(hex: 0xD36B5C),
        shadow: Color.black.opacity(0.38),
        warmGlow: Color(hex: 0xE08847).opacity(0.12),
        coolGlow: Color(hex: 0x56A8A0).opacity(0.10)
    )
}

struct AppTheme {
    let colorScheme: ColorScheme
    let palette: AppPalette

    init(_ colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
        palette = colorScheme == .dark ? .dark : .light
    }

    func surfaceFill(_ style: SurfaceStyle) -> Color {
        switch style {
        case .rail:
            palette.rail
        case .panel:
            palette.panel
        case .raised:
            palette.raisedPanel
        case .inset:
            palette.insetPanel
        case .stage:
            palette.stagePanel
        }
    }

    func surfaceStroke(_ style: SurfaceStyle) -> Color {
        switch style {
        case .rail:
            palette.divider.opacity(colorScheme == .dark ? 0.55 : 0.85)
        case .panel:
            palette.divider.opacity(colorScheme == .dark ? 0.52 : 0.72)
        case .raised:
            palette.divider.opacity(colorScheme == .dark ? 0.5 : 0.68)
        case .inset:
            palette.divider.opacity(colorScheme == .dark ? 0.45 : 0.6)
        case .stage:
            palette.divider.opacity(colorScheme == .dark ? 0.55 : 0.76)
        }
    }

    func shadow(for style: SurfaceStyle) -> Color {
        switch style {
        case .rail:
            palette.shadow.opacity(colorScheme == .dark ? 0.22 : 0.08)
        case .panel:
            palette.shadow.opacity(colorScheme == .dark ? 0.26 : 0.11)
        case .raised:
            palette.shadow.opacity(colorScheme == .dark ? 0.28 : 0.14)
        case .inset:
            palette.shadow.opacity(colorScheme == .dark ? 0.1 : 0.04)
        case .stage:
            palette.shadow.opacity(colorScheme == .dark ? 0.3 : 0.12)
        }
    }
}

enum SurfaceStyle {
    case rail
    case panel
    case raised
    case inset
    case stage
}

enum AppButtonAppearance {
    case primary
    case support
    case secondary
    case tertiary
    case destructive
}

struct WorkshopPanelModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let style: SurfaceStyle
    let cornerRadius: CGFloat
    let padding: CGFloat

    func body(content: Content) -> some View {
        let theme = AppTheme(colorScheme)
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .padding(padding)
            .background {
                shape
                    .fill(theme.surfaceFill(style))
            }
            .overlay {
                shape
                    .stroke(theme.surfaceStroke(style), lineWidth: 1)
            }
            .shadow(color: theme.shadow(for: style), radius: style.shadowRadius, y: style.shadowYOffset)
    }
}

struct AppButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    let appearance: AppButtonAppearance

    func makeBody(configuration: Configuration) -> some View {
        let theme = AppTheme(colorScheme)
        let colors = colors(for: theme)
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(colors.foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background {
                shape.fill(colors.background.opacity(configuration.isPressed ? 0.9 : 1))
            }
            .overlay {
                shape.stroke(colors.stroke, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }

    private func colors(for theme: AppTheme) -> (foreground: Color, background: Color, stroke: Color) {
        switch appearance {
        case .primary:
            return (.white, theme.palette.primaryAction, theme.palette.primaryAction.opacity(0.85))
        case .support:
            return (.white, theme.palette.supportAction, theme.palette.supportAction.opacity(0.85))
        case .secondary:
            return (theme.palette.primaryText, theme.palette.raisedPanel, theme.palette.divider.opacity(0.9))
        case .tertiary:
            return (theme.palette.primaryText, Color.clear, theme.palette.divider.opacity(0.8))
        case .destructive:
            return (.white, theme.palette.destructive, theme.palette.destructive.opacity(0.85))
        }
    }
}

struct WorkshopInputFieldModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let fillStyle: SurfaceStyle

    func body(content: Content) -> some View {
        let theme = AppTheme(colorScheme)
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                shape.fill(theme.surfaceFill(fillStyle))
            }
            .overlay {
                shape.stroke(theme.surfaceStroke(fillStyle), lineWidth: 1)
            }
    }
}

extension View {
    func workshopPanel(
        _ style: SurfaceStyle = .panel,
        cornerRadius: CGFloat = 22,
        padding: CGFloat = 20
    ) -> some View {
        modifier(WorkshopPanelModifier(style: style, cornerRadius: cornerRadius, padding: padding))
    }

    func appButtonStyle(_ appearance: AppButtonAppearance) -> some View {
        buttonStyle(AppButtonStyle(appearance: appearance))
    }

    func workshopInputField(cornerRadius: CGFloat = 14, fillStyle: SurfaceStyle = .inset) -> some View {
        modifier(WorkshopInputFieldModifier(cornerRadius: cornerRadius, fillStyle: fillStyle))
    }
}

private extension SurfaceStyle {
    var shadowRadius: CGFloat {
        switch self {
        case .rail:
            12
        case .panel:
            16
        case .raised:
            12
        case .inset:
            0
        case .stage:
            18
        }
    }

    var shadowYOffset: CGFloat {
        switch self {
        case .rail:
            6
        case .panel:
            10
        case .raised:
            8
        case .inset:
            0
        case .stage:
            12
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
