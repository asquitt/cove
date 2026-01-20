import SwiftUI

struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Semi-dark background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            VStack(spacing: Spacing.lg) {
                // Achievement badge with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.warmSand.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .opacity(glowOpacity)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.warmSand, .warmSand.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: achievement.achievementType.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)

                Text("Achievement Unlocked!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.warmSand)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(achievement.achievementType.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(achievement.achievementType.description)
                    .font(.bodyMedium)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                // XP reward
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.warmSand)
                    Text("+\(achievement.achievementType.xpReward) XP")
                        .font(.bodyLargeBold)
                        .foregroundColor(.warmSand)
                }
                .padding(.top, Spacing.sm)
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.deepOcean.opacity(0.95))
            )
            .padding(.horizontal, Spacing.xl)
            .opacity(opacity)
        }
        .onAppear {
            animateIn()

            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismissWithAnimation()
            }
        }
        .sensoryFeedback(.success, trigger: opacity)
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            scale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    AchievementUnlockView(
        achievement: Achievement(achievementType: .firstTask),
        onDismiss: {}
    )
}
