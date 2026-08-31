# Features implemented

Scope: backend skeleton + all three Flutter modules (ASHA, Caregiver, Patient — the last
built separately by a teammate and merged in). Everything below has been run and verified
live, not just written — see `frontend/README.md` / `backend/README.md` for how to run it
yourself.

## Backend (FastAPI)

- JWT auth (`/api/auth/login`)
- Patients: list / create / get (`/api/patients`)
- Sessions, Reminders, Sync REST routes matching the data model in the tech-stack/ASHA/
  caregiver spec docs
- SQLAlchemy models: User, Patient, CareSession, ResponseRecord, Reminder, ReminderAck
- Verified running locally against Python 3.14 (`/api/health`, Swagger docs at `/docs`)

## ASHA module

- **Today's Sessions** — only today's, split into upcoming and "Done today"; group is the
  default, solo/outreach one tap away rather than a separate primary flow
- **New session** — group/solo/outreach type, multi-select patients, time picker
- **In-session marking** — three-way response per patient per round (Independent /
  Needed a hint / No response), large tap targets for live use on a shared tablet.
  Submitting a round is guarded against double-taps
- **Mark a session missed** — feeds the roster's missed count and the caregiver's
  attendance figures
- **End session → Session Summary** — per-patient round tallies shown immediately, with
  any trend flag inline; no report-writing afterward
- **Patient onboarding + baseline capture** — register an elder and capture the personal
  reaction/error/hint readings every later session is scored against. Someone onboarded
  without a baseline is shown as "No baseline" rather than silently scored against nothing
- **Own-baseline trend flagging** — compares her recent assisted rounds against *her own*
  onboarding baseline (or her own earlier rounds if none was captured) and flags sustained
  drift. Assisted and independent play are never pooled. Always phrased as a trend to
  review, never a diagnosis
- **My Patients** — roster sorted so anyone flagged or missing sessions rises to the top;
  real baseline values, missed-session count, and assisted/independent-labelled history
- **Sync** — offline outbox (queued → syncing → synced), reconnect-and-drain
- **Persistence** — patients, sessions, response records, and the sync outbox all survive
  an app restart

## Caregiver module

- **Dashboard** — every figure derived from real records, with an action attached to each:
  "Flag to ASHA" for missed sessions, "Review" for falling adherence, "Open Alerts" for
  open flags. Metrics with no data yet read "—", not a flattering default
- **Adherence by reminder type** — medicine / hydration / activity / appointment, worst
  first, so one slipping category isn't hidden inside a healthy-looking average
- **Family vs ASHA-as-caregiver-of-record** — a real field on the caregiver record, not an
  assumption that every elder has family. The dashboard reframes itself for each, and the
  role is switchable so both are demonstrable
- **Reminders** — create reminders across all four PS-named categories with a schedule
- **Voice clips** — record a real clip (mic), preview it before saving, and **reuse a
  previously recorded clip** on later reminders instead of re-recording (novelty claim #6,
  actually implemented rather than described)
- **Live adherence** — "Mark taken" / "Mark missed" (standing in for the elder-side ack
  arriving via sync) updates that reminder's rate immediately
- **Alerts** — the same trend flags the ASHA module raises, with "Mark reviewed"; each
  carries an explicit "not a diagnosis" line
- **Weekly digest** — real seven-day window, attendance, per-type breakdown, and highlights
  generated from what actually happened
- **Persistence** — reminders, acknowledgement history, alerts, caregiver role, and the
  recorded-clip library all survive an app restart

## Patient module

