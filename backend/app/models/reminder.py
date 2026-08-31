import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ReminderType(str, enum.Enum):
    medicine = "medicine"
    hydration = "hydration"
    activity = "activity"
    appointment = "appointment"


class AckStatus(str, enum.Enum):
    acknowledged = "acknowledged"
    missed = "missed"


class Reminder(Base):
    """created_by may be a caregiver_id or an asha_id acting as fallback caregiver-of-record."""

    __tablename__ = "reminders"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id: Mapped[str] = mapped_column(ForeignKey("patients.id"), nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    type: Mapped[ReminderType] = mapped_column(Enum(ReminderType), nullable=False)
    schedule: Mapped[str] = mapped_column(String, nullable=False)  # cron-like or ISO recurrence string
    voice_clip_url: Mapped[str | None] = mapped_column(String, nullable=True)  # falls back to TTS if null
    text_label: Mapped[str] = mapped_column(String, nullable=False)


class ReminderAck(Base):
    __tablename__ = "reminder_acks"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    reminder_id: Mapped[str] = mapped_column(ForeignKey("reminders.id"), nullable=False)
    patient_id: Mapped[str] = mapped_column(ForeignKey("patients.id"), nullable=False)
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[AckStatus] = mapped_column(Enum(AckStatus), nullable=False)
