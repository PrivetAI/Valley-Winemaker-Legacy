import SwiftUI

struct ValleyWinemakerLoadingScreen: View {
    @State private var pour: CGFloat = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ValleyPalette.cream, ValleyPalette.ivory, ValleyPalette.creamWarm],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                ValleyEstateMonogram()
                    .stroke(ValleyPalette.burgundy, lineWidth: 2.4)
                    .frame(width: 132, height: 132)
                    .opacity(pulse ? 1.0 : 0.55)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                Text("Valley Winemaker Legacy")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)
                Text("Preparing the cellar, dusting the ledgers,\nand uncorking the season.")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ValleyPalette.creamWarm)
                        .frame(width: 220, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ValleyPalette.burgundy.opacity(0.5), lineWidth: 1)
                        )
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [ValleyPalette.terracotta, ValleyPalette.burgundy],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: 220 * pour, height: 12)
                }
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pour)
            }
            .padding(40)
        }
        .onAppear {
            pulse = true
            pour = 1.0
        }
    }
}
