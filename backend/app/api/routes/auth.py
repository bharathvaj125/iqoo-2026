from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session as DBSession

from app.api.deps import get_current_user
from app.core.security import create_access_token
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import EmailLoginRequest, SetRoleRequest, TokenResponse

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login(payload: EmailLoginRequest, db: DBSession = Depends(get_db)) -> TokenResponse:
    """ASHA/caregiver login only — the elder-facing side never uses this, it's photo-tile/on-device.

    Passwordless find-or-create by email: an existing address logs straight into its
    account; a new one is created on the spot. This is a deliberate hackathon-scope
    simplification — no password, no OTP/email-verification step. A freshly created
    account has `role: null` in the response; the frontend should walk it through the
    one-time role-selection step and call POST /api/auth/role next.
    """
    user = db.query(User).filter(User.email == payload.email).first()
    if user is None:
        user = User(email=payload.email)
        db.add(user)
        db.commit()
        db.refresh(user)

    token = create_access_token(subject=user.id, role=user.role.value if user.role else None)
    return TokenResponse(access_token=token, role=user.role)


@router.post("/role", response_model=TokenResponse)
def set_role(
    payload: SetRoleRequest,
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TokenResponse:
    """One-time role assignment for a freshly created account (see /login above).

    Deliberately a one-shot: once a role is set it can't be changed through this
    endpoint, since nothing in this build expects an ASHA/caregiver account to switch
    roles mid-use. Returns a new token with the role embedded, replacing the
    role-less one issued at signup.
    """
    if current_user.role is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role is already set for this account")

    current_user.role = payload.role
    db.commit()
    db.refresh(current_user)

    token = create_access_token(subject=current_user.id, role=current_user.role.value)
    return TokenResponse(access_token=token, role=current_user.role)
