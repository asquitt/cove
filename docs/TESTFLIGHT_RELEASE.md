# TestFlight Release Contract

## Current Truth

The repository contains a bounded cohort target, app icon, privacy manifest, shared scheme, `CoveTests` unit-test target, and `CoveUITests` golden-journey target. That is source readiness, not distribution proof.

This host currently has no `Xcode.app`; its active developer directory is an incompatible legacy Command Line Tools installation. Therefore app compilation, XCTest execution, Simulator behavior, accessibility inspection, archive, signing, upload, App Store validation, and TestFlight review are unverified.

The Xcode project intentionally leaves `DEVELOPMENT_TEAM` empty. The owner must select the real team without committing a personal signing identity. The distinct bundle ID `com.demario.cove.cohort` intentionally isolates `Cove Study` from legacy `com.demario.Cove` data. Its separate App Store Connect record, next unused build number, agreements, tax/banking state, privacy URL, and tester groups are unverified.

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

1. Fresh launch shows consent and emits no study event before acceptance.
2. Text capture opens Review without a permission prompt or network dependency.
3. Force-quit after capture; relaunch shows Saved for review.
4. Do -> Anchor -> Complete persists across relaunch and counts one linked completion.
5. Exact 3 + 2 caps reject the sixth assignment visibly while preserving it in Waiting for a spot.
6. Keep retains local words; Let go erases them.
7. Week check-in stores once; week-four price language says stated intent, not purchase.
8. Shared report contains no canary task content.
9. Erase all returns to consent and leaves every model table empty.
10. VoiceOver, accessibility Dynamic Type, Reduce Motion, light/dark mode, and keyboard focus preserve the complete journey.

## Archive and Upload

After selecting the confirmed Apple team and App Store record:

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
