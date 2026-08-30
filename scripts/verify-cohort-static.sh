#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/Cove/Cove.xcodeproj/project.pbxproj"
SCHEME="$ROOT/Cove/Cove.xcodeproj/xcshareddata/xcschemes/Cove.xcscheme"
INFO="$ROOT/Cove/Cove/Info.plist"
PRIVACY="$ROOT/Cove/Cove/PrivacyInfo.xcprivacy"
ICON_JSON="$ROOT/Cove/Cove/Assets.xcassets/AppIcon.appiconset/Contents.json"
ICON="$ROOT/Cove/Cove/Assets.xcassets/AppIcon.appiconset/CoveIcon.png"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

for command in plutil jq xmllint sips rg; do
  command -v "$command" >/dev/null || fail "missing required command: $command"
done

plutil -lint "$PROJECT" >/dev/null
plutil -lint "$INFO" >/dev/null
plutil -lint "$PRIVACY" >/dev/null
xmllint --noout "$SCHEME"
jq -e . "$ICON_JSON" >/dev/null

project_json="$(plutil -convert json -o - "$PROJECT")"
app_id="$(jq -r '.objects | to_entries[] | select(.value.isa == "PBXNativeTarget" and .value.name == "Cove") | .key' <<<"$project_json")"
tests_id="$(jq -r '.objects | to_entries[] | select(.value.isa == "PBXNativeTarget" and .value.name == "CoveTests") | .key' <<<"$project_json")"
ui_tests_id="$(jq -r '.objects | to_entries[] | select(.value.isa == "PBXNativeTarget" and .value.name == "CoveUITests") | .key' <<<"$project_json")"
[[ -n "$app_id" && -n "$tests_id" && -n "$ui_tests_id" ]] || fail "expected Cove, CoveTests, and CoveUITests targets"

jq -e --arg app "$app_id" '
  .objects as $objects
  | $objects[$app].buildConfigurationList as $list
  | [$objects[$list].buildConfigurations[] | $objects[.].buildSettings] as $settings
  | ($settings | length) == 2
  and all($settings[];
    .PRODUCT_BUNDLE_IDENTIFIER == "com.demario.cove.cohort"
    and .INFOPLIST_KEY_CFBundleDisplayName == "Cove Study"
    and (has("INFOPLIST_KEY_NSMicrophoneUsageDescription") | not)
    and (has("INFOPLIST_KEY_NSSpeechRecognitionUsageDescription") | not)
    and (has("INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription") | not)
    and (has("INFOPLIST_KEY_NSRemindersFullAccessUsageDescription") | not)
    and (has("INFOPLIST_KEY_NSHealthShareUsageDescription") | not)
  )
' <<<"$project_json" >/dev/null || fail "app build settings violate cohort identity or permission contract"

target_names="$(jq -r '.objects | to_entries[] | select(.value.isa == "PBXNativeTarget") | .value.name' <<<"$project_json" | sort)"
[[ "$target_names" == $'Cove\nCoveTests\nCoveUITests' ]] || fail "unexpected target set: $target_names"

target_bundle_ids() {
  local target_id="$1"
  jq -r --arg target "$target_id" '
    .objects as $objects
    | $objects[$target].buildConfigurationList as $list
    | $objects[$list].buildConfigurations[]
    | $objects[.].buildSettings.PRODUCT_BUNDLE_IDENTIFIER
  ' <<<"$project_json" | sort -u
}

[[ "$(target_bundle_ids "$tests_id")" == "com.demario.cove.cohort.tests" ]] || fail "unexpected CoveTests bundle identity"
[[ "$(target_bundle_ids "$ui_tests_id")" == "com.demario.cove.cohort.uitests" ]] || fail "unexpected CoveUITests bundle identity"

framework_file_count() {
  local target_id="$1"
  jq -r --arg target "$target_id" '
    .objects as $objects
    | [
        $objects[$target].buildPhases[]
        | select($objects[.].isa == "PBXFrameworksBuildPhase")
        | $objects[.].files[]?
      ]
    | length
  ' <<<"$project_json"
}