Built separately, merged into this app under `lib/modules/patient/`, repointed onto the
shared theme. Two real bugs were found and fixed during that merge (see "Fixed during
merge" below); everything else below was verified working as originally built.

- **Comfort-first entry** — a 3D companion character (`flutter_3d_controller`, with a
  hand-drawn fallback where the 3D viewer can't load) greets by voice before anything
  else, then a zero-typing photo-tile profile picker, then a voice-guided mood check-in
- **Home dashboard** — today's-goal banner, streak/badge shelf, an always-visible SOS
  button, and at most one daily-living-guidance card per time-of-day bucket per day
- **Adaptive Memory Match** — grid size (difficulty) tunes from a stored per-elder
  difficulty level; no score or accuracy is ever shown to the patient
- **Picture Recall's rephrase ladder** — a wrong tap never says "wrong": soft rephrase →
  functional question → fewer options → highlight-and-pass. Also wired for reminder
  interrupt/resume — a reminder firing mid-game snapshots state and resumes exactly where
  play left off on acknowledgement
- **Personal Fact Bank + Reminiscence Recall** — a casual "Tell Me About You" prompt
  (facilitator-assisted, structured form — no speech recognition needed) builds a bank of
  personal facts; Reminiscence Recall turns a random one into a naming + functional
  question pair with regional distractors, using the same rephrase ladder, and logs
  `fromPersonalFact: true` so this signal stays distinguishable from generic recall
- **Reminders** — meds/water/appointments with one-tap confirm, a demo "ring now" trigger,
  and the interrupt/resume flow shared with both games
- **Family** — photo + voice-note per relative
- **Persistence** — active profile, streaks, badges, personal facts, response records,
  and pending sync logs all survive an app restart, via the module's own local store

### Fixed during merge

- **`picture_recall_screen.dart` and `reminiscence_recall_screen.dart`** both had the same
  bug in their "starting fresh" path: `_shownOptions = _optionsFor(0, 0);` assigned the
  field directly instead of through `setState()`. Since that assignment happens after the
  screen's first build (inside an async `initState` continuation), Flutter was never told
  to rebuild — the answer-options grid stayed stuck showing its initial empty list
  forever. Confirmed live in a browser: before the fix, Picture Recall showed the
  question and "Say it again" but zero answer tiles; after, all four tiles render and the
  rephrase ladder works end to end.
- `DropdownButtonFormField`'s `initialValue` parameter (used in
  `personal_fact_entry_screen.dart`) doesn't exist on this project's Flutter version
  (3.27.1) — that name was added in a newer SDK. Reverted to `value`, the name this
  version has.

## Cross-cutting

- Dev-only role picker as the app's entry point, standing in for real JWT login until
  that's wired up
- Local persistence via `LocalStore` (shared_preferences today) — a deliberate stand-in
  for the on-device SQLite store called for in the tech-stack doc; swapping the storage
  backend later won't touch any screen code
- A shared `AlertStore` both modules read, so a flag raised while running a session
  actually reaches the caregiver's dashboard instead of the two sides disagreeing
- Screens rebuild from repository change streams, so finishing work in one panel updates
  the others rather than leaving stale figures on screen
- One `AppTheme` for the whole app: `AppTheme.light` (dashboard density) for ASHA and
  Caregiver, `AppTheme.elder` (larger type, taller tap targets) for the Patient module —
  same palette, chosen for how ageing and dementia actually change vision and attention
  (see the doc comment on `AppColors` in `lib/core/theme.dart`), not for looks
- 17 passing tests (scoring rules and widget flows); `flutter analyze` clean
- Verified end-to-end in a live browser run, not just compiled

## Not done yet

- Not wired to the backend (frontend is still local-only)
- No real on-device SQLite (see LocalStore note above)
- **The Patient module doesn't share data with ASHA/Caregiver yet.** It keeps its own
  local store, separate from `AshaRepository`/`CaregiverRepository`/`AlertStore` — a
  session played in the Patient module doesn't show up on the ASHA roster or feed the
  caregiver's adherence figures. Model field names were deliberately kept aligned across
  both sides so this shouldn't require renaming anything when it's built
- Direct voice capture (Bhashini/AI4Bharat STT) for the personal fact bank is deferred,
  per the patient spec itself — additive only, never blocking the facilitator-assisted
  path that's built
- Baseline *measurement* is stubbed — the readings should come from the patient game
  module instrumenting a real play session, which is the other teammate's work. The
  capture flow, the readings, and everything scored against them are real; only the
  source of the three numbers stands in, and the screen says so
- The trend rule is a deliberate, explainable threshold, not a learned model. It is the
  right shape (own-baseline drift, assisted-only) but the adaptive engine proper is still
  to come
- No Redis, Firebase push, or Alembic migrations on the backend
- No localization — UI text is hardcoded English, so the content-pack story from the
  tech-stack doc isn't demonstrable yet
