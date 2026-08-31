# SIH26003 — ASHA Module Spec (for Claude Code)

Build target: the ASHA-facing surface of the Flutter app. This is the **core delivery mechanism** of the whole product (novelty claim #2 — group CST on one shared tablet). Get this right before polish anywhere else.

## Who uses this and how
An ASHA worker runs scheduled **group** cognitive sessions for multiple registered elders at a community centre/PHC, on one shared rugged tablet. She is not a clinician and has no clinical training — the app is the co-therapist; she's the facilitator. She also does outreach home visits (same tablet, same flow, offline) for elders who can't travel.

## Structure — three panels (established design)
1. **Today's Sessions**
2. **My Patients**
3. **Sync**

### 1. Today's Sessions
- Shows sessions scheduled for today, both **group** and **solo/outreach** types.
- ASHA can start a session directly from here.
- A session has a `conducted_by: asha_session` field distinguishing ASHA-assisted sessions from a patient's independent solo play at home — this matters downstream for scoring/trend interpretation (assisted performance ≠ unassisted performance, don't conflate them in the baseline).
- Session creation/scheduling should support picking multiple patients for a group session, or a single patient for solo/outreach.

### 2. My Patients
- Sidebar-style patient roster assigned to this ASHA.
- Each patient entry should surface: name/photo (for the tile-picker style visual ID used elsewhere in the app), recent session history, any flagged trend (phrased as "deviation from baseline," never as diagnosis — see positioning doc), missed-session count.
- From here ASHA can view an individual patient's trend detail or add a new patient (onboarding capture — baseline session).

### 3. Sync
- Offline sync **outbox** — shows what's queued to sync (session logs, response records, new patient onboarding data) and drains when connectivity is available.
- Should visually communicate: queued / syncing / synced states. Nothing here should block app usage — this is a status view, not a gate.
- Demo behavior to support: airplane mode on, use the app fully, then reconnect and watch the queue drain to zero.

## In-session recording — three-way response marking
During a group or solo session, for **each patient, each round**, the ASHA (or the system, where auto-detectable) records one of:
- **Independent** — patient responded without help
- **Needed a hint** — hint was triggered/given
- **No response** — patient did not respond

This is the core telemetry that feeds the adaptive engine and baseline comparison. It needs to be quick to log for multiple patients in the same round on a shared tablet — this is a facilitation tool used in real time, not a form filled out afterward. Favor large tap targets, minimal steps per patient per round.

## Data model implications
- A `session` has: `id`, `type` (group | solo | outreach), `conducted_by` (asha_session | independent), `scheduled_time`, `patient_ids[]`, `status`.
- A `response_record` has: `session_id`, `patient_id`, `round_number`, `marking` (independent | hint | no_response), `timestamp`, `game_module`.
- All of the above must be writable to SQLite with zero connectivity and queued for sync — see tech stack doc.

## What NOT to build here
- Don't default the UI to one-patient-at-a-time — that's the outreach/solo case, not the norm.
- Don't surface AI output as a diagnostic statement — trends only, routed as "review this with [patient]," never "[patient] has dementia" or similar.
- Don't require typed login mid-session for anything patient-facing — ASHA authenticates once (JWT) to open her dashboard; the elder side stays photo-tile / voice-first.

## Open question to confirm with team before finalizing UI
CST session frequency/duration is still unverified against the actual clinical protocol — don't hardcode a specific number of sessions/week or minutes/session into scheduling logic until that's confirmed.
