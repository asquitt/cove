# iOS/SwiftUI Design Skill for Cove

## Skill: `/design`

When invoked, this skill helps design and implement SwiftUI views for the Cove app following the established design system.

---

## Design System Reference

### Color Palette
```swift
extension Color {
    // Primary
    static let deepOcean = Color(hex: "1a365d")    // Primary actions, headers
    static let calmSea = Color(hex: "2c5282")      // Secondary elements
    static let softWave = Color(hex: "4a90a4")     // Accents, highlights

    // States
    static let zenGreen = Color(hex: "48bb78")     // Success, completion
    static let warmSand = Color(hex: "ed8936")     // Warning, caution
    static let coralAlert = Color(hex: "fc8181")   // Danger, reset/meltdown

    // Neutrals
    static let cloudWhite = Color(hex: "f7fafc")   // Backgrounds
    static let mistGray = Color(hex: "e2e8f0")     // Borders, dividers
    static let deepText = Color(hex: "2d3748")     // Primary text
    static let mutedText = Color(hex: "718096")    // Secondary text
}
```

### Typography Scale
```swift
extension Font {
    // Headings
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title = Font.system(size: 24, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 18, weight: .semibold, design: .rounded)

    // Body
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
    static let small = Font.system(size: 11, weight: .regular, design: .rounded)
}
```

### Spacing System
```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

### Corner Radii
```swift
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999  // Pill shape
}
```

---

## Component Patterns

### Task Card
```swift
struct TaskCard: View {
    let task: Task
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Completion button
            Button(action: onComplete) {
                Circle()
                    .strokeBorder(task.isCompleted ? Color.zenGreen : Color.mistGray, lineWidth: 2)
                    .background(
                        Circle().fill(task.isCompleted ? Color.zenGreen : Color.clear)
                    )
                    .frame(width: 24, height: 24)
                    .overlay {
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
            }

            // Task content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.bodyLarge)
                    .foregroundColor(.deepText)
                    .strikethrough(task.isCompleted)

                if let estimate = task.estimatedMinutes {
                    Text("\(estimate) min")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }
            }

            Spacer()

            // Interest indicator
            InterestBadge(level: task.interestLevel)
        }
        .padding(Spacing.md)
        .background(Color.cloudWhite)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
```

### Interest Badge
```swift
struct InterestBadge: View {
    let level: InterestLevel

    var body: some View {
        Text(level.emoji)
            .font(.system(size: 16))
            .padding(Spacing.xs)
            .background(level.color.opacity(0.2))
            .cornerRadius(CornerRadius.sm)
    }
}

enum InterestLevel: String, Codable {
    case high, medium, low

    var emoji: String {
        switch self {
        case .high: return "🔥"
        case .medium: return "👍"
        case .low: return "😴"
        }
    }

    var color: Color {
        switch self {
        case .high: return .zenGreen
        case .medium: return .warmSand
        case .low: return .mistGray
        }
    }
}
```

### Stability Bar
```swift
struct StabilityBar: View {
    let progress: Double  // 0.0 to 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Stability")
                    .font(.caption)
                    .foregroundColor(.mutedText)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.deepText)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: CornerRadius.full)
                        .fill(Color.mistGray)

                    // Progress
                    RoundedRectangle(cornerRadius: CornerRadius.full)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 8)
        }
    }

    var progressColor: Color {
        switch progress {
        case 0..<0.3: return .coralAlert
        case 0.3..<0.7: return .warmSand
        default: return .zenGreen
        }
    }
}
```

### Meltdown Button
```swift
struct MeltdownButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
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
```

### Voice Capture Button
```swift
struct VoiceCaptureButton: View {
    @Binding var isRecording: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer ring (pulsing when recording)
                Circle()
                    .stroke(isRecording ? Color.coralAlert : Color.deepOcean, lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)

                // Inner circle
                Circle()
                    .fill(isRecording ? Color.coralAlert : Color.deepOcean)
                    .frame(width: 64, height: 64)

                // Icon
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .sensoryFeedback(.impact, trigger: isRecording)
    }
}
```

---

## Animation Patterns

### Task Completion
```swift
extension View {
    func taskCompletionAnimation(_ isCompleted: Bool) -> some View {
        self
            .scaleEffect(isCompleted ? 0.98 : 1.0)
            .opacity(isCompleted ? 0.7 : 1.0)
            .animation(.spring(response: 0.3), value: isCompleted)
    }
}

// Haptic feedback on completion
func completeTask() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
}
```

### Card Entrance
```swift
struct CardEntranceModifier: ViewModifier {
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func cardEntrance(delay: Double = 0) -> some View {
        modifier(CardEntranceModifier(delay: delay))
    }
}
```

---

## Layout Patterns

### Screen Template
```swift
struct ScreenTemplate<Content: View>: View {
    let title: String
    let showMeltdownButton: Bool
    let content: () -> Content

    init(
        title: String,
        showMeltdownButton: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.showMeltdownButton = showMeltdownButton
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .foregroundColor(.deepText)
                Spacer()
                if showMeltdownButton {
                    MeltdownButton { /* handle */ }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            // Content
            ScrollView {
                content()
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
            }
        }
        .background(Color.cloudWhite)
    }
}
```

---

## Dark Mode Considerations

```swift
extension Color {
    // Adaptive colors
    static let adaptiveBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "1a202c")
            : UIColor(hex: "f7fafc")
    })

    static let adaptiveText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "f7fafc")
            : UIColor(hex: "2d3748")
    })
}
```

---

## Meltdown Mode Styling

When meltdown is active, apply these overrides:
```swift
struct MeltdownTheme {
    static let background = Color(hex: "1a202c")     // Dark, calm
    static let text = Color(hex: "a0aec0")           // Muted
    static let accent = Color(hex: "4a5568")         // Very subtle
}
```

---

## Usage Examples

### Creating a new view
```swift
struct ContractView: View {
    @State private var viewModel = ContractViewModel()

    var body: some View {
        ScreenTemplate(title: "Today's Contract") {
            VStack(spacing: Spacing.lg) {
                // Stability bar
                StabilityBar(progress: viewModel.stabilityProgress)

                // Anchor tasks
                Section("Anchor Tasks") {
                    ForEach(viewModel.anchorTasks) { task in
                        TaskCard(task: task) {
                            viewModel.completeTask(task)
                        }
                        .cardEntrance(delay: Double(index) * 0.1)
                    }
                }

                // Side quests
                Section("Side Quests") {
                    ForEach(viewModel.sideQuests) { task in
                        TaskCard(task: task) {
                            viewModel.completeTask(task)
                        }
                    }
                }
            }
        }
    }
}
```

---

## Skill Invocation

When `/design` is called:
1. Ask what view/component is needed
2. Reference this design system
3. Generate SwiftUI code following patterns above
4. Include animations and haptics where appropriate
5. Ensure accessibility (VoiceOver labels, dynamic type)
