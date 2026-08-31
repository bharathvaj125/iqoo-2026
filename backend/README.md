# Smriti backend (FastAPI)

REST API + JWT auth + sync service for the ASHA and Caregiver modules.

## Run locally

```bash
cd backend
python -m venv .venv
.venv/Scripts/activate        # Windows; use `source .venv/bin/activate` on macOS/Linux
pip install -r requirements.txt
cp .env.example .env          # then point DATABASE_URL at a real Postgres if you have one
uvicorn app.main:app --reload
```

Visit `http://127.0.0.1:8000/docs` for interactive API docs, or `http://127.0.0.1:8000/api/health`
for a liveness check. Verified working against Python 3.14 as of 2026-08-29.

## Structure

- `app/models/` — SQLAlchemy models (mirrors the data model in the tech-stack/ASHA/caregiver specs)
- `app/schemas/` — Pydantic request/response schemas
- `app/api/routes/` — `auth`, `patients`, `sessions`, `reminders`, `sync`
- `app/core/` — settings + JWT/password hashing
- `app/db/` — SQLAlchemy engine/session setup (Postgres; SQLite lives on-device in the Flutter app, not here)

## Not yet wired up

- Redis caching (dependency is installed, not yet used anywhere)
- Firebase push notifications
- Actual AI/ML adaptive-difficulty and baseline-drift logic (routes currently do plain CRUD)
- Alembic migrations — tables aren't created automatically; add a migration setup before real use
