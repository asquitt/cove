import SwiftUI

struct ActivityHeatmapView: View {
    let activities: [DailyActivity]

    private let weeksToShow = 12
    private let daysPerWeek = 7

    private var activityMap: [Date: DailyActivity] {
        Dictionary(uniqueKeysWithValues: activities.map { ($0.date, $0) })
    }

    private var dateGrid: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var grid: [[Date]] = []
        var currentDate = today

        // Go back to find the start (12 weeks ago, start of that week)
        let startDate = calendar.date(byAdding: .weekOfYear, value: -weeksToShow + 1, to: today) ?? today
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)) ?? startDate

        currentDate = startOfWeek

        for _ in 0..<weeksToShow {
            var week: [Date] = []
            for _ in 0..<daysPerWeek {
                week.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            grid.append(week)
        }

        return grid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Activity")
                .font(.title3)
                .foregroundColor(.deepText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 3) {
                    ForEach(dateGrid, id: \.first) { week in
                        VStack(spacing: 3) {
                            ForEach(week, id: \.self) { date in
                                ActivityCell(
                                    date: date,
                                    activity: activityMap[date]
                                )
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: Spacing.md) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.mutedText)

                ForEach([ActivityLevel.none, .low, .medium, .high, .max], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.zenGreen.opacity(level.opacity))
                        .frame(width: 12, height: 12)
                }

                Text("More")
                    .font(.caption2)
                    .foregroundColor(.mutedText)
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct ActivityCell: View {
    let date: Date
    let activity: DailyActivity?

    @State private var showTooltip = false

    private var activityLevel: ActivityLevel {
        activity?.activityLevel ?? .none
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isFuture: Bool {
        date > Date()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor)
            .frame(width: 14, height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isToday ? Color.deepOcean : Color.clear, lineWidth: 1)
            )
            .onTapGesture {
                if !isFuture {
                    showTooltip.toggle()
                }
            }
            .popover(isPresented: $showTooltip) {
                ActivityTooltip(date: date, activity: activity)
                    .presentationCompactAdaptation(.popover)
            }
    }

    private var cellColor: Color {
        if isFuture {
            return Color.mistGray.opacity(0.3)
        }
        return Color.zenGreen.opacity(activityLevel.opacity)
    }
}

struct ActivityTooltip: View {
    let date: Date
    let activity: DailyActivity?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(dateString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.deepText)

            if let activity = activity {
                Text("\(activity.tasksCompleted) tasks completed")
                    .font(.caption2)
                    .foregroundColor(.mutedText)
                Text("\(activity.xpEarned) XP earned")
                    .font(.caption2)
                    .foregroundColor(.mutedText)
            } else {
                Text("No activity")
                    .font(.caption2)
                    .foregroundColor(.mutedText)
            }
        }
        .padding(Spacing.sm)
    }
}

#Preview {
    ActivityHeatmapView(activities: [])
        .padding()
        .background(Color.cloudWhite)
}
