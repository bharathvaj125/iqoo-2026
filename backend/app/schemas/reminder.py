from datetime import datetime

from pydantic import BaseModel

from app.models.reminder import AckStatus, ReminderType


class ReminderCreate(BaseModel):
    patient_id: str
    created_by: str
    type: ReminderType
    schedule: str
    voice_clip_url: str | None = None
    text_label: str


class ReminderOut(ReminderCreate):
    id: str

    model_config = {"from_attributes": True}


class ReminderAckCreate(BaseModel):
    reminder_id: str
    patient_id: str
    timestamp: datetime
    status: AckStatus


class ReminderAckOut(ReminderAckCreate):
    id: str

    model_config = {"from_attributes": True}
