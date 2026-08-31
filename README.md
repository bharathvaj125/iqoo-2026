# Smriti — SIH26003

AI-based cognitive gaming and memory-assistance platform for elderly dementia patients in
India's North Eastern Region. See `docs/` for the full problem context, positioning, and
module specs — read those before changing scope on anything here.

## The whitespace, one sentence

> Digital CST exists, but has only ever been built for people who are literate, connected,
> and accompanied by a caregiver who can operate a device. Smriti removes all three
> assumptions at once.

## Stack

- **Frontend** — Flutter/Dart, one app with three role-scoped modules:
  - **Patient** — the elder-facing surface: photo-tile profile picker, voice-guided
    check-in, a 3D companion character (TTS + lip sync) that leads every interaction,
    adaptive memory games with a rephrase ladder (never says "wrong"), reminders,
    personal-fact-driven recall, daily-living guidance, and an SOS button
  - **ASHA** — the community health worker's dashboard: group session facilitation,
    patient roster, own-baseline trend flagging, offline sync outbox
  - **Caregiver** — the (often distant) family member's dashboard: reminders with
    recorded-voice playback, adherence tracking, trend alerts, weekly digest
- **Backend** — FastAPI/Python: REST + JWT auth + sync service
- **Data** — SQLite (on-device, source of truth offline) · PostgreSQL (cloud) · Redis
  (cache) · Firebase (push)

## Repo layout

```
backend/    FastAPI app — see backend/README.md to run it
frontend/   Flutter app — see frontend/README.md to run it (needs Flutter SDK)
docs/       Spec docs: problem context, novelty/positioning, tech stack, module specs,
            and FEATURES.md — a running list of what's actually implemented vs. stubbed
```

## Status

One Flutter app, three modules, one shared theme and role picker (dev-only — each role
authenticates for real once that's wired up). Backend is a working FastAPI skeleton,
verified running locally; the frontend is not yet wired to it.

- **ASHA + Caregiver**: full session lifecycle (schedule → run → mark responses →
  complete → summary), own-baseline trend flagging that reaches the caregiver's Alerts
  tab, reminders with voice record/playback and live adherence tracking, patient
  onboarding + baseline capture, and the family-vs-ASHA-as-caregiver-of-record
  distinction. All of it persists across a restart via `LocalStore`
  (shared_preferences today, standing in for the on-device sqflite store called for in
  the tech-stack doc).
- **Patient**: Phases 1–3 of the patient spec — comfort-first onboarding, the
  rephrase-ladder recall games, reminders with interrupt/resume, streaks/badges, the
  personal fact bank and reminiscence recall built from it, and daily-living guidance
  cards. The 3D companion (`flutter_3d_controller`) has no Windows desktop support —
  run this module on web, Android, iOS, or macOS.
- **Not yet wired together**: the three modules don't share data across each other's
  backend calls yet (patient module is fully local-only); see `docs/FEATURES.md` for
  the full breakdown of what's real vs. stubbed in each module.

See `frontend/README.md` and `backend/README.md` for exactly what's left and how to run
each piece.
