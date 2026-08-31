# SIH26003 — Caregiver Module Spec (for Claude Code)

Build target: the caregiver-facing surface of the Flutter app. This is the "**memory assistance**" half of the product (as distinct from the cognitive games) — don't let it end up as an afterthought screen, it's named explicitly in the problem statement.

## Who uses this and how
Usually a family member, often physically distant (out-migration is one of the core NER problems this app addresses — "the child in Bengaluru or Dubai"). Interacts asynchronously, not in real time alongside the elder. Where no family is available, the **ASHA is the fallback caregiver-of-record** — the caregiver module's data model should accommodate an ASHA acting in this role, not assume every patient has a family caregiver.

## Core loop this module must support (reminders/adherence)
`Caregiver creates reminder (what / when) → audio-visual notification plays in a family member's recorded voice → elder acknowledges (taps the caregiver's photo) → status logged → adherence visible on caregiver dashboard.`

Covers four categories, all should be reminder types: **medicines, hydration, daily activities, medical appointments.**

### Recorded-voice requirement (novelty claim #6 — build this properly, it's a headline feature)
- When creating or editing a reminder, the caregiver can record a short voice clip (~15 sec) instead of relying on default TTS.
- Clip is tied to that caregiver's profile/photo and reused across reminders where possible (record once, reuse).
- This is also the fallback for languages where TTS/Bhashini has no model — recorded voice makes the feature work regardless of language tooling.
- Playback happens on the elder's device fully offline once synced down.

## Dashboard content — role-based, decision-support not just charts
Every metric shown should have an action attached, not just be a number:
- **Sessions** — attendance, engagement level → if missed, this should be visible enough to prompt caregiver to check in or flag to ASHA.
- **Reminders/adherence** — ack rate per reminder type → falling adherence should surface as something actionable, not just a graph.
- **Alerts** — trend flags from the AI engine, phrased as deviation-from-baseline (see positioning doc — never diagnostic language here).
- **Async weekly digest** — since the caregiver may check in only occasionally, a digest view (not just a live feed) matters as much as real-time data. This is explicitly designed to work for someone checking in once a week from another city/country.

## Data model implications
- A `reminder` has: `id`, `patient_id`, `created_by` (caregiver_id or asha_id), `type` (medicine | hydration | activity | appointment), `schedule`, `voice_clip_url` (nullable — falls back to TTS), `text_label`.
- A `reminder_ack` has: `reminder_id`, `patient_id`, `timestamp`, `status` (acknowledged | missed).
- `caregiver` records need a flag/field distinguishing family caregiver vs ASHA-as-fallback-caregiver, since permissions and dashboard framing may differ slightly (ASHA already has her own module — decide whether she gets a merged view or switches context).

## What NOT to build here
- Don't assume every patient has an active family caregiver — always design with the ASHA-fallback case in mind.
- Don't make this real-time/synchronous by default — the async digest is a deliberate design choice for distant caregivers, not a limitation to work around.
- Don't surface trend alerts as diagnostic — same rule as the ASHA module, see positioning doc's never-say/say-instead table.
- Don't hardcode reminder categories beyond the four PS-named ones (medicine, hydration, activity, appointment) without checking with the team — these map directly to a PS clause.
