import hashlib
import secrets
import uuid
from datetime import UTC, datetime, timedelta

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from fastapi import Depends, Header
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db import get_db
from app.errors import ApiError
from app.models import Lietotajs

_hasher = PasswordHasher()  # Argon2id, noklusējuma parametri (NFR-04)


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(hashed: str, password: str) -> bool:
    try:
        return _hasher.verify(hashed, password)
    except VerifyMismatchError:
        return False


def create_access_token(user_id: uuid.UUID) -> str:
    s = get_settings()
    now = datetime.now(UTC)
    payload = {"sub": str(user_id), "iat": now, "exp": now + timedelta(minutes=s.access_token_minutes)}
    return jwt.encode(payload, s.jwt_secret, algorithm="HS256")


def new_refresh_token() -> tuple[str, str]:
    """Atgriež (marķieris klientam, SHA-256 glabāšanai serverī)."""
    token = secrets.token_urlsafe(32)
    return token, hashlib.sha256(token.encode()).hexdigest()


def current_user(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> Lietotajs:
    if not authorization or not authorization.startswith("Bearer "):
        raise ApiError(401, "AUTH_REQUIRED", "Lūdzu, piesakieties.")
    try:
        payload = jwt.decode(
            authorization.removeprefix("Bearer "), get_settings().jwt_secret, algorithms=["HS256"]
        )
        user_id = uuid.UUID(payload["sub"])
    except (jwt.PyJWTError, KeyError, ValueError) as exc:
        raise ApiError(401, "AUTH_INVALID", "Sesija beigusies. Piesakieties vēlreiz.") from exc
    user = db.get(Lietotajs, user_id)
    if user is None or user.dzesanas_pieprasijums is not None:
        raise ApiError(401, "AUTH_INVALID", "Sesija beigusies. Piesakieties vēlreiz.")
    return user
