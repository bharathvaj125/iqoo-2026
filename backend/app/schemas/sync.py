from pydantic import BaseModel

from app.schemas.reminder import ReminderAckCreate
from app.schemas.session import ResponseRecordCreate, SessionCreate


class SyncPayload(BaseModel):
    """Store-and-forward batch a tablet bursts up once connectivity is available."""

    device_id: str
    sessions: list[SessionCreate] = []
    response_records: list[ResponseRecordCreate] = []
    reminder_acks: list[ReminderAckCreate] = []


class SyncResult(BaseModel):
    accepted_sessions: int
    accepted_response_records: int
    accepted_reminder_acks: int
