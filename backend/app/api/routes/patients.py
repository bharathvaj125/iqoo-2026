from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session as DBSession

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.patient import Patient
from app.models.user import User
from app.schemas.patient import PatientCreate, PatientOut

router = APIRouter(prefix="/api/patients", tags=["patients"])


@router.get("", response_model=list[PatientOut])
def list_patients(
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Patient]:
    """My Patients panel: roster assigned to the calling ASHA, or patients tied to a caregiver."""
    query = db.query(Patient)
    if current_user.role.value == "asha":
        query = query.filter(Patient.assigned_asha_id == current_user.id)
    else:
        query = query.filter(Patient.primary_caregiver_id == current_user.id)
    return query.all()


@router.post("", response_model=PatientOut, status_code=201)
def create_patient(
    payload: PatientCreate,
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Patient:
    """Onboarding: captures the individual baseline used for all later drift comparisons."""
    patient = Patient(**payload.model_dump())
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return patient


@router.get("/{patient_id}", response_model=PatientOut)
def get_patient(
    patient_id: str,
    db: DBSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Patient:
    patient = db.get(Patient, patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient
