import SwiftUI

struct EnergyRhythmView: View {
    let rhythm: EnergyRhythm
    let hourlyProductivity: [HourlyProductivity]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.warmSand)
                Text("Your Energy Rhythm")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            // Peak hours card
            peakHoursCard

            // Hourly chart
            if !hourlyProductivity.isEmpty {
                hourlyChart
            }

            // Pattern recommendation
            patternRecommendation
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var peakHoursCard: some View {
        HStack(spacing: Spacing.lg) {
            // Peak hours
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Peak Hours", systemImage: "sun.max.fill")
                    .font(.caption)
                    .foregroundColor(.zenGreen)

                Text(rhythm.peakHoursDescription)
                    .font(.bodyMedium)
                    .foregroundColor(.deepText)
            }

            Divider()
                .frame(height: 40)

            // Low hours
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Low Energy", systemImage: "moon.fill")
                    .font(.caption)
                    .foregroundColor(.mutedText)

                Text(lowHoursDescription)
                    .font(.bodyMedium)
                    .foregroundColor(.deepText)
            }
        }
        .padding(Spacing.md)
        .background(Color.cloudWhite)
        .cornerRadius(CornerRadius.md)
    }

    private var lowHoursDescription: String {
        guard !rhythm.lowHours.isEmpty else { return "Not enough data" }
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let labels = rhythm.lowHours.prefix(3).map { hour -> String in
            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            return formatter.string(from: date).lowercased()
        }
        return labels.joined(separator: ", ")
    }

    private var hourlyChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Productivity by Hour")
                .font(.caption)
                .foregroundColor(.mutedText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(hourlyProductivity) { hour in
                        VStack(spacing: 2) {
                            // Bar
                            RoundedRectangle(cornerRadius: 2)
                                .fill(barColor(for: hour.productivityLevel))
                                .frame(width: 20, height: CGFloat(hour.completionRate) * 60)

                            // Label
                            Text(hour.hourLabel)
                                .font(.system(size: 8))
                                .foregroundColor(.mutedText)
                        }
                    }
                }
            }
            .frame(height: 80)
        }
    }

    private func barColor(for level: ProductivityLevel) -> Color {
        switch level {
        case .peak: return .zenGreen
        case .good: return .softWave
        case .moderate: return .warmSand
        case .low: return .coralAlert.opacity(0.5)
        }
    }

    private var patternRecommendation: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: patternIcon)
                .font(.title2)
                .foregroundColor(.softWave)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your Pattern: \(rhythm.recommendedEnergyPattern.displayName)")
                    .font(.captionBold)
                    .foregroundColor(.deepText)

                Text(rhythm.recommendedEnergyPattern.description)
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.softWave.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    private var patternIcon: String {
        switch rhythm.recommendedEnergyPattern {
        case .morningPerson: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .afternoonPeak: return "sun.max.fill"
        case .consistent: return "equal.circle.fill"
        }
    }
}

struct SuggestionsCardView: View {
    let suggestions: [AdaptiveSuggestion]
    var onAction: ((AdaptiveSuggestion) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.warmSand)
                Text("Suggestions")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            if suggestions.isEmpty {
                emptyState
            } else {
                ForEach(suggestions) { suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        onAction?(suggestion)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var emptyState: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.zenGreen)
            Text("No suggestions right now. You're on track!")
                .font(.caption)
                .foregroundColor(.mutedText)
        }
        .padding(Spacing.md)
        .background(Color.zenGreen.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }
}

struct SuggestionRow: View {
    let suggestion: AdaptiveSuggestion
    var onAction: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: suggestionIcon)
                .foregroundColor(suggestionColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.message)
                    .font(.caption)
                    .foregroundColor(.deepText)
            }

            Spacer()

            if let actionLabel = suggestion.actionLabel {
                Button(action: { onAction?() }) {
                    Text(actionLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.softWave)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.cloudWhite)
        .cornerRadius(CornerRadius.sm)
    }

    private var suggestionIcon: String {
        switch suggestion.type {
        case .scheduleTask: return "calendar.badge.clock"
        case .avoidSnooze: return "alarm"
        case .energyMatch: return "bolt.fill"
        case .adjustEstimate: return "clock.badge.exclamationmark"
        case .takeBreak: return "cup.and.saucer.fill"
        }
    }

    private var suggestionColor: Color {
        switch suggestion.type {
        case .scheduleTask: return .softWave
        case .avoidSnooze: return .warmSand
        case .energyMatch: return .zenGreen
        case .adjustEstimate: return .coralAlert
        case .takeBreak: return .softWave
        }
    }
}

struct SnoozeInsightsView: View {
    let snoozePatterns: [SnoozePattern]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "alarm.waves.left.and.right")
                    .foregroundColor(.warmSand)
                Text("Snooze Insights")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            if snoozePatterns.isEmpty {
                Text("Not enough data yet")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            } else {
                ForEach(snoozePatterns) { pattern in
                    SnoozePatternRow(pattern: pattern)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct SnoozePatternRow: View {
    let pattern: SnoozePattern

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Type indicator
            Circle()
                .fill(pattern.isProblematic ? Color.warmSand : Color.zenGreen)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(pattern.taskType.capitalized) interest tasks")
                    .font(.captionBold)
                    .foregroundColor(.deepText)

                Text("Snoozed \(Int(pattern.snoozeRate * 100))% of the time")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            Spacer()

            if pattern.isProblematic {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.warmSand)
                    .font(.caption)
            }
        }
        .padding(Spacing.sm)
        .background(pattern.isProblematic ? Color.warmSand.opacity(0.1) : Color.cloudWhite)
        .cornerRadius(CornerRadius.sm)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            EnergyRhythmView(
                rhythm: EnergyRhythm(
                    peakHours: [9, 10, 11],
                    lowHours: [14, 15],
                    recommendedEnergyPattern: .morningPerson
                ),
                hourlyProductivity: []
            )

            SuggestionsCardView(
                suggestions: [
                    AdaptiveSuggestion(
                        type: .scheduleTask,
                        message: "You're in your peak hours! Great time for high-focus tasks.",
                        actionLabel: "View Tasks",
                        priority: 1
                    )
                ]
            )
        }
        .padding()
    }
    .background(Color.cloudWhite)
}
