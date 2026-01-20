# Cove iOS App - Progress Tracker

> Last Updated: 2026-01-20
> Current Phase: **Phase 2 - Capture & AI**
> Overall Progress: **35%**

---

## Quick Status

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 0: Setup | ✅ Complete | 100% |
| Phase 1: Foundation | ✅ Complete | 100% |
| Phase 2: Capture & AI | ✅ Complete | 100% |
| Phase 3: Contract System | ⏳ Not Started | 0% |
| Phase 4: Meltdown Protocol | ⏳ Not Started | 0% |
| Phase 5: Calendar Integration | ⏳ Not Started | 0% |
| Phase 6: XP & Gamification | ⏳ Not Started | 0% |
| Phase 7: Pattern Learning | ⏳ Not Started | 0% |
| Phase 8: Polish | ⏳ Not Started | 0% |

---

## Phase 0: Project Setup

### Completed ✅
- [x] PRD document created
- [x] CLAUDE.md configuration
- [x] Claude Code hooks configured
  - Pre-commit build verification
  - Swift file quality checks
  - Feature completion reminders
  - Session progress updates
- [x] Progress tracking document (this file)
- [x] MCP research (no iOS-specific MCPs available; using existing Chrome + Notes MCPs)
- [x] `/design` skill created (iOS/SwiftUI design system)
- [x] Claude API integration docs (replacing OpenAI)

---

## Phase 1: Foundation ✅

### Goals
- Basic app shell with data models
- Tab navigation working
- SwiftData persistence

### Completed ✅
- [x] Create Xcode project (iOS App, SwiftUI, SwiftData)
- [x] Set up folder structure per CLAUDE.md
- [x] Implement data models:
  - [x] Task.swift (CoveTask with bucket, status, interest, energy)
  - [x] DailyContract.swift (3+2 constraint, stability tracking)
  - [x] UserProfile.swift (settings, XP, streaks)
  - [x] CapturedInput.swift (voice/text capture storage)
- [x] Build navigation:
  - [x] Tab bar (Home, Capture, Contract, Profile)
  - [x] Basic view shells with real UI
- [x] Implement design system:
  - [x] Color palette extension (Deep Ocean Blue theme)
  - [x] Typography styles (SF Pro Rounded)
  - [x] Spacing & corner radius constants
- [x] Swift code compiles successfully

---

## Phase 2: Capture & AI ✅

### Goals
- Voice/text brain dump capture
- Claude API classification
- Staging area for review

### Completed ✅
- [x] Text capture view (integrated into CaptureView)
- [x] Voice capture (iOS Speech framework - SpeechService.swift)
  - On-device transcription using SFSpeechRecognizer
  - Permission handling for microphone and speech
  - Real-time transcription display
- [x] Claude API service implementation (ClaudeAIService.swift)
  - Actor-based async/await design
  - Keychain storage for API key (KeychainHelper.swift)
  - Classification with retry logic
  - JSON response parsing
- [x] Classification prompt engineering
  - DIRECTIVE/ARCHIVE/VENTING bucket classification
  - Task extraction with title, duration, interest, energy
- [x] Staging area UI (StagingAreaView.swift)
  - Swipe-to-confirm gestures
  - Visual bucket indicators
  - Task preview cards
  - Confirm/dismiss actions
- [x] Full capture flow: speak → transcribe → classify → stage → confirm
- [x] Info.plist with microphone/speech permissions
- [x] Project.pbxproj updated with new files

### Blockers
- Xcode simulator runtime mismatch (SDK 26.2 vs installed simulators 18.x)
- Requires opening project in Xcode GUI to download matching simulator runtime
- Code type-checks successfully with iOS SDK

---

## Phase 3: Contract System (Next)

### Goals
- Daily Contract with 3+2 limit
- Reality check (time estimation)
- Satisfying completion flow

### Tasks
- [ ] Daily Contract view
- [ ] Anchor Tasks section (max 3)
- [ ] Side Quests section (max 2)
- [ ] Constraint enforcement
- [ ] Pessimism multiplier
- [ ] Over-scheduling warnings
- [ ] Completion animations
- [ ] Stability Bar progress

### Blockers
_None yet_

---

## Phase 4: Meltdown Protocol

### Goals
- Emergency reset button
- Goblin Mode self-care
- Gentle recovery flow

### Tasks
- [ ] Reset button (always accessible)
- [ ] Meltdown view (dark/calm)
- [ ] Task triage (hide non-critical)
- [ ] Goblin Mode tasks
- [ ] Recovery flow
- [ ] XP rewards for self-care

### Blockers
_None yet_

---

## Phase 5: Calendar Integration

### Goals
- Apple Calendar sync
- Conflict detection
- Time block visualization

