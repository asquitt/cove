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
- **Directives** → Actionable tasks with time estimates
- **Archive** → Reference material to save
- **Venting** → Emotional processing (acknowledged, not actionized)

### Meltdown Protocol
Having a rough day? One tap activates Meltdown Protocol:
- Hides all gamification and metrics
- Shows only essential self-care tasks ("Goblin Mode")
- No guilt, no judgment—just recovery

### Smart Progress Tracking
- XP system that rewards completing boring tasks more than fun ones
- "Survival vs Growth" task categorization
- Pattern learning that adapts to your energy rhythms

## Tech Stack

- **Platform:** iOS 17+
- **UI:** SwiftUI
- **Data:** SwiftData
- **AI:** Claude API (Anthropic)
- **Voice:** iOS Speech Framework (on-device)

## Project Status

Currently in development. See [PROGRESS.md](PROGRESS.md) for detailed status.

| Phase | Status |
|-------|--------|
| Foundation | ✅ Complete |
| Capture & AI | ✅ Complete |
| Contract System | 🔜 Next |
| Meltdown Protocol | ⏳ Planned |
| Calendar Integration | ⏳ Planned |
| XP & Gamification | ⏳ Planned |

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

4. Add your Claude API key in the app's Settings

## Architecture

```
Cove/
├── Models/           # SwiftData models
├── Views/            # SwiftUI views
├── ViewModels/       # @Observable view models
├── Services/         # Business logic & API
└── Utilities/        # Extensions & helpers
```

### Key Files
- `ClaudeAIService.swift` - AI classification
- `SpeechService.swift` - Voice capture
- `CaptureView.swift` - Brain dump interface
- `StagingAreaView.swift` - Review & confirm tasks

## Design Philosophy

**Constraint is freedom.** By limiting daily tasks to 5, we force prioritization and prevent the paralysis of infinite choice.

**Completion over perfection.** A "done" task at 80% beats a "perfect" task that never ships.

**Energy-aware scheduling.** Match tasks to your current state, not an idealized version of yourself.

## License

MIT

## Acknowledgments

Built with [Claude](https://claude.ai) by Anthropic.
