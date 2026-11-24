"""API-01 reģistrācija, API-02 pieteikšanās, API-03 sesijas atjaunošana un iziešana,
API-04 profils (FR-01, FR-02, DR-10)."""

import hashlib
import re
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel, EmailStr, field_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db import get_db
from app.errors import ApiError
from app.models import AtjaunosanasMarkieris, Lietotajs
from app.security import (
    create_access_token,
    current_user,
    hash_password,
    new_refresh_token,
    verify_password,
)

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


class RegisterIn(BaseModel):
    epasts: EmailStr
    parole: str

    @field_validator("parole")
    @classmethod
    def strong(cls, v: str) -> str:
        if len(v) < 10 or not re.search(r"[a-z]", v) or not re.search(r"[A-Z]", v) \
                or not re.search(r"\d", v):
            raise ValueError("Parolei jābūt vismaz 10 rakstzīmēm ar mazo, lielo burtu un ciparu.")
        return v


class LoginIn(BaseModel):
    epasts: EmailStr
    parole: str


class RefreshIn(BaseModel):
    refresh_token: str


def _aware(dt: datetime | None) -> datetime | None:
    return dt.replace(tzinfo=UTC) if dt is not None and dt.tzinfo is None else dt


@router.post("/register", status_code=201)
def register(body: RegisterIn, db: Session = Depends(get_db)):
    email = body.epasts.lower()
    if db.scalar(select(Lietotajs).where(Lietotajs.epasts == email)):
        raise ApiError(409, "EMAIL_TAKEN", "Šis e-pasts jau ir reģistrēts.", field="epasts")
    user = Lietotajs(epasts=email, paroles_jaucejvertiba=hash_password(body.parole))
    db.add(user)
    db.commit()
    return {"lietotaja_id": str(user.id)}


@router.post("/login")
def login(body: LoginIn, db: Session = Depends(get_db)):
    s = get_settings()
    now = datetime.now(UTC)
    bad = ApiError(401, "INVALID_CREDENTIALS", "E-pasts vai parole nav pareiza.")
    user = db.scalar(select(Lietotajs).where(Lietotajs.epasts == body.epasts.lower()))
    if user is None:
        raise bad

    blocked = _aware(user.blokets_lidz)
    if blocked and blocked > now:
        raise ApiError(423, "ACCOUNT_LOCKED", "Konts īslaicīgi bloķēts. Mēģiniet pēc 15 minūtēm.")

    if not verify_password(user.paroles_jaucejvertiba, body.parole):
        first = _aware(user.pirmais_neveiksmigais)
        if first is None or now - first > timedelta(minutes=s.lockout_minutes):
            user.pirmais_neveiksmigais, user.neveiksmigi_meginajumi = now, 0
        user.neveiksmigi_meginajumi += 1
        if user.neveiksmigi_meginajumi >= s.max_failed_logins:
            user.blokets_lidz = now + timedelta(minutes=s.lockout_minutes)
            user.neveiksmigi_meginajumi, user.pirmais_neveiksmigais = 0, None
        db.commit()
        remaining = s.max_failed_logins - user.neveiksmigi_meginajumi
        bad.detail = f"remaining_attempts={remaining}"
        raise bad

    user.neveiksmigi_meginajumi, user.pirmais_neveiksmigais, user.blokets_lidz = 0, None, None
    return _issue(db, user)


def _issue(db: Session, user: Lietotajs) -> dict:
    s = get_settings()
    refresh, refresh_hash = new_refresh_token()
    db.add(AtjaunosanasMarkieris(
        lietotaja_id=user.id,
        markiera_jaucejvertiba=refresh_hash,
        deriga_lidz=datetime.now(UTC) + timedelta(days=s.refresh_token_days),
    ))
    db.commit()
    return {
        "access_token": create_access_token(user.id),
        "token_type": "bearer",
        "expires_in": s.access_token_minutes * 60,
        "refresh_token": refresh,
    }


def _find_refresh(db: Session, token: str) -> AtjaunosanasMarkieris | None:
    digest = hashlib.sha256(token.encode()).hexdigest()
    return db.scalar(select(AtjaunosanasMarkieris)
                     .where(AtjaunosanasMarkieris.markiera_jaucejvertiba == digest))


@router.post("/refresh")
def refresh(body: RefreshIn, db: Session = Depends(get_db)):
    """Rotācija: vecais marķieris tiek anulēts, izsniegts jauns pāris."""
    row = _find_refresh(db, body.refresh_token)
    expired = row is None or row.anulets or _aware(row.deriga_lidz) <= datetime.now(UTC)
    user = None if row is None else db.get(Lietotajs, row.lietotaja_id)
    if expired or user is None or user.dzesanas_pieprasijums is not None:
        raise ApiError(401, "AUTH_INVALID", "Sesija beigusies. Piesakieties vēlreiz.")
    row.anulets = True
    return _issue(db, user)


@router.post("/logout", status_code=204)
def logout(body: RefreshIn, db: Session = Depends(get_db)):
    row = _find_refresh(db, body.refresh_token)
    if row is not None:
        row.anulets = True
        db.commit()


@router.get("/me")
def me(user: Lietotajs = Depends(current_user)):
    return {"lietotaja_id": str(user.id), "epasts": user.epasts}
