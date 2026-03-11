import SwiftUI

struct GlassPanelModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .padding(padding)
            .background(.white.opacity(0.04), in: shape)
            .glassEffect(.regular, in: shape)
            .overlay {
                shape
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 26, y: 16)
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 28, padding: CGFloat = 22) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

