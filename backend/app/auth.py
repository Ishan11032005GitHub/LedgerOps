from datetime import datetime, timedelta, timezone
import hashlib
import secrets
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from .config import get_settings
from .database import get_db
from .models import AuthSession, Role, User


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return pwd_context.verify(password, hashed)


def create_token(subject: str, token_type: str, expires_delta: timedelta, role: str, session_id: str | None = None) -> str:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    payload = {"sub": subject, "type": token_type, "role": role, "iat": now, "exp": now + expires_delta}
    if session_id:
        payload["sid"] = session_id
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def token_pair(user: User, db: Session, *, revoke_session_id: str | None = None) -> dict:
    settings = get_settings()
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if revoke_session_id:
        prior = db.query(AuthSession).filter(AuthSession.session_id == revoke_session_id, AuthSession.user_id == user.id).first()
        if prior:
            prior.revoked_at = now
    session_id = secrets.token_urlsafe(24)
    refresh_token = create_token(user.email, "refresh", timedelta(days=settings.refresh_token_days), user.role.value, session_id)
    db.add(AuthSession(
        user_id=user.id,
        session_id=session_id,
        refresh_token_hash=hashlib.sha256(refresh_token.encode()).hexdigest(),
        expires_at=now + timedelta(days=settings.refresh_token_days),
    ))
    db.commit()
    return {
        "access_token": create_token(user.email, "access", timedelta(minutes=settings.access_token_minutes), user.role.value, session_id),
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {"id": user.id, "email": user.email, "name": user.name, "role": user.role.value, "account_type": user.account_type, "workspace_name": user.workspace_name},
    }


def current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    settings = get_settings()
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        if payload.get("type") != "access":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid access token")
        email = payload.get("sub")
        session_id = payload.get("sid")
    except JWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc
    user = db.query(User).filter(User.email == email, User.is_active.is_(True)).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    if session_id:
        session = db.query(AuthSession).filter(
            AuthSession.session_id == session_id,
            AuthSession.user_id == user.id,
            AuthSession.revoked_at.is_(None),
            AuthSession.expires_at > datetime.now(timezone.utc).replace(tzinfo=None),
        ).first()
        if not session:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session has expired")
    return user


def require_roles(*roles: Role):
    def checker(user: User = Depends(current_user)) -> User:
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")
        return user
    return checker
