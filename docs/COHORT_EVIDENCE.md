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
| Swift compilation | Passed locally | Xcode 26.6 compiles the app, unit-test target, and UI-test target for iPhone 16 Pro / iOS 18.6 |
| Static-gate failure behavior | Passed | Four isolated mutations for icon wiring, generated microphone permission, privacy linkage, and bundle identity each exit nonzero with the expected fail-closed message |
| Secret scan | Passed | Gitleaks 8.30.1 reports no findings in reachable Git history or the working tree |
| Independent review history | Recorded | Exact review of `7ce186e23515603d11e9c2f24693cb5c53705cda` admitted deterministic-ordering, participant-isolation, legacy-store, permission-setting, framework-path, and privacy-truth findings; the pull request records their disposition and the corrected-head review result |
| XCTest execution | Passed locally | 21 domain/store tests and 3 XCUI journeys pass with zero failures; the final combined result bundle is recorded below |
| Simulator golden journey | Passed locally | Consent, Capture -> Review -> Confirm -> Complete -> Activated, local erasure, and disk-backed completion/activation across process relaunch pass on iPhone 16 Pro / iOS 18.6 |
| Release simulator render | Passed locally | Release build installs and launches as `Cove Study`; consent UI rendered without a permission prompt and the `CoveCohortV1.store` files exist in the app container |
| Accessibility behavior | Partial | XCUI resolves consent, capture, review, completion, activation, and erase controls through accessibility identifiers and labels; VoiceOver, accessibility Dynamic Type, Reduce Motion, contrast variants, and Switch Control remain manual gates |
| Device archive | Passed unsigned | Generic iOS Release archive contains arm64 `Cove.app`, bundle `com.demario.cove.cohort`, version `0.1 (1)`, iOS 18 minimum, icon assets, and `PrivacyInfo.xcprivacy`; binary scan found no sensitive-purpose, network, or third-party analytics strings |
| Signing/upload | Blocked | `security find-identity -v -p codesigning` reports zero valid identities; Apple team, App Store record, unused build number, signed export, upload, and App Store validation remain unverified |
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
xcodebuild -project Cove/Cove.xcodeproj -scheme Cove -configuration Debug \
  -destination 'platform=iOS Simulator,id=81407A06-0C87-46A2-A157-7A7C3B6FB44D' \
  -resultBundlePath /tmp/cove-final-candidate.xcresult CODE_SIGNING_ALLOWED=NO test
xcodebuild -project Cove/Cove.xcodeproj -scheme Cove -configuration Release \
  -destination 'platform=iOS Simulator,id=81407A06-0C87-46A2-A157-7A7C3B6FB44D' \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Cove/Cove.xcodeproj -scheme Cove -configuration Release \
  -destination 'generic/platform=iOS' -archivePath /tmp/CoveCohort.xcarchive \
  CODE_SIGNING_ALLOWED=NO archive
security find-identity -v -p codesigning
```

The local runtime evidence uses Xcode 26.6 (build 17F113) and iPhone 16 Pro / iOS 18.6. The generic-device archive is deliberately unsigned because this host has no valid code-signing identity. It is compilation and packaging proof, not a distributable TestFlight artifact.

The exact commit and tree are recorded after the worktree is frozen and in the pull-request evidence. Local build, XCTest, Simulator, and unsigned archive proof must not be restated as signing, upload, TestFlight installation, four-week retention, willingness to pay, or revenue.
