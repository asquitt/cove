# Cove iOS App - Progress Tracker

> Last Updated: 2026-01-20
> Current Phase: **Phase 1 - Foundation**
> Overall Progress: **15%**

---

## Quick Status

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 0: Setup | ✅ Complete | 100% |
| Phase 1: Foundation | ✅ Complete | 100% |
| Phase 2: Capture & AI | ⏳ Not Started | 0% |
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

### In Progress 🔄
_None_

### Ready for Phase 1 ⏳
- [ ] Create Xcode project
- [ ] Initialize git repository
- [ ] Set up folder structure

---

## Phase 1: Foundation (Week 1-2) ✅

### Goals
- Basic app shell with data models
- Tab navigation working
- SwiftData persistence

### Tasks
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

### Blockers
- Simulator runtime mismatch (Xcode SDK vs installed simulators) - system config issue, not code
- Will resolve when you open project in Xcode GUI

---

## Phase 2: Capture & AI (Week 3-4)

### Goals
- Voice/text brain dump capture
- Claude API classification
- Staging area for review

### Tasks
- [ ] Text capture view
- [ ] Voice capture (iOS Speech framework)
- [ ] Claude API service implementation
- [ ] Classification prompt engineering
- [ ] Staging area UI (swipe to confirm)
- [ ] Integration tests

### Blockers
_None yet_

---

## Phase 3: Contract System (Week 5-6)

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

## Phase 4: Meltdown Protocol (Week 7)

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

## Phase 5: Calendar Integration (Week 8)

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

## Phase 6: XP & Gamification (Week 9-10)

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

## Phase 7: Pattern Learning (Week 11-12)

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

## Phase 8: Polish (Week 12+)

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

**Next Session:**
- Open project in Xcode to resolve simulator runtime
- Implement voice capture (iOS Speech framework)
- Build Claude API service for classification
- Create staging area UI

---

## Known Issues

_No issues yet_

---

## Notes & Decisions

### 2025-01-20
- Decided to use Claude API instead of OpenAI
- Targeting iOS 17+ for SwiftData support
- Starting with simulator only, will add device later
- Using MVVM architecture with @Observable

---

## Verification Log

| Date | Feature | Verification Method | Result |
|------|---------|---------------------|--------|
| _None yet_ | | | |

---

## Next Steps (Priority Order)

1. **Create Xcode project** - Basic iOS app with SwiftUI + SwiftData
2. **Implement Task model** - Core data structure
3. **Build tab navigation** - Home, Capture, Contract, Profile
4. **Add color palette** - Design system foundation
5. **Test data persistence** - Verify SwiftData works
