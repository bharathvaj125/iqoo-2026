from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import auth, patients, reminders, sessions, sync
from app.db.base import Base, engine

# Registers every model's table on Base.metadata so create_all below actually
# has something to create — app/models/__init__.py already imports all of them.
import app.models  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    # No Alembic migration setup yet (see backend/README.md), and this app has
    # no existing production data to migrate around — so the pragmatic
    # hackathon-stage equivalent is creating any table that doesn't already
    # exist when the server actually starts serving. Deliberately *not* run at
    # module import time: tests import this module and override the DB
    # dependency with an in-memory SQLite engine, but FastAPI's TestClient only
    # runs lifespan handlers when used as a context manager, so plain
    # `TestClient(app)` (as tests/conftest.py uses) never touches the real
    # Postgres engine here. Replace with real migrations before this app ever
    # holds data worth preserving.
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Smriti API",
    description="SIH26003 — Cognitive gaming and memory assistance platform for elderly dementia patients in NER.",
    version="0.1.0",
    lifespan=lifespan,
)

# Needed the moment any browser-hosted Flutter build calls this API directly (the
# ASHA/caregiver sign-in flow is the first such caller) — the browser enforces CORS,
# a native Android/iOS/desktop build never hits this. Wide open origins/methods/headers
# is a hackathon-scope simplification; a real deployment should pin this to the actual
# hosted frontend origin(s) instead.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(sessions.router)
app.include_router(reminders.router)
app.include_router(sync.router)


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
