# Cove Four-Week Cohort Protocol

Protocol: `cove_tf_4w_v1`
Consent: `cove-study-v1`
Price tested: `$4.99 USD per month`
Status: preregistered directional validation plan

## Decision

Cove earns another investment cycle only if a bounded cohort establishes both repeated use and stated willingness to pay. Engineering activity, app opens, captures without completion, XP, screenshots, sandbox purchases, and tester praise do not satisfy this gate.

## Cohort

- Recruit 10 adults who self-identify as having ADHD or material executive-function difficulty.
- Exclude the owner, developers, automated sessions, simulator data, seeded fixtures, and prior product testers from the primary cohort.
- Record consent before any study event.
- Keep every enrolled participant in the denominator, including uninstallers, inactive participants, and people who do not export a report.
- Treat the result as directional, not statistically decision-grade.

## Fixed Windows

- Week 1: elapsed hours `0...167`
- Week 2: elapsed hours `168...335`
- Week 3: elapsed hours `336...503`
- Week 4: elapsed hours `504...671`
- Ask the price question only in week 4 so it does not influence earlier retention.

Timezone changes do not move the fixed seven-day windows because study week derives from elapsed time since enrollment. Daily 3 + 2 capacity uses the device's local calendar day.

## Canonical Journey

One subject identifier must carry this exact persisted lineage:

```text
capture_submitted
-> classification_resolved
-> capture_decided(doNext)
-> task_assigned(anchor | sideQuest)
-> task_completed
```

Only a `task_completed` event with that full subject lineage counts as activation or weekly use. Keep and Let go decisions are product-use evidence but do not count as task completion.

## Event Contract

Every study event stores:

- Random event ID
- Random participant ID
- Closed event name
- Local occurrence timestamp
- App version and build
- Schema version
- Optional random subject ID
- Derived study week
- Closed outcome value

Allowed events:

| Event | Outcome |
|---|---|
| `study_enrolled` | consent version |
| `capture_submitted` | `text_local` |
| `classification_resolved` | `doNext`, `keep`, or `release` |
| `capture_decided` | `doNext`, `keep`, or `release` |
| `task_assigned` | `anchor` or `sideQuest` |
| `task_completed` | `anchor` or `sideQuest` |
| `weekly_feedback_submitted` | `feedback_recorded`, `stated_yes`, or `stated_no` |

The exported report replaces exact timestamps with integer elapsed hours. It never contains entry text, task title, task description, voice, provider output, health data, calendar data, display name, email, device ID, Apple ID, IP address, API key, or free-form survey text.

## Metrics

### Activation

A participant activates after the first complete linked journey. Completing an unlinked or manually seeded item does not count.

### Weekly Retention

A participant qualifies for a week only after at least one complete linked journey in that fixed week. The primary retention outcome requires qualifying use in all four weeks.

```text
four_week_retention = participants qualifying in weeks 1, 2, 3, and 4 / 10 enrolled
```

### Payment Intent

The week-four check-in presents one exact offer: Cove at `$4.99 USD per month`. A yes answer is **stated willingness to pay**. It is not a purchase, charge, or revenue artifact.

### Go Gate

- `>= 6/10` retained in all four weeks
- `>= 2/10` stated yes at the displayed price in week 4
- `0` data-loss, content-export, misleading-evidence, or consent incidents

If fewer than 8 participants provide structurally valid reports, classify the cohort as inconclusive even if the point thresholds pass.

## Study Operation

1. Give each qualified participant the same reviewed TestFlight build.
2. Record enrollment separately without mapping personal identity into the app report.
3. Do not coach individual task choices after onboarding.
4. Ask for the local report only after the four-week window or withdrawal.
5. Validate report schema and event lineage before calculating outcomes.
6. Count missing reports as missing outcomes, not exclusions.
7. Record incidents and build changes. Do not mix materially different builds without a separate stratum.

## Adversarial Acceptance

- No consent produces zero study events.
- Killing the app after capture leaves the thought in Saved for review.
- Three Anchors and two Side quests are accepted; a sixth assignment is rejected without losing the item, which remains waiting for a future spot.
- Repeated completion produces one completion event.
- A failed save produces no success claim.
- Let go erases the stored words before success is shown.
- Canary content in entries never appears in exported JSON.
- An unlinked completion does not activate or retain a participant.
- A weekly response cannot be overwritten by a later response.
- Willingness to pay cannot be recorded before week 4.
- Erase all local data removes entries, consent, check-ins, and events.
