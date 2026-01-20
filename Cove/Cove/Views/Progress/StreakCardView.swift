import SwiftUI

struct StreakCardView: View {
    let currentStreak: Int
    let longestStreak: Int

    private var hasStreakBonus: Bool {
        currentStreak >= 2
    }

    var body: some View {
        HStack(spacing: Spacing.xl) {
            // Current streak
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(currentStreak > 0 ? .warmSand : .mistGray)
                    Text("\(currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.deepText)
                }

                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(.mutedText)

                if hasStreakBonus {
                    Text("+\(Constants.streakBonusXP) XP bonus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.zenGreen)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.zenGreen.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }
            }

            Divider()
                .frame(height: 50)

            // Longest streak
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.warmSand)
                    Text("\(longestStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.deepText)
                }

                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    StreakCardView(currentStreak: 5, longestStreak: 12)
        .padding()
        .background(Color.cloudWhite)
}
