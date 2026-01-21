import SwiftUI

/// View showing health-based energy insights
/// PRD 6.7.1 - Apple Health integration
struct EnergyInsightsView: View {
    @State private var healthService = HealthService()
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if !HealthService.isHealthDataAvailable {
                unavailableView
            } else if healthService.needsPermission {
                permissionView
            } else if isLoading {
                loadingView
            } else if let estimate = healthService.energyEstimate {
                energyContent(estimate)
            } else {
                emptyView
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.coralAlert)
            Text("Energy Insights")
                .font(.headline)
                .foregroundColor(.deepText)
            Spacer()
            if healthService.energyEstimate != nil {
                Button {
                    Task { await refreshData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.calmSea)
                }
            }
        }
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.slash")
                .font(.title)
                .foregroundColor(.mutedText)
            Text("Apple Health is not available on this device")
                .font(.caption)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Permission View

    private var permissionView: some View {
        VStack(spacing: 12) {
            Text("Connect Apple Health to get personalized energy insights based on your sleep and activity.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await requestAccess() }
            } label: {
                Label("Connect Health", systemImage: "heart.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.coralAlert)
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
            Text("Analyzing health data...")
                .font(.caption)
                .foregroundColor(.mutedText)
            Spacer()
        }
        .padding()
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 8) {
            Button {
                Task { await refreshData() }
            } label: {
                Label("Check Energy", systemImage: "bolt.heart")
                    .font(.subheadline)
                    .foregroundColor(.calmSea)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Energy Content

    private func energyContent(_ estimate: EnergyEstimate) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Energy score
            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(Color.mistGray, lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: CGFloat(estimate.score) / 100)
                        .stroke(energyColor(estimate.level), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(estimate.score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.deepText)
                        Text(estimate.level.emoji)
                            .font(.caption)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Energy Level: \(estimate.level.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.deepText)

                    Text(estimate.recommendation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Factors
            if !estimate.factors.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Factors")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.mutedText)

                    ForEach(estimate.factors, id: \.description) { factor in
                        HStack(spacing: 8) {
                            Image(systemName: factorIcon(factor))
                                .foregroundColor(factorColor(factor))
                                .frame(width: 20)

                            Text(factor.description)
                                .font(.caption)
                                .foregroundColor(.deepText)
                        }
                    }
                }
            }

            // Sleep summary if available
            if let sleep = healthService.lastNightSleep {
                Divider()

                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundColor(.softWave)
                    Text("Last night: \(String(format: "%.1f", sleep.totalHours))h sleep")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(sleep.quality.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(sleepQualityColor(sleep.quality))
                }
            }
        }
    }

    // MARK: - Helpers

    private func energyColor(_ level: EnergyLevel) -> Color {
        switch level {
        case .high: return .zenGreen
        case .medium: return .warmSand
        case .low: return .coralAlert
        }
    }

    private func factorIcon(_ factor: EnergyFactor) -> String {
        switch factor.impact {
        case .positive: return "arrow.up.circle.fill"
        case .neutral: return "minus.circle.fill"
        case .negative: return "arrow.down.circle.fill"
        }
    }

    private func factorColor(_ factor: EnergyFactor) -> Color {
        switch factor.impact {
        case .positive: return .zenGreen
        case .neutral: return .mistGray
        case .negative: return .warmSand
        }
    }

    private func sleepQualityColor(_ quality: SleepQuality) -> Color {
        switch quality {
        case .good: return .zenGreen
        case .fair: return .warmSand
        case .poor: return .coralAlert
        }
    }

    // MARK: - Actions

    private func requestAccess() async {
        isLoading = true
        let granted = await healthService.requestAccess()
        if granted {
            await refreshData()
        }
        isLoading = false
    }

    private func refreshData() async {
        isLoading = true
        _ = await healthService.calculateEnergyEstimate()
        isLoading = false
    }
}

// MARK: - Compact Energy Badge

struct EnergyBadge: View {
    let estimate: EnergyEstimate?

    var body: some View {
        if let estimate = estimate {
            HStack(spacing: 4) {
                Text(estimate.level.emoji)
                Text("\(estimate.score)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.1))
            .foregroundColor(badgeColor)
            .cornerRadius(12)
        }
    }

    private var badgeColor: Color {
        guard let estimate = estimate else { return .mistGray }
        switch estimate.level {
        case .high: return .zenGreen
        case .medium: return .warmSand
        case .low: return .coralAlert
        }
    }
}

#Preview {
    EnergyInsightsView()
        .padding()
}
