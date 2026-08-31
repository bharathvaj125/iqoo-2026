# Smriti frontend (Flutter)

One app, three role-scoped modules: **ASHA**, **Caregiver**, and **Patient**. A dev-only
role picker (`lib/main.dart`) opens straight into any of the three without a real login
flow — swap that for real auth (JWT for ASHA/caregiver, photo-tile for the patient) once
each is wired to the backend.

## Setup

```bash
cd frontend
flutter create .        # generates android/ ios/ etc. in place, keeps lib/ and pubspec.yaml as-is
flutter pub get
flutter run
```

`web/` is already generated and committed, so `flutter run -d chrome` (or
`flutter run -d web-server`) works right away without the `flutter create .` step; you
only need that step for a native target (Android/iOS/Windows/etc.) that hasn't been
generated yet.

**The Patient module's 3D companion (`flutter_3d_controller`) has no Windows desktop
support.** Run on web, Android, iOS, or macOS to see it; it falls back to a hand-drawn
companion anywhere the 3D viewer can't initialise. ASHA and Caregiver have no such
restriction.

Verified running end-to-end against Flutter 3.27.1 on web (session flow, persistence,
reminders, alerts, and the patient module's rephrase-ladder games) as of 2026-08-31.

## Structure

```
lib/
  core/           # shared theme (AppTheme.light for dashboards, AppTheme.elder for the
                   # patient module), API base URL, shared models, repository-change
                   # listener mixin
  modules/
    asha/         # Today's Sessions / My Patients / Sync
                  # (docs/claude_SIH26003-04-asha-dashboard-spec.md)
    caregiver/    # Dashboard / Reminders / Alerts / Digest
                  # (docs/claude_SIH26003-05-caregiver-dashboard-spec.md)
    patient/      # Welcome -> profile pick -> voice check-in -> home dashboard, with
                  # games, reminders, family, personal-fact recall, daily-living
                  # guidance and an SOS button (see lib/modules/patient/MODULE_NOTES.md
                  # for that module's own detailed phase-by-phase notes)
```

Each module keeps its own local persistence:
- ASHA/Caregiver's repositories (`data/*_repository.dart`) write through
  `core/local_db/local_store.dart` — shared_preferences' JSON storage today, standing in
  for the real on-device SQLite store (`sqflite`, already in `pubspec.yaml`) described in
  the tech-stack doc. Swap that one class's internals for a sqflite-backed implementation
  once building specifically against Android/iOS; nothing else needs to change.
- The Patient module's `services/local_store.dart` does the same for its own data
  (profiles, streaks, reminders, personal facts, response records) under separate keys —
  the two stores don't collide, but they also don't share data yet (see "known gaps").

## What's actually implemented (verified working, not just scaffolded)

**ASHA** — schedule a group/solo/outreach session → live per-patient, per-round
three-way marking (independent / hint / no response) → **End session** → a session
summary with per-patient tallies → shows as Completed on the list. Onboard a patient with
or without a baseline capture; a patient's trend flag compares her recent *assisted* rounds
against her own baseline (never population norms, never assisted-vs-independent pooled)
and is phrased as "review with...", never a diagnosis. Sessions can be marked missed,
which feeds both the roster's missed count and the caregiver's attendance figures.

**Caregiver** — create a reminder (medicine/hydration/activity/appointment), optionally
record a voice clip (works on web via MediaRecorder) or reuse a previously recorded one;
play any recorded clip back to preview it. "Mark taken"/"Mark missed" simulates the
elder-side ack arriving via sync and updates adherence live. Dashboard and Digest numbers
are derived from real ASHA session records and reminder ack history — nothing is a fixed
placeholder number. Alerts are the same trend flags the ASHA module raises (a shared
`AlertStore`, not two disagreeing copies), markable as reviewed. The family-vs-ASHA-as-
caregiver-of-record distinction is a real, switchable field, not an assumption.

**Patient** — photo-tile profile picker (zero typing) → voice-guided mood check-in → home
dashboard with a today's-goal banner, streak/badge shelf, an SOS button, and a due
daily-living-guidance card. **Play Games** routes through a once-daily comfort intro, then
a game hub (Picture Recall, Memory Match), both wired for reminder interrupt/resume (a
reminder firing mid-game snapshots state, shows a task overlay, and resumes exactly where
you left off on acknowledgement). Picture Recall demonstrates the spec's rephrase ladder —
a wrong tap never says "wrong," it escalates through a softer rephrase, a functional
question, fewer options, then highlight-and-pass. A casual "Tell Me About You" prompt
(at most once every ~20h) builds a personal fact bank that Reminiscence Recall turns into
recall questions with regional distractors. The whole module is driven by a 3D companion
character (or its hand-drawn fallback) with TTS and simple lip sync.

All of the above persists across a reload — real `LocalStore` writes in both modules'
stores, not just in-memory state.

## Known gaps / next steps

- `LocalStore` (ASHA/Caregiver) and the Patient module's own local store are both
  shared_preferences today, not real on-device sqflite — fine for a single-device demo,
  but doesn't match the tech-stack doc's storage choice yet.
- No real backend wiring — everything runs against local repositories; swapping in HTTP
  calls to the FastAPI backend (`../backend`) for sessions/reminders/sync is the next
  step once auth is ready.
- **The three modules don't share data with each other yet.** The Patient module's
  response records, personal facts, and reminders live in its own local store, separate
  from the ASHA/Caregiver repositories — a session played in the Patient module doesn't
  yet show up on the ASHA roster or feed the caregiver's adherence figures. Model field
  names were deliberately kept aligned across both sides (see
  `lib/modules/patient/MODULE_NOTES.md`) specifically so wiring this up later shouldn't
  require renaming anything, but the wiring itself isn't built.
- No localization — all UI text is hardcoded English; content-pack-driven language
  switching per the tech-stack doc isn't built yet.
- Direct voice capture (Bhashini/AI4Bharat STT) for the personal fact bank is explicitly
  deferred per the patient spec — the facilitator-assisted structured-form path is built
  first and is not blocked by STT's absence.
- Seeded demo reminders' voice clips are placeholders (`seed://...`) with no real audio
  behind them — playback is disabled for those specifically; anything recorded through
  the app for real is fully playable.
