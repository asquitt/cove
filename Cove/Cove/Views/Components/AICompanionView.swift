import SwiftUI

/// AI Companion presence layer for body doubling support
/// PRD 6.6.1 - Subtle animated presence indicator
struct AICompanionView: View {
    @State private var isAnimating = false
    @State private var breathPhase: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            // Ambient presence indicator
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.softWave.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .scaleEffect(1.0 + breathPhase * 0.15)

                // Inner core
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.calmSea, Color.softWave],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)

                // Pulse dot
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(x: -4, y: -4)
            }

            // Ambient text
            Text("I'm here with you")
                .font(.caption)
                .foregroundColor(.mutedText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathPhase = 1.0
            }
        }
    }
}

/// Compact version for toolbar/corner placement
struct AICompanionIndicator: View {
    @State private var isGlowing = false

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(Color.softWave.opacity(isGlowing ? 0.3 : 0.1))
                .frame(width: 20, height: 20)

            // Core
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.calmSea, Color.softWave],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

/// Full companion overlay for focus mode
struct AICompanionOverlay: View {
    let message: String
    let isVisible: Bool
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        if isVisible {
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    AICompanionIndicator()

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.deepText)

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.mutedText)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .padding(.horizontal)
                .padding(.bottom, 100) // Above tab bar
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

/// Companion state manager
@Observable
final class AICompanionService {
    var isPresent: Bool = false
    var currentMessage: String = "I'm here while you work"
    var showMicroCoaching: Bool = false
    var microCoachingMessage: String = ""

    private var inactivityTimer: Timer?
    private var focusStartTime: Date?

    // MARK: - Presence Messages

    private let ambientMessages = [
        "I'm here while you work",
        "Working alongside you",
        "Right here if you need me",
        "You're not alone in this",
        "Taking it one step at a time"
    ]

    private let encouragementMessages = [
        "You've got this",
        "One small step is still progress",
        "Starting is the hardest part",
        "You're doing better than you think"
    ]

    // MARK: - State Management

    func activate() {
        isPresent = true
        currentMessage = ambientMessages.randomElement() ?? ambientMessages[0]
        focusStartTime = Date()
    }

    func deactivate() {
        isPresent = false
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        focusStartTime = nil
    }

    func updatePresence() {
        currentMessage = ambientMessages.randomElement() ?? ambientMessages[0]
    }

    // MARK: - Micro-Coaching Triggers

    func onTaskViewed(taskTitle: String) {
        // Called when user looks at a task but doesn't start it
        // Could trigger gentle coaching after a delay
    }

    func onInactivityDetected(seconds: TimeInterval) {
        // Called when user hasn't taken action for a while
        if seconds > 30 && !showMicroCoaching {
            triggerMicroCoaching(MicroCoachingMessage.stuckOnTask.randomMessage)
        }
    }

    func triggerMicroCoaching(_ message: String) {
        microCoachingMessage = message
        showMicroCoaching = true
    }

    func dismissMicroCoaching() {
        showMicroCoaching = false
        microCoachingMessage = ""
    }

    // MARK: - Focus Session

    var focusDuration: TimeInterval {
        guard let start = focusStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    func celebrateFocusTime() {
        if focusDuration > 1800 { // 30 minutes
            currentMessage = "Amazing focus! 30+ minutes of deep work"
        } else if focusDuration > 900 { // 15 minutes
            currentMessage = "Great flow! 15 minutes of focused work"
        }
    }
}

/// Types of micro-coaching messages
enum MicroCoachingMessage {
    case stuckOnTask
    case beforeStarting
    case encouragement
    case celebration

    var randomMessage: String {
        switch self {
        case .stuckOnTask:
            return [
                "What's the tiniest first step you could take?",
                "Sometimes opening the thing is enough to start",
                "Break it down: what's the very first action?",
                "You don't have to finish, just start"
            ].randomElement()!

        case .beforeStarting:
            return [
                "Ready when you are",
                "Just the first step, that's all",
                "You've done this type of task before"
            ].randomElement()!

        case .encouragement:
            return [
                "You're making progress",
                "Keep going, you've got this",
                "One task at a time"
            ].randomElement()!

        case .celebration:
            return [
                "Nice work!",
                "Task complete! Well done",
                "Another one down"
            ].randomElement()!
        }
    }
}

// MARK: - Previews

#Preview("Companion View") {
    VStack(spacing: 32) {
        AICompanionView()

        AICompanionIndicator()

        AICompanionOverlay(
            message: "What's the tiniest first step?",
            isVisible: true,
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.cloudWhite)
}
