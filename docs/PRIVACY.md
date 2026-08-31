# Cove Cohort Privacy Contract

## Product Boundary

The cohort target has no automatic network collection. It contains no network client, analytics SDK, external AI provider, account system, advertising identifier, Speech, microphone, Calendar, Reminders, HealthKit, Google, Obsidian, notification, App Intent, or share-extension source.

The legacy exploratory files for those capabilities remain outside target membership and are not product claims.

## Local Data

SwiftData stores:

- Random participant ID, consent version, enrollment timestamp, and fixed price offer
- Captured entry text and editable task title
- Local sorting decision, estimate, plan role, local day key, and completion state
- Content-free study events
- One closed-choice response per study week

The app does not configure CloudKit or an App Group. It uses the dedicated `com.demario.cove.cohort` bundle and `CoveCohortV1` store, so it cannot replace or claim to erase data from the legacy `com.demario.Cove` app. Normal device backup behavior has not been independently verified and must be disclosed in final App Store privacy materials if applicable.

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

Export excludes entries and task titles by construction and regression test. Nothing uploads automatically. The report is pseudonymous, not anonymous: its participant ID is stable across exports, and an identifiable delivery channel can link the report to its sender.

The study owner may use shared user-ID and product-interaction data only for cohort analytics. Shared reports are retained for no more than 90 days after the cohort closes, then deleted. A participant can request earlier deletion through the channel used for enrollment. Local deletion cannot recall a previously shared copy by itself.

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

`PrivacyInfo.xcprivacy` declares linked User ID and Product Interaction data for Analytics because explicit report sharing is part of the field-study workflow. It declares no tracking, tracking domains, or required-reason API. App Store Connect must make the same conservative declarations. The privacy-policy URL, generated privacy report, delivery-channel controls, retention operation, and archive contents remain external release checks.
