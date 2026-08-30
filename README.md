# Cove

Cove is a deliberately small iPhone field-study app for one question: does a text-first capture and protected **3 Anchor + 2 Side quest** plan help adults with ADHD choose and complete what matters each week?

This repository is in **consumer validation**, not production. The current cohort build does not use an account, backend, external AI, analytics SDK, microphone, Speech, Calendar, Reminders, HealthKit, Google, Obsidian, notifications, or a share extension.

## Cohort Journey

1. Read and accept versioned local study consent.
2. Capture one thought as text.
3. Review an on-device starting suggestion: **Do**, **Keep**, or **Let go**.
4. Put actionable work into one of today's three Anchor or two Side quest slots, or keep it waiting for a future day.
5. Complete the same linked task.
6. Submit one immutable closed-choice check-in per study week.
7. In week four only, answer whether Cove is worth the predeclared price of **$4.99/month**.
8. Explicitly share a content-free local report or erase all local data.

The app stores entries locally. The study report contains anonymous identifiers, event names, coarse elapsed hours, closed-choice responses, and outcome counts. It does not include captured text or task titles, and nothing uploads automatically.

## Product Boundary

Only the cohort app, `CoveTests`, and `CoveUITests` are target members. Older exploratory code remains in the repository for reference but is excluded from the build target. It must not be used to claim implemented integrations or release scope.

Compiled app sources:

- `CoveApp.swift`
- `ContentView.swift`
- `Cohort/CohortModels.swift`
- `Cohort/CohortDomain.swift`
- `Cohort/CohortStore.swift`
- `Cohort/CohortTheme.swift`
- `Cohort/StudyOnboardingView.swift`
- `Cohort/CohortRootView.swift`
- `Cohort/TodayView.swift`
- `Cohort/StudyView.swift`

## Verification

Run the repository-owned static gate:

```bash
scripts/verify-cohort-static.sh
```

An installed current Xcode is still required for compilation, XCTest, Simulator, accessibility, archive, signing, upload, and TestFlight proof. See:

- `docs/COHORT_PROTOCOL.md`
- `docs/PRIVACY.md`
- `docs/TESTFLIGHT_RELEASE.md`
- `docs/COHORT_EVIDENCE.md`

## Decision Gate

Treat a ten-person cohort as directional evidence only. Continue investment only if:

- At least `6/10` qualified participants complete the linked journey in every one of the four study weeks.
- At least `2/10` explicitly say yes to Cove at `$4.99/month` in the week-four offer.
- Data-loss, privacy, or misleading-evidence incidents remain zero.

TestFlight StoreKit transactions are sandbox transactions and do not prove that a tester paid. This build measures stated willingness to pay, not revenue.
