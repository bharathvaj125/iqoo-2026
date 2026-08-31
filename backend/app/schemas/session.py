from datetime import datetime

from pydantic import BaseModel

from app.models.session import ConductedBy, ResponseMarking, SessionStatus, SessionType


class SessionCreate(BaseModel):
    type: SessionType
    conducted_by: ConductedBy
    asha_id: str | None = None
    scheduled_time: datetime
    patient_ids: list[str]


class SessionOut(BaseModel):
    id: str
    type: SessionType
    conducted_by: ConductedBy
    asha_id: str | None
    scheduled_time: datetime
    status: SessionStatus
    patient_ids: list[str]

    model_config = {"from_attributes": True}


class ResponseRecordCreate(BaseModel):
    session_id: str
    patient_id: str
    round_number: int
    marking: ResponseMarking
    game_module: str
    timestamp: datetime


class ResponseRecordOut(ResponseRecordCreate):
    id: str

    model_config = {"from_attributes": True}
