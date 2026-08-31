# SIH26003 — Tech Stack & Architecture (for Claude Code)

This is the locked stack decision. Don't introduce alternative frameworks/libraries without checking with the team first.

## Stack tree (as decided)

```
FRONTEND
Flutter + Dart
│
├── Patient Module        (in progress — other teammate)
├── ASHA Module           (building next)
└── Caregiver Module      (building next)
        │
        ├── Flame
        │     └── Cognitive Games
        │
        ▼
BACKEND
FastAPI + Python
├── REST APIs
├── JWT Auth
├── Clinical Engines
├── AI/ML
└── Sync Service
        │
        ▼
DATA & SERVICES
SQLite       → Offline local storage
PostgreSQL   → Main cloud database
Redis        → Cache
Firebase     → Push notifications & alerts
```

## Module notes

- **Patient Module** — the elder-facing surface. Photo-tile login (no typed login), voice-first prompts, the Flame-based cognitive games sit under here. Owned by teammate currently.
- **ASHA Module** — the group-session facilitation surface. This is the app's core delivery mechanism (see novelty claim #2 — group CST on one shared tablet). Runs on the same shared tablet as the Patient Module; ASHA picks it up to start/manage a session, Patient Module runs during the session itself.
- **Caregiver Module** — the async, usually-remote surface. Reminders (with recorded voice clips), engagement digests, alerts. Can run on the caregiver's own phone, separate from the shared tablet.
- **Flame** — Flutter's 2D game engine, used specifically for the five cognitive game modules (memory matching, rhythm/tap, sequential recall, motif completion, reminiscence trivia). Sits under the Patient Module since that's where gameplay renders, but session *control* (start/pause/who's playing) is driven from the ASHA Module.

## Backend responsibilities

- **REST APIs** — CRUD for patients, sessions, reminders, sync payloads.
- **JWT Auth** — for ASHA and caregiver login (elder-facing side never has typed/token auth — photo-tile only, resolved locally).
- **Clinical Engines** — CST session structuring, baseline comparison, trend detection logic (not diagnosis — see positioning doc).
- **AI/ML** — adaptive difficulty engine (target ~80% success rate, tuned per session from error rate/reaction time/hesitation/hints used).
- **Sync Service** — receives store-and-forward JSON deltas from tablets when connectivity is available; reconciles against PostgreSQL.

## Data layer

- **SQLite (on-device)** — source of truth while offline. Games, session logs, reminder acknowledgements, patient roster all fully functional at zero connectivity. This is not a cache — it's the primary store during a session.
- **PostgreSQL (cloud)** — main database once synced. Longitudinal trends, cross-ASHA/cross-region views live here.
- **Redis** — cache layer, likely for dashboard read performance (ASHA's patient list, caregiver's digest) and/or session state during active group sessions.
- **Firebase** — push notifications and alerts (e.g., caregiver alert on missed session or performance drop; only meaningful when the caregiver's device has connectivity — the elder/ASHA side does not depend on this).

## System workflow reference (from deck architecture slide)
`ASHA/Group Interface + Patient/Individual Interface → AI/ML Adaptive Engine → Local Database (SQLite, offline) → SatCom/VSAT/Cloud Sync → Caregiver Dashboard + Health Worker Reports`

Two 7-step app-workflow rows exist in the pitch deck for reference:
- **ASHA Worker — Group Therapy Mode**
- **Patient — Individual Daily Mode**

If you need the literal step-by-step breakdown of either row for UI flow design, ask — it's in the deck build notes, not duplicated here to avoid drift between two copies.

## Non-negotiable constraints for anything built in ASHA/Caregiver modules
1. **Offline-first.** Every screen must be fully usable with zero connectivity. Sync is opportunistic, never blocking.
2. **No typed login for the elder.** Doesn't apply to ASHA/Caregiver themselves — they authenticate normally (JWT), but nothing they build should force the elder through a credential flow.
3. **Group-first data model.** A "session" is not implicitly one patient — it can be a group of patients on one tablet at one scheduled time, with per-patient response tracking inside it.
4. **Modular content packs.** Cultural/language content is data, not hardcoded strings — new region/district should be addable without touching app logic.
