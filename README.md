# Cove

An ADHD-friendly task management iOS app that uses AI to help you capture, classify, and complete what matters.

## The Problem

Traditional task apps fail people with ADHD because they:
- Allow infinite task lists that become overwhelming
- Don't account for time blindness or energy fluctuations
- Treat all tasks equally regardless of interest or difficulty
- Punish missed tasks instead of celebrating progress

## The Solution

Cove is designed around how ADHD brains actually work:

### The Daily Contract
Instead of endless lists, you commit to just **3 Anchor Tasks** and **2 Side Quests** each day. That's it. The app enforces this limit—you can't add more without removing something first.

### AI-Powered Capture
Brain dump everything via voice or text. Cove's AI (powered by Claude) automatically classifies your input:
- **Directives** — Actionable tasks with time/energy estimates
- **Archive** — Reference material to save
- **Venting** — Emotional processing (acknowledged, not actionized)

PII is automatically redacted before anything reaches the API.

### Meltdown Protocol
Having a rough day? One tap activates Meltdown Protocol:
- Hides all gamification and metrics
- Shows only essential self-care tasks ("Goblin Mode")
- Bail-out message generator for canceling commitments
- No guilt, no judgment—just recovery

### Smart Progress
- XP system across 4 skill categories (Focus, Energy Management, Emotional Regulation, Consistency)
- 12 unlockable achievements
- Activity heatmap and streak tracking
- Pattern learning that adapts to your energy rhythms
- Micro-coaching nudges when you stall

### Calendar & Scheduling
- Apple Calendar sync with conflict detection
- Auto-schedule tasks to available time slots
- Reality Check with pessimism buffer (1.5x estimates)
- Over-scheduling warnings

### Integrations
- **Apple Reminders** — Import existing reminders as Cove tasks
- **Apple Calendar** — Two-way event sync
- **Siri Shortcuts** — "Brain dump to Cove", "What's my contract?", and more
- **iOS Share Extension** — Send content from any app to Cove
- **Google Calendar** — Optional sync
- **Obsidian** — Export tasks and patterns to your vault

## Tech Stack

| Component | Technology |
|-----------|------------|
| Platform | iOS 17+ |
| UI | SwiftUI |
| Data | SwiftData (local-first) |
| AI | Claude API (Anthropic) |
| Voice | iOS Speech Framework (on-device) |
| Calendar | EventKit |
| Reminders | EventKit |
| Notifications | UNUserNotificationCenter |
| Secrets | iOS Keychain |
| Intents | App Intents (Siri Shortcuts) |

## Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ Simulator or Device
- Claude API key from [Anthropic](https://console.anthropic.com)

### Setup
1. Clone the repo
   ```bash
   git clone https://github.com/asquitt/cove.git
   cd cove
   ```

2. Open in Xcode
   ```bash
   open Cove/Cove.xcodeproj
   ```

3. Build and run on simulator

4. Add your Claude API key in the app's Settings tab

## Architecture

MVVM with SwiftData persistence and actor-based services.

```
Cove/
├── CoveApp.swift              # Entry point & model registration
├── ContentView.swift          # Tab navigation
├── Models/                    # SwiftData models
│   ├── Task.swift             # Core task model (bucket, status, energy, interest)
│   ├── DailyContract.swift    # 3+2 constraint, stability tracking
│   ├── UserProfile.swift      # Settings, XP, streaks
│   ├── CapturedInput.swift    # Voice/text capture storage
│   ├── SkillCategory.swift    # 4 XP skill types
│   ├── DailyActivity.swift    # Daily stats for heatmap
│   ├── Achievement.swift      # 12 achievement types
│   └── TaskPattern.swift      # Productivity & energy patterns
├── Views/
│   ├── Home/                  # Dashboard with suggestions
│   ├── Capture/               # Brain dump, staging, reminders import
│   ├── Contract/              # Daily contract with task cards
│   ├── Calendar/              # Week view with time blocks
│   ├── Meltdown/              # Meltdown protocol & bail-out
│   ├── Progress/              # XP, achievements, heatmap, energy insights
│   ├── Settings/              # Profile, API key, integrations
│   └── Components/            # AI companion, shared components
├── ViewModels/
│   └── ContractViewModel.swift
├── Services/
│   ├── ClaudeAIService.swift  # AI classification (actor-based)
│   ├── SpeechService.swift    # On-device voice transcription
│   ├── GamificationService.swift
│   ├── PatternService.swift   # Adaptive learning
│   ├── CalendarService.swift  # Apple Calendar (EventKit)
│   ├── RemindersService.swift # Apple Reminders import
│   ├── NotificationService.swift
│   ├── PIIRedactionService.swift
│   ├── ColdStorageService.swift
│   ├── GoogleCalendarService.swift
│   ├── ObsidianService.swift
│   └── ShareExtensionService.swift
├── Intents/
│   └── CoveAppIntents.swift   # Siri Shortcuts
└── Utilities/
    ├── Constants.swift
    ├── KeychainHelper.swift
    └── Extensions/
```

## Security

- API keys stored exclusively in iOS Keychain (never in SwiftData)
- Keychain items restricted to `WhenUnlockedThisDeviceOnly`
- PII automatically redacted before AI processing
- Voice transcription runs entirely on-device
- Input validation and length limits on all AI calls
- No third-party analytics or tracking

## Design Philosophy

**Constraint is freedom.** By limiting daily tasks to 5, we force prioritization and prevent the paralysis of infinite choice.

**Completion over perfection.** A "done" task at 80% beats a "perfect" task that never ships.

**Energy-aware scheduling.** Match tasks to your current state, not an idealized version of yourself.

**Recovery is productive.** Meltdown Protocol treats self-care as a first-class feature, not a failure mode.

## Project Status

All core features implemented. See [PROGRESS.md](PROGRESS.md) for detailed history.

| Phase | Status |
|-------|--------|
| Foundation | Done |
| Capture & AI | Done |
| Contract System | Done |
| Meltdown Protocol | Done |
| Calendar Integration | Done |
| XP & Gamification | Done |
| Pattern Learning | Done |
| Polish & Dark Mode | Done |
| Security Audit | Done |
| PRD Completion | Done |

## License

MIT

## Acknowledgments

Built with [Claude](https://claude.ai) by Anthropic.
