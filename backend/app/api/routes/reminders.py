from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session as DBSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.reminder import Reminder, ReminderAck
from app.models.user import User
from app.schemas.reminder import ReminderAckCreate, ReminderAckOut, ReminderCreate, ReminderOut

router = APIRouter(prefix="/api/reminders", tags=["reminders"])


@router.get("", response_model=list[ReminderOut])
def list_reminders(
    patient_id: str,
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Reminder]:
    return db.query(Reminder).filter(Reminder.patient_id == patient_id).all()


@router.post("", response_model=ReminderOut, status_code=201)
def create_reminder(
    payload: ReminderCreate,
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Reminder:
    """created_by may be a caregiver or an ASHA acting as fallback caregiver-of-record."""
    reminder = Reminder(**payload.model_dump())
    db.add(reminder)
    db.commit()
    db.refresh(reminder)
    return reminder


@router.post("/acks", response_model=ReminderAckOut, status_code=201)
def acknowledge_reminder(
    payload: ReminderAckCreate,
    db: DBSession = Depends(get_db),
) -> ReminderAck:
    """Elder taps the caregiver's photo to acknowledge — this endpoint is called by the sync service, not the elder directly."""
    ack = ReminderAck(**payload.model_dump())
    db.add(ack)
    db.commit()
    db.refresh(ack)
    return ack
