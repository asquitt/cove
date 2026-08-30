# Cove Cohort Evidence Ledger

Candidate evidence is recorded here without upgrading unavailable proof to green.

| Property | State | Current evidence |
|---|---|---|
| Repository quality controls | Passed | `scripts/verify-agent-quality.sh` via the cohort static gate |
| Cohort target containment | Passed statically | `scripts/verify-cohort-static.sh` resolves PBX source phases and proves exactly ten cohort app sources |
| Test targets and scheme | Passed statically | Static gate proves `CoveTests` and `CoveUITests` target dependencies, source membership, and shared-scheme testables |
| Privacy manifest and permission removal | Passed statically | Plist/JSON checks prove an explicit manifest resource, empty privacy declarations, and no excluded purpose strings or APIs in compiled sources |
| Icon packaging | Passed statically | `sips` proves opaque PNG, 1024x1024; asset JSON and PBX resources are wired |
| Swift syntax | Passed with limitation | Every compiled app, unit-test, and UI-test source parses with the available Swift 5.2 parser; this is not modern API type checking |
| Static-gate failure behavior | Passed | Isolated copy with `CoveIcon.png` changed to `MissingIcon.png` exits 1 with `FAIL: app icon filename is not wired` |
| Secret scan | Passed | Gitleaks 8.30.1 reports no findings in reachable Git history or the working tree |
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
```

The exact commit and tree are recorded after the worktree is frozen and in the pull-request evidence. Static source readiness must not be restated as a build, Simulator, archive, TestFlight, or customer outcome.
