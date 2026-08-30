# Cove Cohort Evidence Ledger

Candidate evidence is recorded here without upgrading unavailable proof to green.

| Property | State | Current evidence |
|---|---|---|
| Repository quality controls | Passed | `scripts/verify-agent-quality.sh` via the cohort static gate |
| Cohort target containment | Passed statically | `scripts/verify-cohort-static.sh` resolves PBX source phases and proves exactly ten cohort app sources |
| Test targets and scheme | Passed statically | Static gate proves `CoveTests` and `CoveUITests` target dependencies, source membership, and shared-scheme testables |
| Privacy manifest and permission removal | Passed statically | Plist/JSON checks prove linked User ID and Product Interaction analytics declarations, no tracking, and no excluded permission purpose strings or APIs in app build settings or compiled sources |
| Participant isolation | Passed statically | Every `FocusItem` has an owner; store mutations require persisted current consent and matching ownership; UI queries and 3 + 2 capacity are participant-scoped |
| Legacy app isolation | Passed statically | App build settings require bundle `com.demario.cove.cohort`, display name `Cove Study`, and store `CoveCohortV1`; legacy `com.demario.Cove` data is outside this app's container |
| Icon packaging | Passed statically | `sips` proves opaque PNG, 1024x1024; asset JSON and PBX resources are wired |
| Swift syntax | Passed with limitation | Every compiled app, unit-test, and UI-test source parses with the available Swift 5.2 parser; this is not modern API type checking |
| Static-gate failure behavior | Passed | Four isolated mutations for icon wiring, generated microphone permission, privacy linkage, and bundle identity each exit nonzero with the expected fail-closed message |
| Secret scan | Passed | Gitleaks 8.30.1 reports no findings in reachable Git history or the working tree |
| Independent review history | Recorded | Exact review of `7ce186e23515603d11e9c2f24693cb5c53705cda` admitted deterministic-ordering, participant-isolation, legacy-store, permission-setting, framework-path, and privacy-truth findings; the pull request records their disposition and the corrected-head review result |
| Xcode compilation | Unverified | No `Xcode.app` on this host |
| XCTest execution | Unverified | No iOS SDK/Xcode runtime on this host |
| Simulator golden journey | Unverified | No Simulator runtime on this host |
| Accessibility behavior | Unverified | Static semantics only; no Accessibility Inspector or runtime proof |
| Archive/signing/upload | Blocked | Apple team, App Store record, build number, archive, and upload unverified |
| TestFlight installation | Unverified | No uploaded or installed beta build observed |
| Four-week cohort outcome | Not started | No participants or reports |
| Real willingness to pay | Not established | Week-four stated-intent contract only; no real charge |

Commands run from the cohort worktree:

```text
scripts/verify-cohort-static.sh
bash -n scripts/verify-cohort-static.sh
git diff --check
gitleaks git . --no-banner --redact --log-level warn
gitleaks dir . --no-banner --redact --log-level warn
xcodebuild -project Cove/Cove.xcodeproj -scheme Cove -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

The `xcodebuild` attempt exits 1 before project evaluation because the active developer directory is Command Line Tools rather than a full Xcode installation. This is environment-blocked evidence, not an app test failure or a passing build.

The exact commit and tree are recorded after the worktree is frozen and in the pull-request evidence. Static source readiness must not be restated as a build, Simulator, archive, TestFlight, or customer outcome.
