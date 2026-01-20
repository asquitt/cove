import SwiftUI
import SwiftData

struct ProgressView: View {
    @Query(sort: \UserProfile.createdAt)
    private var profiles: [UserProfile]

    private var userProfile: UserProfile? {
        profiles.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if let profile = userProfile {
                        // Level Card
                        LevelCardView(
                            level: profile.currentLevel,
                            totalXP: profile.totalXPEarned,
                            xpToNextLevel: profile.xpToNextLevel,
                            levelProgress: profile.levelProgress
                        )

                        // Streak Card
                        StreakCardView(
                            currentStreak: profile.currentStreak,
                            longestStreak: profile.longestStreak
                        )

                        // Skills
                        if let skills = profile.skillCategories, !skills.isEmpty {
                            SkillBarsView(skills: skills)
                        }

                        // Activity Heatmap
                        ActivityHeatmapView(activities: profile.dailyActivities ?? [])

                        // Achievements Preview
                        if let achievements = profile.achievements, !achievements.isEmpty {
                            AchievementsPreviewView(achievements: achievements)
                        }

                        // Stats Summary
                        statsSummary(profile)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.cloudWhite)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func statsSummary(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Stats")
                .font(.title3)
                .foregroundColor(.deepText)

            HStack(spacing: Spacing.lg) {
                statItem(value: "\(profile.totalTasksCompleted)", label: "Tasks", icon: "checkmark.circle.fill")
                statItem(value: "\(profile.totalContractsCompleted)", label: "Contracts", icon: "doc.text.fill")
                statItem(value: "\(profile.totalMeltdownsSurvived)", label: "Survived", icon: "heart.fill")
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.softWave)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.deepText)

            Text(label)
                .font(.caption)
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 56))
                .foregroundColor(.softWave.opacity(0.5))

            Text("No progress yet")
                .font(.title2)
                .foregroundColor(.deepText)

            Text("Complete tasks to see your progress and earn XP!")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
    }
}

#Preview {
    ProgressView()
        .modelContainer(for: [UserProfile.self, SkillCategory.self, DailyActivity.self, Achievement.self], inMemory: true)
}
