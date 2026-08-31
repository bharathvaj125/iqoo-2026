from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import auth, patients, reminders, sessions, sync

app = FastAPI(
    title="Smriti API",
    description="SIH26003 — Cognitive gaming and memory assistance platform for elderly dementia patients in NER.",
    version="0.1.0",
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
