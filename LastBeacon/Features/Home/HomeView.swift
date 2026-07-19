import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 76, weight: .thin))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.8), radius: 18)

                Text(AppConfiguration.productName)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Button("Start") { }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(true)
            }
            .padding(32)
        }
    }
}
