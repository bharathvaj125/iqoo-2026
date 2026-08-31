from pydantic import BaseModel


class PatientBase(BaseModel):
    name: str
    photo_url: str | None = None
    age: int | None = None
    language: str
    primary_caregiver_id: str | None = None


class PatientCreate(PatientBase):
    assigned_asha_id: str
    baseline_reaction_time_ms: int | None = None
    baseline_error_rate: int | None = None
    baseline_hint_dependence: int | None = None


class PatientOut(PatientBase):
    id: str
    assigned_asha_id: str

    model_config = {"from_attributes": True}
