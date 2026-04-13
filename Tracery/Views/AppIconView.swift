import SwiftUI

/// The icon design: four game tiles spelling T-R-A-C in a 2×2 grid.
/// Used both for preview and for PNG export via ImageRenderer in tests.
struct AppIconView: View {
    private let letters = [["T", "R"], ["A", "C"]]
    private let tileColor = Color.blue
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.06, green: 0.09, blue: 0.20),
                 Color(red: 0.10, green: 0.15, blue: 0.32)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let spacing = size * 0.04
            let tileSize = (size * 0.72 - spacing) / 2

            ZStack {
                bgGradient
                    .ignoresSafeArea()

                VStack(spacing: spacing) {
                    ForEach(letters, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(row, id: \.self) { letter in
                                tile(letter: letter, size: tileSize)
                            }
                        }
                    }
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func tile(letter: String, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(tileColor.gradient)
                .shadow(color: .blue.opacity(0.5), radius: size * 0.06)

            Text(letter)
                .font(.system(size: size * 0.52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    AppIconView()
        .frame(width: 400, height: 400)
}
