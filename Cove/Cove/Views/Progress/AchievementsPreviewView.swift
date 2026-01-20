import SwiftUI

struct AchievementsPreviewView: View {
    let achievements: [Achievement]

    private var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? Date.distantPast) > ($1.unlockedAt ?? Date.distantPast) }
    }

    private var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked }
            .sorted { $0.progressPercentage > $1.progressPercentage }
    }

    private var displayedAchievements: [Achievement] {
        let recent = Array(unlockedAchievements.prefix(2))
        let upcoming = Array(lockedAchievements.prefix(2 - recent.count))
        return recent + upcoming
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Achievements")
                    .font(.title3)
                    .foregroundColor(.deepText)

                Spacer()

                Text("\(unlockedAchievements.count)/\(achievements.count)")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(displayedAchievements, id: \.id) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.warmSand.opacity(0.2) : Color.mistGray.opacity(0.5))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.achievementType.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .warmSand : .mutedText)
            }

            Text(achievement.achievementType.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(achievement.isUnlocked ? .deepText : .mutedText)
                .lineLimit(1)

            if !achievement.isUnlocked {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.mistGray)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.softWave)
                            .frame(width: geometry.size.width * achievement.progressPercentage)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Color.cloudWhite)
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    AchievementsPreviewView(achievements: AchievementType.allCases.map { Achievement(achievementType: $0) })
        .padding()
        .background(Color.cloudWhite)
}
