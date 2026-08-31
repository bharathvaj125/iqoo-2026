from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session as DBSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.session import ResponseRecord, Session
from app.models.user import User
from app.schemas.session import ResponseRecordCreate, ResponseRecordOut, SessionCreate, SessionOut

router = APIRouter(prefix="/api/sessions", tags=["sessions"])


def _to_out(session: Session) -> SessionOut:
    return SessionOut(
        id=session.id,
        type=session.type,
        conducted_by=session.conducted_by,
        asha_id=session.asha_id,
        scheduled_time=session.scheduled_time,
        status=session.status,
        patient_ids=session.patient_ids.split(",") if session.patient_ids else [],
    )


@router.get("", response_model=list[SessionOut])
def list_sessions(
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[SessionOut]:
    """Today's Sessions panel — both group and solo/outreach types, filtered to the calling ASHA."""
    sessions = db.query(Session).filter(Session.asha_id == current_user.id).all()
    return [_to_out(s) for s in sessions]


@router.post("", response_model=SessionOut, status_code=201)
def create_session(
    payload: SessionCreate,
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SessionOut:
    """Group sessions carry multiple patient_ids; solo/outreach carry exactly one."""
    session = Session(
        type=payload.type,
        conducted_by=payload.conducted_by,
        asha_id=payload.asha_id or current_user.id,
        scheduled_time=payload.scheduled_time,
        patient_ids=",".join(payload.patient_ids),
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return _to_out(session)


@router.post("/{session_id}/responses", response_model=ResponseRecordOut, status_code=201)
def record_response(
    session_id: str,
    payload: ResponseRecordCreate,
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ResponseRecord:
    """Three-way marking per patient per round: independent / hint / no_response. Feeds the adaptive engine."""
    if payload.session_id != session_id:
        raise HTTPException(status_code=400, detail="session_id mismatch between path and body")

    record = ResponseRecord(**payload.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record
