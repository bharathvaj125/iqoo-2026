from pydantic import BaseModel, EmailStr

from app.models.user import UserRole


class EmailLoginRequest(BaseModel):
    email: EmailStr


class SetRoleRequest(BaseModel):
    role: UserRole


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    # None means this account hasn't completed the one-time role-selection step yet —
    # the frontend should show that step and then call POST /api/auth/role.
    role: UserRole | None
