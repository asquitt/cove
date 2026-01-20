import SwiftUI

struct LevelCardView: View {
    let level: Int
    let totalXP: Int
    let xpToNextLevel: Int
    let levelProgress: Double

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.lg) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.deepOcean, .softWave],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    VStack(spacing: 0) {
                        Text("LV")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))

                        Text("\(level)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("\(totalXP) XP Total")
                        .font(.title3)
                        .foregroundColor(.deepText)

                    Text("\(xpToNextLevel) XP to next level")
                        .font(.caption)
                        .foregroundColor(.mutedText)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.mistGray)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.softWave, .zenGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * levelProgress)
                                .animation(.spring(response: 0.5), value: levelProgress)
                        }
                    }
                    .frame(height: 12)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    LevelCardView(
        level: 7,
        totalXP: 650,
        xpToNextLevel: 50,
        levelProgress: 0.5
    )
    .padding()
    .background(Color.cloudWhite)
}
