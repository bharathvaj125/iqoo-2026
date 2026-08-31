import enum
import uuid

from sqlalchemy import Boolean, Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class UserRole(str, enum.Enum):
    asha = "asha"
    caregiver = "caregiver"


class User(Base):
    """ASHA worker or caregiver account. The elder-facing side never authenticates here — photo-tile only, resolved on-device."""

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String, nullable=False)
    phone: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String, nullable=False)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), nullable=False)
    photo_url: Mapped[str | None] = mapped_column(String, nullable=True)
    is_asha_fallback_caregiver: Mapped[bool] = mapped_column(Boolean, default=False)
    voice_clip_url: Mapped[str | None] = mapped_column(String, nullable=True)
