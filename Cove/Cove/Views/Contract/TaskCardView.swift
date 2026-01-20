import SwiftUI

struct TaskCardView: View {
    let task: CoveTask
    let onComplete: () -> Void
    let onStart: () -> Void
    let onRemove: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isCompleting = false

    private let completeThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            // Complete background (swipe right)
            HStack {
                completeBackground
                Spacer()
            }

            // Card content
            cardContent
                .offset(x: offset)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .opacity(isCompleting ? 0 : 1)
        .scaleEffect(isCompleting ? 0.8 : 1)
    }

    private var completeBackground: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(.white)
                .padding(.leading, Spacing.lg)

            Text("Complete!")
                .font(.bodyLargeBold)
                .foregroundColor(.white)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.zenGreen)
    }

    private var cardContent: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            statusButton

            // Task info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.bodyLarge)
                    .foregroundColor(.deepText)
                    .strikethrough(task.status == .completed)

                HStack(spacing: Spacing.sm) {
                    if let minutes = task.estimatedMinutes {
                        Label("\(minutes)m", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.mutedText)
                    }

                    Text(task.interestLevel.emoji)
                        .font(.caption)

                    Text(task.energyRequired.emoji)
                        .font(.caption)

                    if task.isAnchorTask {
                        Text("ANCHOR")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.deepOcean)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.deepOcean.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Remove button
            if task.status != .completed {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.mistGray)
                }
            }
        }
        .padding(Spacing.md)
        .background(cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var statusButton: some View {
        Button(action: handleStatusTap) {
            ZStack {
                Circle()
                    .stroke(statusColor, lineWidth: 2)
                    .frame(width: 28, height: 28)

                if task.status == .completed {
                    Circle()
                        .fill(Color.zenGreen)
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else if task.status == .inProgress {
                    Circle()
                        .fill(Color.softWave.opacity(0.3))
                        .frame(width: 28, height: 28)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.softWave, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
        .disabled(task.status == .completed)
        .sensoryFeedback(.impact(weight: .light), trigger: task.status)
    }

    private var statusColor: Color {
        switch task.status {
        case .completed: return .zenGreen
        case .inProgress: return .softWave
        default: return .mistGray
        }
    }

    private var cardBackground: Color {
        switch task.status {
        case .completed: return Color.zenGreen.opacity(0.05)
        case .inProgress: return Color.softWave.opacity(0.05)
        default: return .white
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow swipe right for completion
                if value.translation.width > 0 && task.status != .completed {
                    offset = value.translation.width
                }
            }
            .onEnded { value in
                if offset > completeThreshold {
                    completeWithAnimation()
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                }
            }
    }

    private func handleStatusTap() {
        switch task.status {
        case .pending:
            onStart()
        case .inProgress:
            completeWithAnimation()
        default:
            break
        }
    }

    private func completeWithAnimation() {
        withAnimation(.spring(response: 0.3)) {
            offset = UIScreen.main.bounds.width
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3)) {
                isCompleting = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onComplete()
        }
    }
}

// MARK: - Completion Celebration View
struct CompletionCelebrationView: View {
    let task: CoveTask
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Celebration icon
            ZStack {
                Circle()
                    .fill(Color.zenGreen)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)

            // Message
            Text("Nice work!")
                .font(.title2)
                .foregroundColor(.deepText)

            Text(task.title)
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)

            // XP earned
            HStack(spacing: Spacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundColor(.warmSand)
                Text("+\(task.xpValue) XP")
                    .font(.bodyLargeBold)
                    .foregroundColor(.warmSand)
            }
            .padding(.top, Spacing.sm)
        }
        .padding(Spacing.xl)
        .background(Color.white)
        .cornerRadius(CornerRadius.xl)
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1
                opacity = 1
            }

            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
        .sensoryFeedback(.success, trigger: scale)
    }
}

// MARK: - Stability Bar
struct StabilityBarView: View {
    let score: Double
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Stability")
                    .font(.caption)
                    .foregroundColor(.mutedText)

                Spacer()

                Text("\(Int(score * 100))%")
                    .font(.captionBold)
                    .foregroundColor(stabilityColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mistGray)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stabilityColor)
                        .frame(width: geometry.size.width * score)
                        .animation(.spring(response: 0.5), value: score)
                }
            }
            .frame(height: 8)
        }
    }

    private var stabilityColor: Color {
        if score >= 0.7 {
            return .zenGreen
        } else if score >= 0.4 {
            return .warmSand
        } else {
            return .coralAlert
        }
    }
}

// MARK: - Progress Ring
struct ProgressRingView: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.mistGray, lineWidth: 4)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5), value: progress)

            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                .foregroundColor(.deepText)
        }
        .frame(width: size, height: size)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .zenGreen
        } else if progress >= 0.5 {
            return .softWave
        } else {
            return .warmSand
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TaskCardView(
            task: CoveTask(title: "Review pull requests", estimatedMinutes: 30, interestLevel: .medium, energyRequired: .high, isAnchorTask: true),
            onComplete: {},
            onStart: {},
            onRemove: {}
        )

        StabilityBarView(score: 0.65, progress: 0.4)
            .padding(.horizontal)

        ProgressRingView(progress: 0.6, size: 80)
    }
    .padding()
    .background(Color.cloudWhite)
}