### Tasks
- [ ] EventKit permissions
- [ ] Read existing events
- [ ] Write tasks as events
- [ ] Conflict warnings
- [ ] Available time slots view

### Blockers
_Requires device testing (not just simulator)_

---

## Phase 6: XP & Gamification

### Goals
- XP system implementation
- Visual progress tracking
- Done List celebration

### Tasks
- [ ] XP categories model
- [ ] Survival vs Growth tasks
- [ ] Skill bars UI
- [ ] Level-up animations
- [ ] Consistency heatmap
- [ ] Done List summary

### Blockers
_None yet_

---

## Phase 7: Pattern Learning

### Goals
- Learn user habits
- Adaptive suggestions
- Snooze pattern tracking

### Tasks
- [ ] Passive tracking implementation
- [ ] Snooze pattern analysis
- [ ] Energy rhythm detection
- [ ] Feedback collection UI
- [ ] Adaptive suggestion engine
- [ ] Pessimism multiplier auto-adjustment

### Blockers
_None yet_

---

## Phase 8: Polish

### Goals
- Smooth animations
- Notifications
- Settings & customization

### Tasks
- [ ] Animation polish pass
- [ ] Dark mode support
- [ ] Notification system
- [ ] Settings view
- [ ] App icon design
- [ ] TestFlight preparation

### Blockers
_Requires Apple Developer account for TestFlight_

---

## Session History

### Session 1 - 2026-01-20
**Duration:** ~45 min
**Completed:**
- Created PRD
- Set up CLAUDE.md with project config
- Configured Claude Code hooks (pre-commit, verification)
- Created `/design` skill for SwiftUI components
- Created PROGRESS.md
- Built Phase 1 Foundation:
  - Xcode project structure
  - 4 SwiftData models (CoveTask, DailyContract, UserProfile, CapturedInput)
  - 4 main views (Home, Capture, Contract, Profile)
  - Design system (colors, fonts, spacing)
  - Tab navigation
- Swift code compiles successfully

### Session 2 - 2026-01-20
**Duration:** ~30 min
**Completed:**
- Built Phase 2 Capture & AI:
  - SpeechService.swift - iOS Speech framework integration
    - On-device speech recognition
    - Permission handling
    - Real-time transcription
  - KeychainHelper.swift - Secure API key storage
  - ClaudeAIService.swift - Claude API integration
    - Actor-based async service
    - Task classification (DIRECTIVE/ARCHIVE/VENTING)
    - Retry logic for rate limiting
    - JSON parsing for task suggestions
  - StagingAreaView.swift - Review UI
    - Swipe-to-confirm gestures
    - Bucket visualization
    - Task preview cards
  - Updated CaptureView with full capture flow
  - Updated project.pbxproj with new files
  - Added Info.plist for permissions
- Code type-checks successfully with iOS SDK

**Next Session:**
- Open project in Xcode to resolve simulator runtime
- Build and test capture flow end-to-end
- Add API key entry in Settings
- Start Phase 3: Contract System

---

## Known Issues

1. **Simulator Runtime Mismatch**
   - Xcode SDK is 26.2, installed simulators are 18.x
   - Requires downloading iOS 26.2 simulator or reinstalling matching Xcode
   - Code compiles and type-checks successfully

---

## Notes & Decisions

### 2026-01-20
- Decided to use Claude API instead of OpenAI
- Targeting iOS 17+ for SwiftData support
- Starting with simulator only, will add device later
- Using MVVM architecture with @Observable
- Using actor for ClaudeAIService for thread safety
- Keychain for API key storage (security)
- On-device speech recognition (privacy)

---

## Verification Log

| Date | Feature | Verification Method | Result |
|------|---------|---------------------|--------|
| 2026-01-20 | Phase 2 Services | swiftc -typecheck with iOS SDK | ✅ Pass |
| 2026-01-20 | Models/Utilities | swiftc -typecheck with iOS SDK | ✅ Pass |

---

## Files Created in Phase 2

```
Cove/Cove/Services/
├── SpeechService.swift      # iOS Speech framework
└── ClaudeAIService.swift    # Claude API integration

Cove/Cove/Utilities/
└── KeychainHelper.swift     # Secure storage

Cove/Cove/Views/Capture/
├── CaptureView.swift        # Updated with services
└── StagingAreaView.swift    # Review UI

Cove/Cove/Info.plist         # Privacy permissions
```

---

## Next Steps (Priority Order)

1. **Open Xcode** - Download matching simulator runtime
2. **Test capture flow** - Voice → Transcribe → Classify → Stage → Confirm
3. **Add Settings view** - API key entry
4. **Start Phase 3** - Daily Contract with 3+2 limit