[[ "$(framework_file_count "$tests_id")" == "0" ]] || fail "CoveTests has unexpected explicit framework links"
[[ "$(framework_file_count "$ui_tests_id")" == "0" ]] || fail "CoveUITests has unexpected explicit framework links"

source_names() {
  local target_id="$1"
  jq -r --arg target "$target_id" '
    .objects as $objects
    | ($objects[$target].buildPhases[] | select($objects[.].isa == "PBXSourcesBuildPhase")) as $phase
    | $objects[$phase].files[]
    | $objects[$objects[.].fileRef].path
  ' <<<"$project_json" | sort
}

resource_names() {
  local target_id="$1"
  jq -r --arg target "$target_id" '
    .objects as $objects
    | ($objects[$target].buildPhases[] | select($objects[.].isa == "PBXResourcesBuildPhase")) as $phase
    | $objects[$phase].files[]
    | $objects[$objects[.].fileRef].path
  ' <<<"$project_json" | sort
}

expected_app_sources=$'CohortDomain.swift\nCohortModels.swift\nCohortRootView.swift\nCohortStore.swift\nCohortTheme.swift\nContentView.swift\nCoveApp.swift\nStudyOnboardingView.swift\nStudyView.swift\nTodayView.swift'
actual_app_sources="$(source_names "$app_id")"
[[ "$actual_app_sources" == "$expected_app_sources" ]] || fail "unexpected app source membership: $actual_app_sources"

expected_test_sources=$'CohortDomainTests.swift\nCohortStoreTests.swift'
actual_test_sources="$(source_names "$tests_id")"
[[ "$actual_test_sources" == "$expected_test_sources" ]] || fail "unexpected test source membership: $actual_test_sources"

actual_ui_test_sources="$(source_names "$ui_tests_id")"
[[ "$actual_ui_test_sources" == "CoveGoldenJourneyUITests.swift" ]] || fail "unexpected UI test source membership: $actual_ui_test_sources"

actual_resources="$(resource_names "$app_id")"
[[ "$actual_resources" == $'Assets.xcassets\nPrivacyInfo.xcprivacy' ]] || fail "unexpected app resources: $actual_resources"

jq -e --arg tests "$tests_id" --arg app "$app_id" '
  .objects as $objects
  | any($objects[$tests].dependencies[]; $objects[.].target == $app)
' <<<"$project_json" >/dev/null || fail "CoveTests does not depend on Cove"

jq -e --arg tests "$ui_tests_id" --arg app "$app_id" '
  .objects as $objects
  | any($objects[$tests].dependencies[]; $objects[.].target == $app)
' <<<"$project_json" >/dev/null || fail "CoveUITests does not depend on Cove"

rg -q 'BlueprintName = "CoveTests"' "$SCHEME" || fail "CoveTests is missing from shared scheme"
rg -q 'BlueprintName = "CoveUITests"' "$SCHEME" || fail "CoveUITests is missing from shared scheme"
rg -q 'buildForTesting = "YES"' "$SCHEME" || fail "shared scheme does not build tests"
rg -q 'lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy' "$PROJECT" || fail "privacy manifest PBX type is not explicit"

privacy_json="$(plutil -convert json -o - "$PRIVACY")"
jq -e '
  .NSPrivacyTracking == false
  and (.NSPrivacyTrackingDomains | length) == 0
  and ([.NSPrivacyCollectedDataTypes[].NSPrivacyCollectedDataType] | sort) == [
    "NSPrivacyCollectedDataTypeProductInteraction",
    "NSPrivacyCollectedDataTypeUserID"
  ]
  and all(.NSPrivacyCollectedDataTypes[];
    .NSPrivacyCollectedDataTypeLinked == true
    and .NSPrivacyCollectedDataTypeTracking == false
    and .NSPrivacyCollectedDataTypePurposes == ["NSPrivacyCollectedDataTypePurposeAnalytics"]
  )
  and (.NSPrivacyAccessedAPITypes | length) == 0
' <<<"$privacy_json" >/dev/null || fail "privacy manifest violates pseudonymous cohort contract"

