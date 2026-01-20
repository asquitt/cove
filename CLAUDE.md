# Cove iOS App - Claude Code Configuration

## Project Overview
**Cove** - An ADHD-friendly task management iOS app built with SwiftUI + SwiftData + Claude API.

## Tech Stack
- **Platform:** iOS 17+
- **UI:** SwiftUI
- **Data:** SwiftData (local persistence)
- **AI:** Claude API (Anthropic) for task classification
- **Voice:** iOS Speech framework (on-device transcription)
- **Calendar:** EventKit

## Project Structure
```
Cove/
├── CoveApp.swift                 # App entry point
├── Models/                       # SwiftData models
│   ├── Task.swift
│   ├── DailyContract.swift
│   ├── UserProfile.swift
│   ├── CapturedInput.swift
│   └── XPCategory.swift
├── Views/                        # SwiftUI views
│   ├── Home/
│   ├── Capture/
│   ├── Contract/
│   ├── Meltdown/
│   ├── Progress/
│   └── Settings/
├── ViewModels/                   # View models (MVVM)
├── Services/                     # Business logic
│   ├── ClaudeAIService.swift     # Claude API integration
│   ├── SpeechService.swift
│   ├── ContractService.swift
│   ├── CalendarService.swift
│   └── PatternService.swift
└── Utilities/
    ├── Extensions/
    ├── Constants.swift
    └── KeychainHelper.swift
```

## Core Concepts

### The Daily Contract
- Maximum 3 Anchor Tasks (critical)
- Maximum 2 Side Quests (optional)
- Enforced constraint - can't add more without removing

### AI Classification Buckets
- **Bucket A (Directives):** Actionable tasks
- **Bucket B (Archive):** Reference material
- **Bucket C (Venting):** Emotional processing

### Meltdown Protocol
- Reset button always accessible
- Hides gamification, shows only essentials
- "Goblin Mode" for self-care tasks

## API Configuration

### Claude API
- **Model:** claude-sonnet-4-20250514 (fast, cost-effective)
- **API Key Location:** iOS Keychain (never in code/logs)
- **Endpoint:** https://api.anthropic.com/v1/messages

### API Key Setup
User must add their Claude API key in app Settings. Store using KeychainHelper:
```swift
KeychainHelper.save(key: "claude_api_key", value: apiKey)
```

## Design System

### Colors (Deep Ocean Blue Palette)
```swift
// Primary
Color("DeepOcean")       // #1a365d - Primary actions
Color("CalmSea")         // #2c5282 - Secondary
Color("SoftWave")        // #4a90a4 - Accents

// States
Color("ZenGreen")        // #48bb78 - Success/Complete
Color("WarmSand")        // #ed8936 - Warning
Color("CoralAlert")      // #fc8181 - Danger/Reset

// Neutrals
Color("CloudWhite")      // #f7fafc - Background
Color("MistGray")        // #e2e8f0 - Subtle borders
Color("DeepText")        // #2d3748 - Primary text
```

### Typography
- **Font:** SF Pro Rounded (system)
- **Headings:** .bold, sizes 28/24/20
- **Body:** .regular, size 17
- **Captions:** .regular, size 13

### Haptics
- Task complete: `.success`
- Contract filled: `.warning`
- Meltdown activated: `.soft`

## Verification Requirements

### Before ANY Commit
1. `xcodebuild -scheme Cove -destination 'platform=iOS Simulator,name=iPhone 15' build` - Must succeed
2. `xcodebuild test -scheme Cove -destination 'platform=iOS Simulator,name=iPhone 15'` - All tests pass
3. No compiler warnings (treat warnings as errors)
4. SwiftLint passes (if configured)

### Feature Verification
- UI changes: Take simulator screenshot, describe what changed
- AI features: Test with sample input, show classification result
- Data changes: Query SwiftData, show persisted values

## Coding Standards

### SwiftUI Best Practices
```swift
// GOOD - Extract subviews
struct TaskCard: View {
    let task: Task
    var body: some View {
        VStack { ... }
    }
}

// BAD - Massive nested views
var body: some View {
    VStack {
        HStack {
            VStack {
                // 200 lines of nesting...
            }
        }
    }
}
```

### Async/Await
```swift
// GOOD - Modern concurrency
func classifyInput(_ text: String) async throws -> Classification {
    let response = try await claudeService.classify(text)
    return response
}

// BAD - Completion handlers
func classifyInput(_ text: String, completion: @escaping (Result<Classification, Error>) -> Void) {
    // Callback hell
}
```

### Error Handling
```swift
// GOOD - Specific errors
enum CoveError: LocalizedError {
    case apiKeyMissing
    case classificationFailed(String)
    case contractFull

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "Please add your Claude API key in Settings"
        case .classificationFailed(let reason): return "Classification failed: \(reason)"
        case .contractFull: return "Daily contract is full. Remove a task first."
        }
    }
}
```

### View Models
```swift
@Observable
class ContractViewModel {
    private let contractService: ContractService

    var anchorTasks: [Task] = []
    var sideQuests: [Task] = []
    var isLoading = false
    var error: CoveError?

    func addTask(_ task: Task) throws {
        guard anchorTasks.count < 3 else {
            throw CoveError.contractFull
        }
        // ...
    }
}
```

## File Limits
- Max 300 lines per Swift file
- Extract components when views exceed 150 lines
- One model per file
- One service per file

## Testing Strategy

### Unit Tests
- All service methods
- ViewModel logic
- Model validation

### UI Tests
- Critical flows: Capture → Classify → Confirm → Complete
- Meltdown Protocol activation
- Contract constraints

## Common Patterns

### Claude API Call
```swift
struct ClaudeRequest: Codable {
    let model: String
    let max_tokens: Int
    let messages: [Message]

    struct Message: Codable {
        let role: String
        let content: String
    }
}

// Usage
let request = ClaudeRequest(
    model: "claude-sonnet-4-20250514",
    max_tokens: 1024,
    messages: [.init(role: "user", content: prompt)]
)
```

### SwiftData Query
```swift
@Query(sort: \Task.createdAt, order: .reverse)
private var tasks: [Task]

// Filtered query
@Query(filter: #Predicate<Task> { $0.status == .pending })
private var pendingTasks: [Task]
```

## Progress Tracking
See `PROGRESS.md` for current phase, completed features, and next steps.

## Quick Commands

```bash
# Build
xcodebuild -scheme Cove -destination 'platform=iOS Simulator,name=iPhone 15' build

# Test
xcodebuild test -scheme Cove -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean
xcodebuild clean -scheme Cove

# List simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 15"

# Open simulator
open -a Simulator
```

## DO NOT
- Hardcode API keys
- Skip build verification
- Commit with warnings
- Create massive view files
- Use completion handlers (prefer async/await)
- Add features not in current phase

## ALWAYS
- Verify builds compile before committing
- Test AI features with real input
- Update PROGRESS.md after completing features
- Follow the Daily Contract principle: small, focused commits
