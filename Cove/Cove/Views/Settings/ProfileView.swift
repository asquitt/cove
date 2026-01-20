import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? {
        profiles.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    if let profile = profile {
                        profileContent(profile)
                    } else {
                        createProfilePrompt
                    }
                }
                .padding(.top, Spacing.md)
            }
            .background(Color.cloudWhite)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Profile")
                .font(.largeTitle)
                .foregroundColor(.deepText)

            Text("Settings & Progress")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
    }

    private func profileContent(_ profile: UserProfile) -> some View {
        VStack(spacing: Spacing.lg) {
            // Stats Card
            statsCard(profile)

            // Level Progress
            levelProgressCard(profile)

            // Settings Sections
            settingsSection(profile)

            // API Key Section
            apiKeySection(profile)
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func statsCard(_ profile: UserProfile) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.softWave)
                Text("Stats")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            HStack(spacing: Spacing.lg) {
                statItem(value: "\(profile.totalTasksCompleted)", label: "Tasks Done")
                statItem(value: "\(profile.currentStreak)", label: "Day Streak")
                statItem(value: "\(profile.totalXPEarned)", label: "Total XP")
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.title2)
                .foregroundColor(.deepText)
            Text(label)
                .font(.caption)
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity)
    }

    private func levelProgressCard(_ profile: UserProfile) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Level \(profile.currentLevel)")
                    .font(.title3)
                    .foregroundColor(.deepText)

                Spacer()

                Text("\(profile.xpToNextLevel) XP to next")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.full)
                        .fill(Color.mistGray)

                    RoundedRectangle(cornerRadius: CornerRadius.full)
                        .fill(Color.zenGreen)
                        .frame(width: geometry.size.width * profile.levelProgress)
                }
            }
            .frame(height: 12)
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func settingsSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Settings")
                .font(.title3)
                .foregroundColor(.deepText)

            // Pessimism Multiplier
            settingRow(
                icon: "timer",
                title: "Time Buffer",
                value: "\(Int(profile.pessimismMultiplier * 100 - 100))% extra"
            )

            // Energy Pattern
            settingRow(
                icon: "bolt.fill",
                title: "Energy Pattern",
                value: profile.energyPattern.displayName
            )

            // Work Hours
            settingRow(
                icon: "clock",
                title: "Work Hours",
                value: "\(profile.preferredWorkStartHour):00 - \(profile.preferredWorkEndHour):00"
            )
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func settingRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.softWave)
                .frame(width: 24)

            Text(title)
                .font(.bodyMedium)
                .foregroundColor(.deepText)

            Spacer()

            Text(value)
                .font(.bodyMedium)
                .foregroundColor(.mutedText)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.mistGray)
        }
        .padding(.vertical, Spacing.sm)
    }

    private func apiKeySection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.warmSand)
                Text("Claude API")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            HStack {
                if profile.claudeAPIKey != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.zenGreen)
                    Text("API Key configured")
                        .font(.bodyMedium)
                        .foregroundColor(.deepText)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.warmSand)
                    Text("API Key not set")
                        .font(.bodyMedium)
                        .foregroundColor(.deepText)
                }

                Spacer()

                Button(profile.claudeAPIKey != nil ? "Update" : "Add") {
                    // TODO: Show API key input sheet
                }
                .font(.captionBold)
                .foregroundColor(.deepOcean)
            }

            Text("Required for AI-powered task classification")
                .font(.caption)
                .foregroundColor(.mutedText)
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var createProfilePrompt: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.circle")
                .font(.system(size: 48))
                .foregroundColor(.softWave)

            Text("Welcome to Cove")
                .font(.title2)
                .foregroundColor(.deepText)

            Text("Let's set up your profile")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)

            Button(action: createProfile) {
                Text("Get Started")
                    .font(.bodyLargeBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.deepOcean)
                    .cornerRadius(CornerRadius.lg)
            }
        }
        .padding(Spacing.xl)
    }

    private func createProfile() {
        let profile = UserProfile()
        modelContext.insert(profile)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