info_json="$(plutil -convert json -o - "$INFO")"
jq -e '
  (has("NSMicrophoneUsageDescription") | not)
  and (has("NSSpeechRecognitionUsageDescription") | not)
  and (has("NSCalendarsFullAccessUsageDescription") | not)
  and (has("NSRemindersFullAccessUsageDescription") | not)
  and (has("NSHealthShareUsageDescription") | not)
' <<<"$info_json" >/dev/null || fail "cohort Info.plist contains an excluded permission purpose string"

if rg -n 'DEVELOPER_DIR|iPhoneOS[0-9.]+\.sdk|INFOPLIST_KEY_NS(Microphone|SpeechRecognition|Calendars|Reminders|Health).*UsageDescription' "$PROJECT"; then
  fail "Xcode project contains a pinned SDK path or excluded generated permission string"
fi

[[ "$(jq -r '.images[0].filename' "$ICON_JSON")" == "CoveIcon.png" ]] || fail "app icon filename is not wired"
[[ -f "$ICON" ]] || fail "app icon file is missing"
icon_width="$(sips -g pixelWidth "$ICON" | awk '/pixelWidth/ {print $2}')"
icon_height="$(sips -g pixelHeight "$ICON" | awk '/pixelHeight/ {print $2}')"
icon_alpha="$(sips -g hasAlpha "$ICON" | awk '/hasAlpha/ {print $2}')"
[[ "$icon_width" == "1024" && "$icon_height" == "1024" && "$icon_alpha" == "no" ]] || fail "app icon must be opaque 1024x1024"

compiled_sources=(
  "$ROOT/Cove/Cove/CoveApp.swift"
  "$ROOT/Cove/Cove/ContentView.swift"
  "$ROOT"/Cove/Cove/Cohort/*.swift
)
if rg -n 'URLSession|@AppStorage|UserDefaults|import (EventKit|Speech|HealthKit|StoreKit)|api\.anthropic\.com|googleapis\.com' "${compiled_sources[@]}"; then
  fail "compiled cohort sources contain an excluded integration or required-reason API"
fi

rg -q '"CoveCohortV1"' "$ROOT/Cove/Cove/CoveApp.swift" || fail "cohort SwiftData store is not isolated"
rg -q 'var participantID: UUID' "$ROOT/Cove/Cove/Cohort/CohortModels.swift" || fail "focus items are not participant-owned"

rg -q 'XCTAssertFalse\(encoded\.contains\(secret\)\)' "$ROOT/Cove/CoveTests/CohortStoreTests.swift" || fail "content-exclusion regression test is missing"
rg -q 'XCTAssertFalse\(encoded\.contains\("generatedAt"\)\)' "$ROOT/Cove/CoveTests/CohortStoreTests.swift" || fail "exact report-time exclusion regression test is missing"
rg -q 'XCTAssertFalse\(try CohortStore\.complete' "$ROOT/Cove/CoveTests/CohortStoreTests.swift" || fail "idempotent-completion regression test is missing"
rg -q 'testStoreJourneyWithIdenticalTimestampsProducesCanonicalActivation' "$ROOT/Cove/CoveTests/CohortStoreTests.swift" || fail "same-time lineage regression test is missing"
rg -q 'testCrossParticipantMutationIsRejectedAndCapacityIsScoped' "$ROOT/Cove/CoveTests/CohortStoreTests.swift" || fail "participant-isolation regression test is missing"
rg -q 'testCaptureRejectsParticipantWithoutPersistedCurrentConsent' "$ROOT/Cove/CoveTests/CohortStoreTests.swift" || fail "consent-boundary regression test is missing"

parser=(arch -x86_64 /usr/bin/swiftc)
"${parser[@]}" --version >/dev/null 2>&1 || fail "available Swift parser is not executable"
for source in "${compiled_sources[@]}" "$ROOT"/Cove/CoveTests/*.swift "$ROOT"/Cove/CoveUITests/*.swift; do
  "${parser[@]}" -parse "$source"
done

"$ROOT/scripts/verify-agent-quality.sh" >/dev/null

printf 'PASS: Cove cohort static release contract\n'
printf 'INFO: Xcode build, XCTest execution, Simulator, archive, signing, upload, and cohort outcomes remain separate evidence.\n'
