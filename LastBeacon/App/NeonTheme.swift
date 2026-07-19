import SwiftUI

enum NeonTheme {
    static let background = Color(red: 0.015, green: 0.025, blue: 0.075)
    static let panel = Color(red: 0.055, green: 0.075, blue: 0.15)
    static let cyan = Color(red: 0.15, green: 0.9, blue: 1)
    static let magenta = Color(red: 1, green: 0.22, blue: 0.62)
    static let amber = Color(red: 1, green: 0.72, blue: 0.2)
}

struct NeonBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                colors: [NeonTheme.background, Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            content
        }
        .foregroundStyle(.white)
    }
}

extension View {
    func neonBackground() -> some View { modifier(NeonBackground()) }
}

