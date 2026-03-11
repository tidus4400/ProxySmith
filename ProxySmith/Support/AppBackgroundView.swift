import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.11, blue: 0.15),
                    Color(red: 0.13, green: 0.15, blue: 0.18),
                    Color(red: 0.18, green: 0.15, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.95, green: 0.55, blue: 0.28).opacity(0.25))
                .frame(width: 460, height: 460)
                .blur(radius: 60)
                .offset(x: 420, y: -240)

            Circle()
                .fill(Color(red: 0.33, green: 0.76, blue: 0.73).opacity(0.22))
                .frame(width: 420, height: 420)
                .blur(radius: 40)
                .offset(x: -360, y: 240)

            Rectangle()
                .fill(.white.opacity(0.04))
                .mask {
                    Canvas { context, size in
                        let spacing: CGFloat = 32
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            context.fill(
                                Path(CGRect(x: x, y: 0, width: 1, height: size.height)),
                                with: .color(.white.opacity(0.35))
                            )
                        }

                        for y in stride(from: 0, through: size.height, by: spacing) {
                            context.fill(
                                Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                                with: .color(.white.opacity(0.25))
                            )
                        }
                    }
                }
                .blendMode(.softLight)
        }
        .ignoresSafeArea()
    }
}

