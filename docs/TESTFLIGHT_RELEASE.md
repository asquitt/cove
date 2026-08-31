# TestFlight Release Contract

## Current Truth

The repository contains a bounded cohort target, app icon, privacy manifest, shared scheme, `CoveTests` unit-test target, and `CoveUITests` golden-journey target. Xcode 26.6 locally compiles the app, 21 unit tests, and 3 UI journeys. The UI suite proves activation and erasure in an in-memory store plus completed-task and activation persistence across a process relaunch in the normal disk-backed store.

The Release simulator build installs and renders on iPhone 16 Pro / iOS 18.6. An unsigned generic-iOS archive also succeeds and contains the expected bundle identity, icon, privacy manifest, and arm64 binary. These are local build and runtime proofs, not distribution proof.

This host has zero valid code-signing identities and the Xcode project intentionally leaves `DEVELOPMENT_TEAM` empty. The owner must select the real team without committing a personal signing identity. The distinct bundle ID `com.demario.cove.cohort` intentionally isolates `Cove Study` from legacy `com.demario.Cove` data. Its separate App Store Connect record, next unused build number, agreements, tax/banking state, privacy URL, tester groups, upload, and beta review are unverified.

## Local Gates

Run first:

```bash
scripts/verify-cohort-static.sh
```

With a current Xcode installed:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Cove/Cove.xcodeproj -list
xcodebuild -project Cove/Cove.xcodeproj \
  -scheme Cove \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test
xcodebuild -project Cove/Cove.xcodeproj \
  -scheme Cove \
  -configuration Release \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Required Simulator proof:

1. Verified: fresh launch shows consent; unit coverage proves a fresh store has no consent or study events.
2. Verified: text capture opens Review without a permission prompt or network dependency.
3. Verified: Do -> Anchor -> Complete persists across process relaunch and remains activated.
4. Verified: Erase all returns to consent; unit coverage proves every model table is empty.
5. Covered in unit tests, manual runtime gate remains: exact 3 + 2 cap behavior and Waiting for a spot presentation.
6. Covered in unit tests, manual runtime gate remains: Keep retention and immediate Let go text erasure.
7. Covered in unit tests, manual runtime gate remains: weekly check-in presentation and week-four stated-intent language.
8. Covered in unit tests, manual runtime gate remains: exported report inspection with canary task content.
9. Manual gate remains: VoiceOver, accessibility Dynamic Type, Reduce Motion, light/dark mode, Switch Control, and keyboard-only focus.

## Archive and Upload

The unsigned archive command below passes locally. After selecting the confirmed Apple team and App Store record, remove `CODE_SIGNING_ALLOWED=NO` and create a signed archive:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Cove/Cove.xcodeproj \
  -scheme Cove \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$PWD/build/Cove.xcarchive" \
  archive
```

Before upload, inspect the archive for:

- Exact commit and build identity
- `Cove.app/PrivacyInfo.xcprivacy`
- Correct 1024x1024 icon
- No unexpected entitlements, extensions, privacy-sensitive frameworks, or permission strings
- Correct bundle ID, team, marketing version, and unused build number

Do not describe Cove as on TestFlight until App Store Connect shows the exact uploaded build. External testing requires Apple beta review for the first build of a version. TestFlight builds expire after 90 days. Apple documents up to 100 internal testers and 10,000 external testers: [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview), [external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers).

TestFlight in-app purchases run in Apple's sandbox and do not charge testers, so they cannot prove willingness to pay or revenue: [Apple StoreKit sandbox testing](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox).

Privacy-manifest and required-reason declarations must match the archive, not merely the source tree: [Apple privacy manifest guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
