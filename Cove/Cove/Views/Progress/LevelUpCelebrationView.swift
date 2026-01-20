import SwiftUI

struct LevelUpCelebrationView: View {
    let oldLevel: Int
    let newLevel: Int
    let onDismiss: () -> Void

    @State private var showOldLevel = true
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            VStack(spacing: Spacing.xl) {
                Text("LEVEL UP!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.warmSand)
                    .opacity(contentOpacity)

                // Level ring
                ZStack {
                    // Animated ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.warmSand, .zenGreen, .softWave],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 6
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Level number
                    VStack(spacing: 0) {
                        Text("LV")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))

                        Text(showOldLevel ? "\(oldLevel)" : "\(newLevel)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                    }
                }

                Text("Keep up the great work!")
                    .font(.bodyMedium)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(contentOpacity)

                Button(action: dismissWithAnimation) {
                    Text("Continue")
                        .font(.bodyLargeBold)
                        .foregroundColor(.deepOcean)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(Color.white)
                        .cornerRadius(CornerRadius.lg)
                }
                .opacity(contentOpacity)
                .padding(.top, Spacing.lg)
            }
        }
        .onAppear {
            animateIn()
        }
        .sensoryFeedback(.success, trigger: showOldLevel)
    }

    private func animateIn() {
        // Ring animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            ringScale = 1.0
            ringOpacity = 1.0
        }

        // Content fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            contentOpacity = 1.0
        }

        // Level flip
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showOldLevel = false
            }
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            contentOpacity = 0
            ringOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    LevelUpCelebrationView(oldLevel: 4, newLevel: 5, onDismiss: {})
}
