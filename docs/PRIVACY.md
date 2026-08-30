# Cove Cohort Privacy Contract

## Product Boundary

The cohort target is local-only. It contains no network client, analytics SDK, external AI provider, account system, advertising identifier, Speech, microphone, Calendar, Reminders, HealthKit, Google, Obsidian, notification, App Intent, or share-extension source.

The legacy exploratory files for those capabilities remain outside target membership and are not product claims.

## Local Data

SwiftData stores:

- Random participant ID, consent version, enrollment timestamp, and fixed price offer
- Captured entry text and editable task title
- Local sorting decision, estimate, plan role, local day key, and completion state
- Content-free study events
- One closed-choice response per study week

The app does not configure CloudKit or an App Group. Normal device backup behavior has not been independently verified and must be disclosed in final App Store privacy materials if applicable.

## Export

Export is an explicit iOS share action. The JSON report contains:

- Protocol and schema identity
- Random participant and event IDs
- Event names and closed outcomes
- Coarsened elapsed hours and study weeks
- App build identity
- Closed-choice ratings and friction category
- Week-four stated willingness to pay
- Derived activation and four-week-use state

Export excludes entries and task titles by construction and regression test. Nothing uploads automatically. Once a participant shares a report, the recipient controls that copy; local deletion cannot recall it.

## Let Go

Choosing Let go clears both stored text and title before the decision is saved. A content-free decision event remains so the interaction can be counted without retaining the words.

## Withdrawal and Deletion

Erase all local data deletes:

- Participant and consent record
- Every entry and task
- Every weekly check-in
- Every study event

The app then returns to onboarding. Deletion is reported as complete only after `ModelContext.save()` succeeds. No local tracking tombstone is intentionally retained.

## Apple Declarations

`PrivacyInfo.xcprivacy` declares no tracking, collected-data type, tracking domain, or required-reason API because the compiled cohort source uses none of those APIs and performs no collection off device. App Store Connect privacy answers, privacy-policy URL, generated privacy report, and archive contents remain external release checks.
