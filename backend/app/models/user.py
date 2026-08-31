import enum
import uuid

from sqlalchemy import Boolean, Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class UserRole(str, enum.Enum):
    asha = "asha"
    caregiver = "caregiver"


class User(Base):
    """ASHA worker or caregiver account. The elder-facing side never authenticates here — photo-tile only, resolved on-device.

    Passwordless by design (hackathon-scope simplification, see app/api/routes/auth.py):
    an account is identified by email alone, and `role` starts unset for a brand-new
    account until the frontend's one-time role-selection step assigns it.
    """

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email: Mapped[str] = mapped_column(String, unique=True, nullable=False, index=True)
    name: Mapped[str | None] = mapped_column(String, nullable=True)
    phone: Mapped[str | None] = mapped_column(String, unique=True, nullable=True)
    role: Mapped[UserRole | None] = mapped_column(Enum(UserRole), nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String, nullable=True)
    is_asha_fallback_caregiver: Mapped[bool] = mapped_column(Boolean, default=False)
    voice_clip_url: Mapped[str | None] = mapped_column(String, nullable=True)
