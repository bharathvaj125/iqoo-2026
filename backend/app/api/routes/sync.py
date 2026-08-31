from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session as DBSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.reminder import ReminderAck
from app.models.session import ResponseRecord, Session
from app.models.user import User
from app.schemas.sync import SyncPayload, SyncResult

router = APIRouter(prefix="/api/sync", tags=["sync"])


@router.post("", response_model=SyncResult)
def sync_batch(
    payload: SyncPayload,
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SyncResult:
    """Reconciles a tablet's store-and-forward outbox against Postgres. Never blocks the tablet's own usage."""
    for s in payload.sessions:
        db.add(
            Session(
                type=s.type,
                conducted_by=s.conducted_by,
                asha_id=s.asha_id or current_user.id,
                scheduled_time=s.scheduled_time,
                patient_ids=",".join(s.patient_ids),
            )
        )
    for r in payload.response_records:
        db.add(ResponseRecord(**r.model_dump()))
    for a in payload.reminder_acks:
        db.add(ReminderAck(**a.model_dump()))

    db.commit()
    return SyncResult(
        accepted_sessions=len(payload.sessions),
        accepted_response_records=len(payload.response_records),
        accepted_reminder_acks=len(payload.reminder_acks),
    )
