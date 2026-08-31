from fastapi import FastAPI

from app.api.routes import auth, patients, reminders, sessions, sync

app = FastAPI(
    title="Smriti API",
    description="SIH26003 — Cognitive gaming and memory assistance platform for elderly dementia patients in NER.",
    version="0.1.0",
)

app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(sessions.router)
app.include_router(reminders.router)
app.include_router(sync.router)


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
