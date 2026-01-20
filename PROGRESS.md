# Cove iOS App - Progress Tracker

> Last Updated: 2026-01-20
> Current Phase: **Phase 4 - Meltdown Protocol** ✅
> Overall Progress: **60%**

---

## Quick Status

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 0: Setup | ✅ Complete | 100% |
| Phase 1: Foundation | ✅ Complete | 100% |
| Phase 2: Capture & AI | ✅ Complete | 100% |
| Phase 3: Contract System | ✅ Complete | 100% |
| Phase 4: Meltdown Protocol | ✅ Complete | 100% |
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

## Phase 3: Contract System ✅

### Goals
- Daily Contract with 3+2 limit
- Reality check (time estimation)
- Satisfying completion flow

### Completed ✅
- [x] ContractViewModel.swift - Contract state management
  - Load/create daily contracts
  - Task add/remove/complete operations
  - Unassigned task filtering
  - Error handling
- [x] TaskCardView.swift - Task display components
  - Swipe-to-complete gesture
  - Task status indicators (pending/inProgress/completed)
  - Remove task button
  - Haptic feedback on status changes
- [x] CompletionCelebrationView - Celebration overlay
  - Animated checkmark
  - XP display (+10 XP)
  - Auto-dismiss after 1.5s
  - Success haptic
- [x] StabilityBarView - Progress visualization
  - Color-coded (red/yellow/green)
  - Animated progress
  - Score percentage display
- [x] ProgressRingView - Circular progress
  - Task completion percentage
  - Color-coded based on progress
- [x] ContractView.swift - Full contract UI
  - Reality Check card (estimated/buffered time)
  - Pessimism multiplier (1.5x buffer)
  - Anchor Tasks section (max 3)
  - Side Quests section (max 2)
  - Unassigned tasks section
  - Over-scheduling warnings (>6h)
  - Contract Complete celebration card
  - Empty state with create button
- [x] ContentView.swift - Tab navigation
  - Home, Contract, Capture, Profile tabs
  - Deep Ocean tint color
- [x] Constraint enforcement
  - 3 anchor tasks maximum
  - 2 side quests maximum
  - Counter badges with warnings
- [x] Swift type-check passes

---

## Phase 4: Meltdown Protocol ✅

### Goals
- Emergency reset button
- Goblin Mode self-care
- Gentle recovery flow

### Completed ✅
- [x] MeltdownView.swift - Full-screen calming interface
  - Dark/calm color scheme (meltdownBackground)
  - Animated breathing exercise with phases
  - Breathing circle with scale animation
  - Encouraging messages
- [x] Goblin Mode - Self-care task system
  - 8 gentle self-care tasks (water, stretch, snack, etc.)
  - XP rewards (+5 XP per task)
  - Visual completion tracking
  - Haptic feedback on completion
- [x] Meltdown button in toolbar (HomeView, ContractView)
  - Always accessible via navigation bar
  - Full-screen cover presentation
- [x] Recovery flow
  - "I'm feeling better" exit button
  - Meltdown count tracking per day
  - Stability score adjustment on meltdown
- [x] Integration with existing models
  - DailyContract.activateMeltdown() / deactivateMeltdown()
  - UserProfile.recordMeltdown() / recordTaskCompletion()
- [x] Swift type-check passes

---

## Phase 5: Calendar Integration (Next)

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
- GitHub repo created: https://github.com/asquitt/cove

### Session 2 (continued) - 2026-01-20
**Duration:** ~20 min
**Completed:**
- Built Phase 3 Contract System:
  - ContractViewModel.swift - Contract state management
  - TaskCardView.swift - Swipe-to-complete task cards
  - CompletionCelebrationView - Animated completion overlay
  - StabilityBarView - Color-coded progress bar
  - ProgressRingView - Circular progress indicator
  - ContentView.swift - Tab navigation with 4 tabs
  - Updated ContractView.swift - Full contract UI with:
    - Reality Check card with pessimism buffer
    - Anchor Tasks section (max 3)
    - Side Quests section (max 2)
    - Unassigned tasks section
    - Over-scheduling warnings
    - Contract complete celebration
  - Fixed SwiftData predicate syntax (enum comparison issues)
  - Updated HomeView to use shared StabilityBarView
- Code type-checks successfully with iOS SDK
- Pushed to GitHub

### Session 3 - 2026-01-20
**Duration:** ~15 min
**Completed:**
- Built Phase 4 Meltdown Protocol:
  - MeltdownView.swift - Full-screen calming interface
    - Dark color scheme with calming aesthetics
    - Animated breathing exercise (inhale/hold/exhale)
    - Breathing circle with scale animation
    - Encouraging messages throughout
  - Goblin Mode - Self-care task system
    - 8 gentle tasks: water, stretch, snack, bathroom, walk, window, breathe, music
    - +5 XP per completed task
    - Visual completion states
    - Haptic feedback on completion
  - Integrated meltdown button in HomeView and ContractView toolbars
  - Full-screen cover presentation for immersive experience
  - Recovery flow with "I'm feeling better" exit
  - Meltdown tracking (count, stability adjustment)
- Code type-checks successfully with iOS SDK
- Pushed to GitHub

**Next Session:**
- Open project in Xcode to resolve simulator runtime
- Build and test full flow end-to-end
- Start Phase 5: Calendar Integration

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
- SwiftData predicates don't support enum comparisons directly - use computed properties with filter instead
- Pessimism multiplier set to 1.5x (configurable in Constants)
- Over-scheduling warning triggers at >360 minutes (6 hours)

---

## Verification Log

| Date | Feature | Verification Method | Result |
|------|---------|---------------------|--------|
| 2026-01-20 | Phase 2 Services | swiftc -typecheck with iOS SDK | ✅ Pass |
| 2026-01-20 | Models/Utilities | swiftc -typecheck with iOS SDK | ✅ Pass |
| 2026-01-20 | Phase 3 Contract System | swiftc -typecheck with iOS SDK | ✅ Pass |
| 2026-01-20 | Phase 4 Meltdown Protocol | swiftc -typecheck with iOS SDK | ✅ Pass |

---

## Files Created in Phase 4

```
Cove/Cove/Views/Meltdown/
└── MeltdownView.swift         # Full meltdown experience
    - BreathingPhase enum
    - GoblinTask enum (8 self-care tasks)
    - GoblinTaskCard component
    - MeltdownTriggerButton component

Cove/Cove/Views/Home/
└── HomeView.swift             # Updated with meltdown integration

Cove/Cove/Views/Contract/
└── ContractView.swift         # Updated with meltdown integration
```

---

## Next Steps (Priority Order)

1. **Open Xcode** - Download matching simulator runtime
2. **Test full flow** - Capture → Classify → Stage → Contract → Complete → Meltdown
3. **Start Phase 5** - Calendar Integration with EventKit
