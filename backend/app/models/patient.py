import uuid

from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Patient(Base):
    """A registered elder. Own-baseline scoring: baseline_* fields are captured once at onboarding, never population norms."""

    __tablename__ = "patients"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String, nullable=False)
    photo_url: Mapped[str | None] = mapped_column(String, nullable=True)
    age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    language: Mapped[str] = mapped_column(String, nullable=False)
    assigned_asha_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    primary_caregiver_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    baseline_reaction_time_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    baseline_error_rate: Mapped[int | None] = mapped_column(Integer, nullable=True)
    baseline_hint_dependence: Mapped[int | None] = mapped_column(Integer, nullable=True)
