import SwiftUI
import SwiftData

struct MeltdownView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    @Query(sort: \DailyContract.date, order: .reverse)
    private var contracts: [DailyContract]

    @Query(sort: \UserProfile.createdAt)
    private var profiles: [UserProfile]

    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var breathingScale: CGFloat = 0.8
    @State private var showGoblinMode = false
    @State private var selectedGoblinTask: GoblinTask?
    @State private var completedGoblinTasks: Set<GoblinTask> = []
    @State private var showBailOut = false

    private var todaysContract: DailyContract? {
        let today = Calendar.current.startOfDay(for: Date())
        return contracts.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var userProfile: UserProfile? {
        profiles.first
    }

    var body: some View {
        ZStack {
            // Dark calming background
            Color.meltdownBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: exitMeltdown) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.meltdownText.opacity(0.5))
                    }
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                if showGoblinMode {
                    goblinModeContent
                } else {
                    breathingContent
                }

                Spacer()

                // Bottom actions
                bottomActions
            }
            .padding(.vertical, Spacing.lg)
        }
        .onAppear {
            startBreathingAnimation()
            activateMeltdownMode()
        }
    }

    // MARK: - Breathing Content
    private var breathingContent: some View {
        VStack(spacing: Spacing.xl) {
            // Calming message
            Text("It's okay.")
                .font(.largeTitle)
                .foregroundColor(.meltdownText)

            Text("Take a moment. Breathe.")
                .font(.bodyMedium)
                .foregroundColor(.meltdownText.opacity(0.7))

            // Breathing circle
            ZStack {
                Circle()
                    .stroke(Color.meltdownAccent, lineWidth: 2)
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(Color.softWave.opacity(0.3))
                    .frame(width: 180, height: 180)
                    .scaleEffect(breathingScale)

                VStack(spacing: Spacing.xs) {
                    Text(breathingPhase.instruction)
                        .font(.title3)
                        .foregroundColor(.meltdownText)

                    Text(breathingPhase.emoji)
                        .font(.system(size: 32))
                }
            }
            .padding(.vertical, Spacing.xl)

            // Encouraging message
            Text("You're doing great. This feeling will pass.")
                .font(.caption)
                .foregroundColor(.meltdownText.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
    }

    // MARK: - Goblin Mode Content
    private var goblinModeContent: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            VStack(spacing: Spacing.sm) {
                Text("Goblin Mode")
                    .font(.title)
                    .foregroundColor(.meltdownText)

                Text("Pick something gentle. No pressure.")
                    .font(.bodyMedium)
                    .foregroundColor(.meltdownText.opacity(0.7))
            }

            // Goblin tasks
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(GoblinTask.allCases, id: \.self) { task in
                        GoblinTaskCard(
                            task: task,
                            isCompleted: completedGoblinTasks.contains(task)
                        ) {
                            completeGoblinTask(task)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }

            // XP earned
            if !completedGoblinTasks.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.warmSand)
                    Text("+\(completedGoblinTasks.count * 5) XP for self-care")
                        .font(.caption)
                        .foregroundColor(.warmSand)
                }
                .padding(.vertical, Spacing.sm)
            }
        }
    }

    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: Spacing.md) {
            if !showGoblinMode {
                HStack(spacing: Spacing.md) {
                    Button(action: { withAnimation { showGoblinMode = true } }) {
                        HStack(spacing: Spacing.sm) {
                            Text("👹")
                            Text("Goblin Mode")
                                .font(.bodyMedium)
                        }
                        .foregroundColor(.meltdownText)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(Color.meltdownAccent)
                        .cornerRadius(CornerRadius.lg)
                    }

                    Button(action: { showBailOut = true }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "envelope")
                            Text("Bail Out")
                                .font(.bodyMedium)
                        }
                        .foregroundColor(.meltdownText)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(Color.meltdownAccent)
                        .cornerRadius(CornerRadius.lg)
                    }
                }
            }

            Button(action: exitMeltdown) {
                Text("I'm feeling better")
                    .font(.bodyMedium)
                    .foregroundColor(.zenGreen)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.zenGreen.opacity(0.1))
                    .cornerRadius(CornerRadius.lg)
            }

            // Stats
            if let contract = todaysContract {
                Text("Meltdowns today: \(contract.meltdownCount)")
                    .font(.caption)
                    .foregroundColor(.meltdownText.opacity(0.3))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .sheet(isPresented: $showBailOut) {
            BailOutView()
        }
    }

    // MARK: - Actions
    private func startBreathingAnimation() {
        animateBreathing()
    }

    private func animateBreathing() {
        withAnimation(.easeInOut(duration: 4)) {
            breathingPhase = .inhale
            breathingScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeInOut(duration: 2)) {
                breathingPhase = .hold
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(.easeInOut(duration: 4)) {
                breathingPhase = .exhale
                breathingScale = 0.8
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            animateBreathing()
        }
    }

    private func activateMeltdownMode() {
        todaysContract?.activateMeltdown()
        userProfile?.recordMeltdown()

        // Soft haptic
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    private func completeGoblinTask(_ task: GoblinTask) {
        guard !completedGoblinTasks.contains(task) else { return }

        _ = withAnimation(.spring(response: 0.3)) {
            completedGoblinTasks.insert(task)
        }

        // Award XP via gamification system
        userProfile?.recordGoblinTaskCompletion()

        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func exitMeltdown() {
        todaysContract?.deactivateMeltdown()

        // Award survival XP if goblin tasks were completed
        if !completedGoblinTasks.isEmpty {
            userProfile?.recordMeltdownSurvival()
        }

        withAnimation {
            isPresented = false
        }
    }
}

// MARK: - Breathing Phase
enum BreathingPhase {
    case inhale
    case hold
    case exhale

    var instruction: String {
        switch self {
        case .inhale: return "Breathe in..."
        case .hold: return "Hold..."
        case .exhale: return "Breathe out..."
        }
    }

    var emoji: String {
        switch self {
        case .inhale: return "🌊"
        case .hold: return "✨"
        case .exhale: return "🍃"
        }
    }
}

// MARK: - Goblin Tasks
enum GoblinTask: String, CaseIterable {
    case drinkWater = "Drink a glass of water"
    case stretch = "Do a quick stretch"
    case snack = "Have a small snack"
    case bathroom = "Take a bathroom break"
    case walkAround = "Walk around for a minute"
    case lookOutside = "Look out a window"
    case breathe = "Take 5 deep breaths"
    case music = "Listen to a favorite song"

    var emoji: String {
        switch self {
        case .drinkWater: return "💧"
        case .stretch: return "🧘"
        case .snack: return "🍎"
        case .bathroom: return "🚽"
        case .walkAround: return "🚶"
        case .lookOutside: return "🪟"
        case .breathe: return "🌬️"
        case .music: return "🎵"
        }
    }

    var xpValue: Int { 5 }
}

// MARK: - Goblin Task Card
struct GoblinTaskCard: View {
    let task: GoblinTask
    let isCompleted: Bool
    let onComplete: () -> Void

    var body: some View {
        Button(action: onComplete) {
            HStack(spacing: Spacing.md) {
                Text(task.emoji)
                    .font(.title2)

                Text(task.rawValue)
                    .font(.bodyMedium)
                    .foregroundColor(isCompleted ? .meltdownText.opacity(0.5) : .meltdownText)
                    .strikethrough(isCompleted)

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.zenGreen)
                } else {
                    Text("+\(task.xpValue) XP")
                        .font(.caption)
                        .foregroundColor(.warmSand)
                }
            }
            .padding(Spacing.md)
            .background(isCompleted ? Color.zenGreen.opacity(0.1) : Color.meltdownAccent)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(isCompleted)
    }
}

// MARK: - Meltdown Button (Reusable)
struct MeltdownTriggerButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "heart.fill")
                Text("Overwhelmed?")
            }
            .font(.caption)
            .foregroundColor(.coralAlert)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.coralAlert.opacity(0.1))
            .cornerRadius(CornerRadius.full)
        }
    }
}

#Preview {
    MeltdownView(isPresented: .constant(true))
        .modelContainer(for: [DailyContract.self, UserProfile.self], inMemory: true)
}
