import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var profiles: [UserProfile]
    @AppStorage("notificationSettings") private var notificationSettingsData: Data = Data()
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @State private var showAPIKeySheet = false
    @State private var apiKeyInput = ""
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private var profile: UserProfile? {
        profiles.first
    }

    private var notificationSettings: NotificationSettings {
        get {
            (try? JSONDecoder().decode(NotificationSettings.self, from: notificationSettingsData))
                ?? NotificationSettings.default
        }
        set {
            notificationSettingsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
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
            .sheet(isPresented: $showAPIKeySheet) {
                apiKeyInputSheet
            }
            .task {
                notificationStatus = await NotificationService.shared.checkPermissionStatus()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Settings")
                .font(.largeTitle)
                .foregroundColor(.deepText)

            Text("Customize your Cove experience")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
    }

    private func profileContent(_ profile: UserProfile) -> some View {
        VStack(spacing: Spacing.lg) {
            statsCard(profile)
            levelProgressCard(profile)
            appearanceSection
            notificationSection
            timeSettingsSection(profile)
            apiKeySection(profile)
            dangerZoneSection
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Stats Card

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
        .background(Color.cardBackground)
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

    // MARK: - Level Progress

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
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.softWave)
                Text("Appearance")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            Picker("Color Scheme", selection: $preferredColorScheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.warmSand)
                Text("Notifications")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()

                if notificationStatus == .authorized {
                    Text("Enabled")
                        .font(.caption)
                        .foregroundColor(.zenGreen)
                } else if notificationStatus == .denied {
                    Text("Disabled")
                        .font(.caption)
                        .foregroundColor(.coralAlert)
                }
            }

            if notificationStatus == .notDetermined {
                Button(action: requestNotificationPermission) {
                    HStack {
                        Text("Enable Notifications")
                            .font(.bodyMedium)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.deepOcean)
                }
            } else if notificationStatus == .denied {
                Text("Open Settings to enable notifications")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            } else {
                notificationToggles
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var notificationToggles: some View {
        VStack(spacing: Spacing.sm) {
            notificationToggle(
                title: "Daily Reminder",
                subtitle: "Remind me to plan my day",
                isOn: Binding(
                    get: { notificationSettings.dailyReminderEnabled },
                    set: { newValue in
                        var settings = notificationSettings
                        settings.dailyReminderEnabled = newValue
                        self.notificationSettingsData = (try? JSONEncoder().encode(settings)) ?? Data()
                        Task { await updateNotifications() }
                    }
                )
            )

            notificationToggle(
                title: "Streak Reminder",
                subtitle: "Keep my streak alive",
                isOn: Binding(
                    get: { notificationSettings.streakReminderEnabled },
                    set: { newValue in
                        var settings = notificationSettings
                        settings.streakReminderEnabled = newValue
                        self.notificationSettingsData = (try? JSONEncoder().encode(settings)) ?? Data()
                        Task { await updateNotifications() }
                    }
                )
            )

            notificationToggle(
                title: "Task Reminders",
                subtitle: "Scheduled task alerts",
                isOn: Binding(
                    get: { notificationSettings.taskRemindersEnabled },
                    set: { newValue in
                        var settings = notificationSettings
                        settings.taskRemindersEnabled = newValue
                        self.notificationSettingsData = (try? JSONEncoder().encode(settings)) ?? Data()
                    }
                )
            )

            notificationToggle(
                title: "Gentle Nudges",
                subtitle: "Soft reminders to stay on track",
                isOn: Binding(
                    get: { notificationSettings.gentleNudgesEnabled },
                    set: { newValue in
                        var settings = notificationSettings
                        settings.gentleNudgesEnabled = newValue
                        self.notificationSettingsData = (try? JSONEncoder().encode(settings)) ?? Data()
                    }
                )
            )
        }
    }

    private func notificationToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyMedium)
                    .foregroundColor(.deepText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }
        }
        .tint(.deepOcean)
    }

    // MARK: - Time Settings

    private func timeSettingsSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.softWave)
                Text("Time & Energy")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            settingRow(
                icon: "timer",
                title: "Time Buffer",
                value: "\(Int(profile.pessimismMultiplier * 100 - 100))% extra"
            )

            settingRow(
                icon: "bolt.fill",
                title: "Energy Pattern",
                value: profile.energyPattern.displayName
            )

            settingRow(
                icon: "calendar",
                title: "Work Hours",
                value: "\(profile.preferredWorkStartHour):00 - \(profile.preferredWorkEndHour):00"
            )
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
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

    // MARK: - API Key Section

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
                    showAPIKeySheet = true
                }
                .font(.captionBold)
                .foregroundColor(.deepOcean)
            }

            Text("Required for AI-powered task classification")
                .font(.caption)
                .foregroundColor(.mutedText)
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.coralAlert)
                Text("Data")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            Button(action: {}) {
                HStack {
                    Text("Export Data")
                        .font(.bodyMedium)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundColor(.deepOcean)
            }
            .padding(.vertical, Spacing.sm)

            Button(action: {}) {
                HStack {
                    Text("Clear All Data")
                        .font(.bodyMedium)
                    Spacer()
                    Image(systemName: "trash")
                }
                .foregroundColor(.coralAlert)
            }
            .padding(.vertical, Spacing.sm)
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - API Key Sheet

    private var apiKeyInputSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text("Enter your Claude API key from Anthropic Console")
                    .font(.bodyMedium)
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)

                SecureField("sk-ant-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                Button(action: saveAPIKey) {
                    Text("Save")
                        .font(.bodyLargeBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(apiKeyInput.isEmpty ? Color.mistGray : Color.deepOcean)
                        .cornerRadius(CornerRadius.lg)
                }
                .disabled(apiKeyInput.isEmpty)

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAPIKeySheet = false
                        apiKeyInput = ""
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Create Profile

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

    // MARK: - Actions

    private func createProfile() {
        let profile = UserProfile()
        profile.initializeGamification()
        modelContext.insert(profile)
    }

    private func saveAPIKey() {
        guard let profile = profile else { return }
        do {
            try KeychainHelper.save(key: "claude_api_key", value: apiKeyInput)
            profile.claudeAPIKey = "configured"
            showAPIKeySheet = false
            apiKeyInput = ""
        } catch {
            // Handle keychain error - could show alert
            print("Failed to save API key: \(error)")
        }
    }

    private func requestNotificationPermission() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                await NotificationService.shared.registerNotificationCategories()
                notificationStatus = .authorized
            } else {
                notificationStatus = .denied
            }
        }
    }

    private func updateNotifications() async {
        let settings = notificationSettings

        if settings.dailyReminderEnabled {
            try? await NotificationService.shared.scheduleDailyContractReminder(
                at: settings.dailyReminderHour,
                minute: settings.dailyReminderMinute
            )
        } else {
            await NotificationService.shared.cancelDailyContractReminder()
        }

        if settings.streakReminderEnabled, let profile = profile, profile.currentStreak > 0 {
            try? await NotificationService.shared.scheduleStreakReminder(
                currentStreak: profile.currentStreak,
                at: settings.streakReminderHour
            )
        } else {
            await NotificationService.shared.cancelStreakReminder()
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
