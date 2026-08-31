import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class SessionType(str, enum.Enum):
    group = "group"
    solo = "solo"
    outreach = "outreach"


class ConductedBy(str, enum.Enum):
    asha_session = "asha_session"
    independent = "independent"


class SessionStatus(str, enum.Enum):
    scheduled = "scheduled"
    in_progress = "in_progress"
    completed = "completed"
    missed = "missed"


class ResponseMarking(str, enum.Enum):
    independent = "independent"
    hint = "hint"
    no_response = "no_response"


class Session(Base):
    """A session is not implicitly one patient — group sessions carry multiple patient_ids with per-patient response tracking."""

    __tablename__ = "sessions"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    type: Mapped[SessionType] = mapped_column(Enum(SessionType), nullable=False)
    conducted_by: Mapped[ConductedBy] = mapped_column(Enum(ConductedBy), nullable=False)
    asha_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    scheduled_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[SessionStatus] = mapped_column(Enum(SessionStatus), default=SessionStatus.scheduled)
    # patient_ids is stored as a comma-separated string here for SQLite/Postgres portability;
    # a join table is the natural upgrade once the sync service is wired up.
    patient_ids: Mapped[str] = mapped_column(String, nullable=False)


class ResponseRecord(Base):
    """Core telemetry: one row per patient, per round, per session. Feeds the adaptive engine and baseline comparison."""

    __tablename__ = "response_records"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id: Mapped[str] = mapped_column(ForeignKey("sessions.id"), nullable=False)
    patient_id: Mapped[str] = mapped_column(ForeignKey("patients.id"), nullable=False)
    round_number: Mapped[int] = mapped_column(Integer, nullable=False)
    marking: Mapped[ResponseMarking] = mapped_column(Enum(ResponseMarking), nullable=False)
    game_module: Mapped[str] = mapped_column(String, nullable=False)
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
