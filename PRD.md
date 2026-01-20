# Product Requirements Document (PRD)

**App Name:** Cove
**Tagline:** "Your Safe Harbor from Executive Dysfunction"
**Platform:** iOS (MVP)
**Version:** 1.0
**Last Updated:** January 2026

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Target Audience](#3-target-audience)
4. [Core Philosophy & Psychology](#4-core-philosophy--psychology)
5. [Competitive Analysis & Differentiation](#5-competitive-analysis--differentiation)
6. [Feature Requirements](#6-feature-requirements)
7. [UI/UX Design System](#7-uiux-design-system)
8. [Technical Architecture](#8-technical-architecture)
9. [Success Metrics](#9-success-metrics)
10. [Roadmap](#10-roadmap)
11. [Appendix: Research Foundation](#11-appendix-research-foundation)

---

## 1. Executive Summary

Cove is an iOS productivity app designed specifically for adults with ADHD and executive dysfunction. Unlike traditional task managers that treat all tasks as equal and punish missed deadlines, Cove functions as an **Executive Function Prosthetic**—filtering unrealistic expectations, negotiating workload based on energy and emotional state, and preventing shame spirals when things go wrong.

**Core Insight:** People with ADHD don't need another list. They need a system that understands their brain works differently and adapts accordingly.

**Key Differentiators:**
- Interest-based task organization (not importance-based)
- Emotional state awareness and adaptive scaffolding
- Shame-resistant design with no "overdue" badges or red text
- Hyperfocus protection rather than interruption
- The "Contract" system limiting daily commitments to prevent overwhelm

---

## 2. Problem Statement

### 2.1 The Core Problem

Adults with ADHD suffer from three interlocking challenges:

| Challenge | Description | Impact |
|-----------|-------------|--------|
| **Execution Paralysis** | Too many options/tasks cause complete shutdown | Nothing gets done despite capability |
| **Time Blindness** | Impaired perception of time passing and duration estimation | Chronic lateness, missed deadlines, unrealistic planning |
| **Shame Spirals** | Emotional dysregulation and RSD trigger avoidance | Abandoned apps, self-blame, worsening symptoms |

### 2.2 Why Current Solutions Fail

Existing productivity apps exacerbate these problems:

- **Treat all tasks as equal** — No understanding of energy, interest, or cognitive load
- **Display "overdue" as failure** — Triggers shame and app abandonment
- **Require constant maintenance** — Adding friction to already-impaired executive function
- **Importance-based prioritization** — ADHD brains run on interest, not importance
- **Static, non-adaptive** — Don't learn or respond to user patterns and emotional states
- **One-size-fits-all** — Designed for neurotypical workflows

### 2.3 The Gap

**Current apps manage lists. Cove manages energy, interest, and psychology.**

---

## 3. Target Audience

### 3.1 Primary Persona: "Alex"

**Demographics:**
- Age: 25-45
- Recently diagnosed or self-identified ADHD
- Knowledge worker, creative, or founder
- Has tried and abandoned 5+ productivity apps

**Behavioral Patterns:**
- 50+ unorganized notes in their phone
- Misses deadlines not from laziness but from overwhelm
- Deletes apps that make them feel guilty
- High capability, inconsistent execution
- Hyperfocuses intensely on interesting work, struggles with routine

**Emotional State:**
- Frustrated with themselves
- Suspicious of "productivity" tools
- Craving structure without rigidity
- Needs permission to rest without guilt

**Goals:**
- Get important things done without burning out
- Stop feeling ashamed of their brain
- Find a system that actually works with their neurology

### 3.2 Secondary Personas

| Persona | Description | Key Need |
|---------|-------------|----------|
| **The Founder** | Idea-rich, execution-poor entrepreneur | Grounding scattered vision into action |
| **The Creative** | Artist/writer with inconsistent output | Harnessing hyperfocus, managing dry spells |
| **The Parent** | Managing household + work with ADHD | Reducing cognitive load of "invisible labor" |

### 3.3 Anti-Personas (Not Our Target)

- Users who thrive with traditional GTD systems
- Those seeking complex project management
- Users wanting team/collaborative features (V1)

---

## 4. Core Philosophy & Psychology

### 4.1 The Fundamental Promise

Cove creates a **"Contract"** with the user:

> "Tell me everything. I'll filter the noise, respect your limits, and never shame you when things don't go as planned."

### 4.2 Design Principles

#### Principle 1: Productivity via Subtraction
- Remove options, not add them
- Constrain choices to prevent paralysis
- Hide complexity until needed

#### Principle 2: Interest-Based, Not Importance-Based
Research shows ADHD brains operate on an **interest-based nervous system**. Tasks need to be:
- **Novel** — Fresh, not stale
- **Urgent** — Time pressure creates activation
- **Challenging** — Appropriate difficulty engages attention
- **Interesting** — Intrinsic motivation trumps external importance

*Cove organizes by interest potential, not arbitrary priority.*

#### Principle 3: Shame-Resistant by Default
- No red text, ever
- No "overdue" badges
- No broken streaks
- Reframe failures as experiments
- Private by default

#### Principle 4: Respect the Hyperfocus
Traditional apps try to interrupt hyperfocus. Cove protects it:
- Detect flow states
- Soft reminders that don't break concentration
- Celebrate hyperfocus productivity as a strength

#### Principle 5: Emotional State Awareness
Research confirms emotional dysregulation predicts greater functional impairment than ADHD symptoms alone. Cove must:
- Track emotional signals (explicit and implicit)
- Adapt recommendations to current state
- Provide scaffolding during dysregulation

### 4.3 The "Cozy Sci-Fi" Aesthetic

**The Vibe:** High-tech system wrapped in a calming, safe interface.

Think: *WALL-E meets Headspace*—advanced capability, warm presentation.

**Metaphor:** Clearing the fog
- Start of day: Subtle cloud/particle overlay
- Task completed: Satisfying "pop," clouds clear slightly
- End of day: Clear blue sky/calm water

---

## 5. Competitive Analysis & Differentiation

### 5.1 Competitive Landscape

| App | Strength | Weakness (ADHD Context) |
|-----|----------|-------------------------|
| **Todoist** | Clean, cross-platform | Importance-based, shame-inducing overdue |
| **Things 3** | Beautiful design | Complex hierarchy, no adaptation |
| **Notion** | Infinitely customizable | Requires executive function to set up |
| **Structured** | Time-blocking | Rigid scheduling, no emotional awareness |
| **Tiimo** | ADHD-focused visuals | Limited AI, basic planning |
| **Focusmate** | Body doubling | Requires social coordination |

### 5.2 Cove's Differentiation Matrix

| Feature | Traditional Apps | Cove |
|---------|------------------|------|
| Task Organization | Importance/deadline | Interest + Energy + Context |
| Missed Deadline | "Overdue" badge | Silent rescheduling |
| AI Role | None or basic | Empathetic coach + filter |
| Emotional State | Ignored | Core input to planning |
| Hyperfocus | Interrupted | Protected |
| Gamification | Streaks (shame) | XP system (growth) |
| Recovery | Start over | "Meltdown Protocol" |

### 5.3 Moat Strategy

**Short-term Moat (0-12 months):**
- ADHD-specific AI prompt engineering
- Shame-resistant UX patterns
- The "Contract" system

**Medium-term Moat (12-24 months):**
- Behavioral pattern learning (personalized predictions)
- Interest-based scheduling algorithm
- Community of ADHD-specific coaches/content

**Long-term Moat (24+ months):**
- Proprietary dataset of ADHD task completion patterns
- Integration ecosystem with ADHD-friendly services
- Potential research partnerships with academic institutions

---

## 6. Feature Requirements

### 6.1 Feature Set 1: The Input Engine ("The Chaos Engine")

**Goal:** Capture everything, organize silently, respect privacy.

#### 6.1.1 Voice Capture
- **UI:** Large, prominent microphone button
- **Tech:** OpenAI Whisper API (or iOS Dictation fallback)
- **Behavior:** Accept messy, unstructured brain dumps
- **Example Input:** "uh buy milk and also I need to call diana about the thing and oh god the api bug is still broken"

#### 6.1.2 Text Capture
- **UI:** Simple text field, no formatting required
- **Behavior:** Accept lists, fragments, full sentences
- **Example Input:** "Buy milk, call diana, fix the api bug!!!"

#### 6.1.3 External Integration
- **Apple Calendar:** Read-only scanning via EventKit
- **Apple Reminders:** Read-only scanning via EventKit
- **Apple Notes Workaround:** iOS Shortcut "Send to Cove" (direct API access restricted)

#### 6.1.4 Privacy Sandbox
- **Local PII Redactor:** Automatically detect and ignore:
  - Patterns resembling passwords
  - Health data
  - API keys/tokens
  - Financial account numbers
- **Tag as "Sensitive":** Flagged content excluded from AI processing
- **Local-first Storage:** User data stored on-device by default

#### 6.1.5 The Intent Classifier

AI parses raw input into three strict buckets:

| Bucket | Name | Examples | Action |
|--------|------|----------|--------|
| **A** | Directives (Actionable) | "Call tax guy," "Fix bug" | Candidate for schedule |
| **B** | Archive (Reference) | "Hex codes," "Movie list," "Login details" | Store as context, do NOT schedule |
| **C** | Venting (Emotional) | "I hate this project," "I'm so tired" | Do NOT schedule; adjust energy estimate |

#### 6.1.6 The Staging Area ("The Draft Board")

**Rule:** AI never writes directly to the visible calendar without permission.

**UI:** A "Shadow Layer" showing AI-suggested tasks
- **Swipe Right:** Confirm task to real calendar
- **Swipe Left:** Ignore/archive suggestion
- **Tap:** Edit before confirming

---

### 6.2 Feature Set 2: The Intelligence Layer ("The Pattern Brain")

**Goal:** Infer importance without asking users to tag everything.

#### 6.2.1 The Importance Signals (Ranking Algorithm)

| Signal | Description | Weight |
|--------|-------------|--------|
| **Linguistic** | Detects panic keywords ("ASAP," "!!!," "Must," "Owe") | High |
| **Echo** | Task appears in multiple notes/lists over time | Medium-High |
| **Gravity** | Task relates to an active "Big Project" | Medium |
| **Freshness** | Tasks written <1 hour ago get "Momentum Boost" | Medium |
| **Interest Potential** | AI estimates user interest level | High |
| **Energy Match** | Task requirements match current energy state | High |
| **Low-Hanging Fruit** | 5-minute tasks identified for warm-up filler | Contextual |

#### 6.2.2 The "Reality Check" Engine

**Time Blindness Buffer:**
- Apply "Pessimism Multiplier" (default 1.5x) to user time estimates
- Learn and adjust multiplier based on historical accuracy
- Display both estimated and buffered time

**The Impossible Plan Warning:**
- Trigger when user attempts unrealistic scheduling
- Example: User tries to schedule 6 hours of focus time
- Response: "Your data shows you hit a wall after 2 hours. Want to insert a 'Guilt-Free Break'?"

**Calendar Conflict Detection:**
- Identify overlapping commitments
- Flag back-to-back meetings without transition time
- Suggest realistic alternatives

#### 6.2.3 Pattern Recognition (Learning)

**Active Learning (Coach Mode):**
- When task is missed, gently ask: "What got in the way?"
- Options: Boring | Too Hard | Ran Out of Time | Forgot | Other
- Use responses to improve future suggestions

**Passive Learning (Silent Mode):**
- **Snooze Tracking:** If "Finance" is snoozed every Friday, stop suggesting it on Fridays
- **Ghost Detection:** If user opens app and closes immediately, assume "Overwhelm" and simplify next view
- **Completion Patterns:** Learn which task types complete at which times
- **Energy Rhythms:** Detect high/low energy periods from behavior

#### 6.2.4 Interest-Based Organization (Research-Backed Differentiator)

Rather than forcing importance-based prioritization:
- Tag tasks with estimated "interest potential"
- Surface high-interest tasks when energy is low (leverage interest to overcome inertia)
- Build novelty into routine tasks (suggest new approaches)
- Detect when tasks have become stale and suggest refreshing them

---

### 6.3 Feature Set 3: The Workflow ("The Contract")

**Goal:** Stabilize the day through constrained choice.

#### 6.3.1 The Daily Contract (Morning Ritual)

**The View:** Not a list, but a **Menu** of curated options.

**The Limit:**
- Maximum **3 "Anchor Tasks"** (Critical/Must-do)
- Maximum **2 "Side Quests"** (Easy/Optional)
- User cannot add more without removing something

**The Negotiation:**
- If user tries to add 4th Anchor: "You're at capacity. Which task should wait until tomorrow?"
- If task is vague: "What's the first tiny step for 'Work on project'?"

**Visual: The Stability Bar**
- Starts at 50% (baseline)
- Completing Anchor Tasks fills it toward 100%
- Reaching 100% = "Zen Mode" (day complete, rest encouraged)

#### 6.3.2 The Context Switcher (Notification Intelligence)

**Actionable Lock Screen Notifications:**
- **"I'm on it"** — Start task timer
- **"Too Tired"** — Reschedule to "Low Energy" slot
- **"Just 5 Mins"** — Micro-start commitment

**Smart Snooze Options:**
- "Snooze until I leave this location"
- "Snooze until after my next meeting"
- "Bump to Weekend"
- "Remind me when I'm less busy"

**Deep Work Protection:**
- Tasks marked "Deep Work" (Coding, Writing) scheduled in 2+ hour continuous blocks
- Never scheduled between meetings
- Soft notifications only during flow

**Energy-Aware Scheduling:**
- "Low Energy" tasks (Email, Admin) → Afternoon Slump (2-4 PM)
- "High Energy" tasks (Creative, Complex) → Morning Peak
- Learn individual energy patterns over time

#### 6.3.3 The Satisfaction Dashboard ("The Done List")

**The Receipt:**
- End-of-day summary showing achievements
- Include "Invisible Work" (e.g., "You handled 3 interruptions gracefully")
- Celebrate completion without judgment of what wasn't done

**The Consistency Heatmap:**
- GitHub-style contribution squares
- Shows days of engagement, not perfection
- **No "Broken Streaks"** — Just a visual history of showing up
- Missing days are neutral, not failures

---

### 6.4 Feature Set 4: Long-Term Goals ("The Vision")

**Goal:** Maintain "Object Permanence" for dreams without nagging.

#### 6.4.1 The XP System (Research-Backed Gamification)

**Distinguish Task Types:**
- **Survival Tasks** (Chores): Necessary but not growth-oriented
- **Growth Tasks** (Goals): Aligned with long-term aspirations

**XP Rewards:**
- Completing a growth task grants XP in that category
- Example: "Read 10 pages" → +10 Intellect XP
- XP accumulates toward skill levels

**Visual Representation:**
- "Skill Trees" or "RPG Bars" for long-term interests
- Categories: Intellect, Creativity, Wellness, Career, Relationships, etc.
- Opt-in only (not forced on users who dislike gamification)

**Anti-Streak Design:**
- No penalty for missing days
- XP only accumulates, never decreases
- Focus on total growth, not consistency

#### 6.4.2 Opportunistic Scheduling

**Rule:** Never lock long-term goals to fixed daily times.

**Mechanism:**
- AI monitors for "Light Days" or unexpected gaps
- Surfaces opportunity: "You have a free hour. Want to snag 20 XP in Spanish?"
- User can accept, snooze, or decline without penalty

**Interest-Based Suggestions:**
- Prioritize suggesting goals user has shown recent interest in
- Rotate suggestions to maintain novelty
- Respect user's current energy state

#### 6.4.3 The "Cold Storage" (Serendipity Engine)

**The Sunset Protocol:**
- If a goal is ignored 3 times, AI asks: "Archive this for now?"
- Archived goals move to "Someday" list (out of active rotation)
- No shame, just acknowledgment of current priorities

**The Revival:**
- Periodically (months later), during free moments
- AI surfaces archived goals: "Remember this idea? Want to revive it?"
- Maintains object permanence without active nagging

---

### 6.5 Feature Set 5: The Meltdown Protocol

**Goal:** Psychological safety during executive function collapse.

#### 6.5.1 The "Reset" Button

**UI:** Discrete "Overwhelmed?" button, always accessible (not hidden in menus).

**Actions on Trigger:**

1. **UI Transformation:**
   - Fade to dark/calm colors
   - Hide all XP, skill bars, and progress indicators
   - Minimize visual complexity

2. **The Purge:**
   - Move ALL non-critical tasks to hidden "Holding Pen"
   - Only show tasks with hard deadlines (today)
   - If no hard deadlines: Show nothing

3. **Triage Mode:**
   - If one critical task exists: Show only that task
   - Break it into smallest possible steps
   - Offer to reschedule if even that feels impossible

#### 6.5.2 "Goblin Mode"

**When Activated:** System detects severe overwhelm or user explicitly enters.

**The Menu:** Suggest only physiological fixes:
- "Drink Water" (+50 XP)
- "Stretch for 2 minutes" (+50 XP)
- "Eat a Snack" (+50 XP)
- "Take 5 deep breaths" (+30 XP)
- "Lie down for 10 minutes" (+100 XP)

**Reward Design:**
- High XP for basic self-care during meltdown
- Validates that survival IS productive
- Rebuilds emotional foundation before task re-engagement

#### 6.5.3 The "Bail Out" Generator

**Purpose:** Remove social anxiety from canceling/rescheduling commitments.

**UI:**
- One-tap excuse generation
- Input: "I can't make the meeting" or context from calendar

**Output:**
- AI drafts polite, professional message
- User reviews and sends (or copies to clipboard)
- Example: "Hi [Name], Something came up and I need to reschedule our meeting. Would [alternative time] work for you? Apologies for any inconvenience."

**Customization:**
- Tone options: Formal / Casual / Brief
- Include or exclude specific details
- Learn user's communication style over time

---

### 6.6 Feature Set 6: AI Companion ("The Co-Regulator")

**Research Basis:** AI-enabled body doubling supports task initiation AND emotional regulation.

#### 6.6.1 The Presence Layer

**Concept:** AI companion that "works alongside" the user without being intrusive.

**Manifestations:**
- Subtle animated presence indicator (not a chatbot face)
- Ambient awareness: "I'm here while you work"
- Available for interaction but doesn't demand it

#### 6.6.2 Micro-Coaching Moments

**Trigger:** User staring at task without starting (detected via app open time without action).

**Response Examples:**
- "What's the tiniest first step you could take?"
- "Sometimes starting is the hardest part. Want to just open the document?"
- "You've done this type of task before. You've got this."

**Tone:** Encouraging, not pushy. Opt-out available.

#### 6.6.3 Emotional Check-Ins

**Passive Detection:**
- App usage patterns suggest frustration (rapid switching, immediate closes)
- Task avoidance on specific items
- Energy estimation from Venting bucket inputs

**Explicit Check-In (Optional):**
- "How's your energy right now?" (Quick emoji selection)
- Adjust day's recommendations based on response

---

### 6.7 Feature Set 7: Integrations & Ecosystem

#### 6.7.1 Apple Ecosystem (MVP)

| Integration | Access Level | Purpose |
|-------------|--------------|---------|
| Apple Calendar | Read/Write | Import events, write confirmed tasks |
| Apple Reminders | Read | Import existing reminders |
| Apple Notes | Via Shortcut | Deep scan notes content |
| Apple Health | Read (Optional) | Sleep, activity data for energy modeling |
| Siri | Voice trigger | "Hey Siri, brain dump to Cove" |

#### 6.7.2 Future Integrations (Post-MVP)

| Integration | Purpose | Priority |
|-------------|---------|----------|
| Google Calendar | Cross-platform users | High |
| Notion | Reference material | Medium |
| Slack | Work context awareness | Medium |
| Spotify | Focus music integration | Low |
| Apple Watch | Wrist notifications, quick capture | High |

---

## 7. UI/UX Design System

### 7.1 Visual Identity

**Aesthetic:** "Cozy Sci-Fi" — Advanced technology, warm presentation

**Inspiration:**
- WALL-E (warmth in technology)
- Headspace (calm productivity)
- Arc Browser (modern, clean, playful)

### 7.2 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Deep Ocean Blue** | #1A365D | Primary background, calm base |
| **Soft Navy** | #2D3748 | Secondary surfaces |
| **Bioluminescent Teal** | #38B2AC | Actions, success states |
| **Warm Coral** | #F6AD55 | Gentle warnings (never red) |
| **Cloud White** | #F7FAFC | Text, highlights |
| **Muted Sage** | #68D391 | Completed states |

**Critical Rule:** No red anywhere in the app. Warnings use soft orange/coral.

### 7.3 Typography

**Primary Font:** SF Pro Rounded (iOS system, accessible, friendly)

| Style | Usage |
|-------|-------|
| Bold 24pt | Section headers |
| Semibold 18pt | Task titles |
| Regular 16pt | Body text |
| Regular 14pt | Secondary info |

### 7.4 Component Library

#### Cards
- Rounded corners (16px radius)
- Soft shadows
- Swipeable actions
- Haptic feedback on completion

#### Buttons
- Large touch targets (minimum 44pt)
- Primary: Filled with Teal
- Secondary: Outlined
- Destructive: Never red, use muted orange

#### Animations
- **Task Completion:** Scale up → flash → fade
- **Cloud Clearing:** Particle system that disperses
- **Transitions:** Smooth, 300ms default
- **Haptics:** Light tap on interaction, medium on completion

### 7.5 Accessibility

- VoiceOver full support
- Dynamic Type support
- Minimum contrast ratios (WCAG AA)
- Reduce Motion respects system setting
- Color-blind friendly palette

---

## 8. Technical Architecture

### 8.1 Technology Stack (iOS MVP)

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Frontend** | SwiftUI | Native iOS, modern declarative UI |
| **Data** | SwiftData | Local-first, privacy-respecting |
| **AI** | OpenAI GPT-4o-mini | Cost-effective, fast, good reasoning |
| **Voice** | OpenAI Whisper API | Best-in-class transcription |
| **Integrations** | EventKit | Apple Calendar/Reminders access |
| **Notifications** | UNUserNotificationCenter | Rich, actionable notifications |

### 8.2 AI Prompt Engineering

**System Prompt Core Traits:**
- Empathetic, non-judgmental
- Realistic about capabilities
- Brevity-focused (ADHD users lose interest in long responses)
- Strength-based framing

**Example System Prompt Excerpt:**
```
You are Cove, an executive function assistant for someone with ADHD.

Your core principles:
1. Never shame or judge. Missed tasks are information, not failures.
2. Be brief. Long explanations lose attention.
3. Assume the user is capable but struggling with initiation, not ability.
4. Protect energy. Suggest rest as often as productivity.
5. Celebrate small wins. Starting matters more than finishing.

When classifying input:
- Actionable tasks: Things that can be done
- Reference: Information to store, not schedule
- Venting: Emotional expression, acknowledge and move on
```

### 8.3 Data Model (Core Entities)

```swift
// Task
struct Task {
    let id: UUID
    var title: String
    var bucket: TaskBucket // .directive, .archive, .venting
    var status: TaskStatus // .draft, .scheduled, .completed, .archived
    var estimatedMinutes: Int?
    var bufferedMinutes: Int? // After pessimism multiplier
    var interestLevel: InterestLevel? // .high, .medium, .low
    var energyRequired: EnergyLevel? // .high, .medium, .low
    var scheduledDate: Date?
    var completedDate: Date?
    var snoozeCount: Int
    var relatedProjectId: UUID?
    var createdAt: Date
}

// DailyContract
struct DailyContract {
    let id: UUID
    let date: Date
    var anchorTasks: [Task] // Max 3
    var sideQuests: [Task] // Max 2
    var stabilityPercentage: Int // 50-100
    var isZenMode: Bool
}

// UserProfile
struct UserProfile {
    var pessimismMultiplier: Double // Default 1.5
    var energyPatterns: [EnergyPattern]
    var snoozePatterns: [SnoozePattern]
    var completionHistory: [CompletionRecord]
    var xpByCategory: [Category: Int]
}
```

### 8.4 Privacy Architecture

**Principles:**
1. **Local-First:** All user data stored on device
2. **Minimal Cloud:** Only AI processing sends data externally
3. **PII Redaction:** Sensitive patterns filtered before AI processing
4. **No Telemetry:** No behavioral tracking to external services
5. **Export/Delete:** User can export all data or delete account

**PII Detection Patterns:**
- Credit card numbers (regex)
- Social Security Numbers (regex)
- API keys (common patterns)
- Passwords (context clues: "password:", "pw:")
- Health keywords (medical terms, diagnoses)

### 8.5 Offline Capability

- Full task management works offline
- AI features require connectivity
- Sync on reconnection
- Clear offline indicators

---

## 9. Success Metrics

### 9.1 North Star Metric

**"Days Stabilized":** Percentage of days where user completes their Daily Contract (all 3 Anchor Tasks).

**Why This Metric:**
- Measures actual utility, not engagement
- Aligned with user goals (getting things done)
- Resistant to dark patterns

### 9.2 Key Performance Indicators (KPIs)

| Metric | Target (Month 3) | Target (Month 12) |
|--------|------------------|-------------------|
| Daily Active Users (DAU) | 1,000 | 25,000 |
| Days Stabilized Rate | 40% | 60% |
| 7-Day Retention | 35% | 50% |
| 30-Day Retention | 20% | 35% |
| Post-Meltdown Return Rate | 60% | 80% |
| Net Promoter Score (NPS) | +30 | +50 |

### 9.3 Anti-Metrics (What We Don't Optimize For)

| Anti-Metric | Why We Avoid It |
|-------------|-----------------|
| Time in App | We want users living life, not in the app |
| Tasks Created | Could encourage overwhelming overcommitment |
| Streak Length | Creates shame when broken |
| Daily Opens | Frequency isn't quality |

### 9.4 Qualitative Success Indicators

- Users describe feeling "less stressed" or "more in control"
- Spontaneous sharing/recommendation to friends with ADHD
- Users return after period of non-use without shame
- Community testimonials about specific features helping

---

## 10. Roadmap

### 10.1 Phase 1: The Contract (MVP) — Months 1-3

**Focus:** Prove the core "Subtraction" concept works.

**Features:**
- [ ] Voice and text capture
- [ ] Basic AI classification (3 buckets)
- [ ] The Staging Area (draft board)
- [ ] The Daily Contract (3+2 task limit)
- [ ] The Reality Check (time buffering)
- [ ] The Meltdown Button (basic reset)
- [ ] Apple Calendar read integration
- [ ] Basic notifications

**Success Criteria:**
- 500 beta users
- 30%+ 7-day retention
- Qualitative feedback: "This actually works for my brain"

### 10.2 Phase 2: The Eye — Months 4-6

**Focus:** Add intelligence and learning.

**Features:**
- [ ] Apple Reminders integration
- [ ] iOS Shortcut for Notes capture
- [ ] Pattern recognition (snooze, completion times)
- [ ] Interest-level tagging
- [ ] Energy-aware scheduling
- [ ] Actionable notifications (snooze options)
- [ ] Consistency heatmap (done list)

**Success Criteria:**
- 2,500 users
- 40%+ Days Stabilized rate
- Measurable improvement in task completion over time

### 10.3 Phase 3: The Soul — Months 7-9

**Focus:** Gamification and long-term goals.

**Features:**
- [ ] XP system (Growth vs. Survival tasks)
- [ ] Skill trees / category progress
- [ ] Opportunistic goal scheduling
- [ ] Cold Storage with revival
- [ ] Goblin Mode (full meltdown protocol)
- [ ] Bail-out message generator
- [ ] AI companion presence layer

**Success Criteria:**
- 10,000 users
- 70%+ post-meltdown return rate
- Strong NPS from long-term users

### 10.4 Phase 4: The Ecosystem — Months 10-12

**Focus:** Expansion and stickiness.

**Features:**
- [ ] Apple Watch app
- [ ] Google Calendar integration
- [ ] Apple Health integration (sleep/activity data)
- [ ] Advanced pattern learning
- [ ] Personalized AI coaching moments
- [ ] Shareable "My Day" summary (optional)

**Success Criteria:**
- 25,000 users
- Sustainable retention metrics
- Clear path to monetization

### 10.5 Future Considerations (V2+)

- Android version
- Web dashboard
- ADHD coach marketplace
- Group/family features
- Corporate/enterprise version
- Research partnerships

---

## 11. Appendix: Research Foundation

### 11.1 Key Research Findings Informing Design

#### Interest-Based Nervous System (Dodson, 2022)
ADHD brains require tasks to be **novel, urgent, challenging, or interesting** to initiate action. Importance alone doesn't trigger activation.

**Design Impact:** Interest-level tagging, novelty injection, urgency creation through gamification.

#### Emotional Dysregulation Predicts Impairment
Research confirms emotional dysregulation predicts greater functional impairment than ADHD symptoms alone (PLOS ONE, 2024).

**Design Impact:** Emotional state awareness, shame-resistant design, Meltdown Protocol.

#### Time Blindness is Measurable
Time perception impairments are a core, consistent feature of ADHD (Nature Scientific Reports, 2024).

**Design Impact:** Pessimism multiplier, visual time representation, buffer time enforcement.

#### Gamification Effectiveness (Mixed)
89% of children showed positive attitudes toward game interventions, but long-term efficacy unclear (Frontiers, 2025).

**Design Impact:** Optional gamification, anti-streak design, XP that never decreases.

#### Hyperfocus as Strength
Adults who recognize and leverage ADHD strengths report better quality of life (ScienceDaily, 2025).

**Design Impact:** Hyperfocus protection mode, celebrate deep work rather than interrupt it.

#### RSD and Shame
Single negative feedback can trigger hours of shame, anger, or sadness in ADHD individuals (Cleveland Clinic).

**Design Impact:** No red text, no "overdue," private by default, reframe failures as experiments.

#### Body Doubling Mechanisms
AI-enabled body doubling shows promise for supporting task initiation AND emotional regulation (ArXiv, 2024).

**Design Impact:** AI companion presence layer, non-intrusive "working alongside" indicator.

### 11.2 Research Gaps = Opportunities

| Gap | Opportunity for Cove |
|-----|---------------------|
| Long-term efficacy understudied | Build longitudinal tracking |
| Adult ADHD has fewer tools | Focus on 25-45 demographic |
| RSD-informed design nonexistent | First-mover advantage |
| Hyperfocus channeling underdeveloped | Protection-first approach |
| Emotional scaffolding rare | Core differentiator |

### 11.3 Sources

1. Journal of Medical Internet Research - Cognitive-Physical Intervention RCT (2024)
2. MDPI - Systematic Review of Executive Function Stimulation Methods (2024)
3. Frontiers - Digital Mental Health Intervention Development (2024)
4. ArXiv - Neurodivergent-Aware Productivity Framework (2024)
5. PLOS ONE - Emotional Dysfunction in Adult Women with ADHD (2024)
6. Nature Scientific Reports - tDCS Time Perception Study (2024)
7. Frontiers - Gamified Educational App RCT (2025)
8. Psychology Today - Interest-Based Nervous System (2024)
9. SagePub - Understanding Women with ADHD Qualitative Study (2025)
10. iScience - Neuromonitoring-Guided Working Memory Intervention (2024)
11. Cleveland Clinic - RSD Symptoms & Treatment
12. ACM TAC - Body Doubling Investigation with Neurodivergent Participants (2024)
13. ScienceDaily - ADHD Strengths and Mental Health (2025)
14. Nature Scientific Reports - Validation of Hyperfocus Questionnaire (2024)

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | January 2026 | [Your Name] | Initial comprehensive PRD |

---

*"Your brain isn't broken. It just needs a different operating system."*
