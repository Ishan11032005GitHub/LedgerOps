from datetime import datetime, timedelta
import hashlib
import secrets
from fastapi import APIRouter, Depends, HTTPException, status
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from ..auth import create_token, current_user, hash_password, token_pair, verify_password
from ..config import get_settings
from ..database import get_db
from ..models import AccountPreference, PasswordResetToken, User
from ..schemas import AccountPreferencesIn, ForgotPasswordIn, LoginIn, PasswordChangeIn, ProfileUpdateIn, RefreshIn, ResetPasswordIn, SignupIn

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/signup")
def signup(payload: SignupIn, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == payload.email).first():
        raise HTTPException(status_code=409, detail="Email already registered")
    user = User(email=payload.email, name=payload.name, role=payload.role, hashed_password=hash_password(payload.password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return token_pair(user)


@router.post("/login")
def login(payload: LoginIn, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    return token_pair(user)


@router.post("/refresh")
def refresh(payload: RefreshIn, db: Session = Depends(get_db)):
    settings = get_settings()
    try:
        decoded = jwt.decode(payload.refresh_token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        if decoded.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid refresh token")
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid refresh token") from exc
    user = db.query(User).filter(User.email == decoded.get("sub")).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return {
        "access_token": create_token(user.email, "access", timedelta(minutes=settings.access_token_minutes), user.role.value),
        "token_type": "bearer",
    }


@router.get("/me")
def me(user: User = Depends(current_user)):
    return {"id": user.id, "email": user.email, "name": user.name, "role": user.role.value}


@router.patch("/me")
def update_me(payload: ProfileUpdateIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    user.name = payload.name.strip()
    db.commit()
    db.refresh(user)
    return {"id": user.id, "email": user.email, "name": user.name, "role": user.role.value}


@router.post("/password")
def change_password(payload: PasswordChangeIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if not verify_password(payload.current_password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    user.hashed_password = hash_password(payload.new_password)
    db.commit()
    return {"status": "updated"}


@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordIn, db: Session = Depends(get_db)):
    result = {"message": "If this email is registered, a password reset link has been prepared."}
    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        return result
    token = secrets.token_urlsafe(32)
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    db.add(PasswordResetToken(user_id=user.id, token_hash=token_hash, expires_at=datetime.utcnow() + timedelta(minutes=30)))
    db.commit()
    if get_settings().password_reset_preview:
        result["reset_url"] = f"{get_settings().frontend_url}/reset-password?token={token}"
    return result


@router.post("/reset-password")
def reset_password(payload: ResetPasswordIn, db: Session = Depends(get_db)):
    token_hash = hashlib.sha256(payload.token.encode()).hexdigest()
    reset = db.query(PasswordResetToken).filter(
        PasswordResetToken.token_hash == token_hash,
        PasswordResetToken.used_at.is_(None),
        PasswordResetToken.expires_at > datetime.utcnow(),
    ).first()
    if not reset:
        raise HTTPException(status_code=400, detail="This reset link is invalid or has expired")
    user = db.get(User, reset.user_id)
    if not user:
        raise HTTPException(status_code=400, detail="Account could not be recovered")
    user.hashed_password = hash_password(payload.new_password)
    reset.used_at = datetime.utcnow()
    db.commit()
    return {"status": "updated", "message": "Password reset complete. You can now sign in."}


def preferences_out(preferences: AccountPreference):
    return {
        "paymentAlerts": preferences.payment_alerts,
        "riskAlerts": preferences.risk_alerts,
        "weeklyDigest": preferences.weekly_digest,
        "currency": preferences.currency,
        "timezone": preferences.timezone,
    }


@router.get("/preferences")
def get_preferences(db: Session = Depends(get_db), user: User = Depends(current_user)):
    preferences = db.query(AccountPreference).filter(AccountPreference.user_id == user.id).first()
    if not preferences:
        preferences = AccountPreference(user_id=user.id)
        db.add(preferences)
        db.commit()
        db.refresh(preferences)
    return preferences_out(preferences)


@router.patch("/preferences")
def update_preferences(payload: AccountPreferencesIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    preferences = db.query(AccountPreference).filter(AccountPreference.user_id == user.id).first()
    if not preferences:
        preferences = AccountPreference(user_id=user.id)
        db.add(preferences)
    preferences.payment_alerts = payload.paymentAlerts
    preferences.risk_alerts = payload.riskAlerts
    preferences.weekly_digest = payload.weeklyDigest
    preferences.currency = payload.currency
    preferences.timezone = payload.timezone
    db.commit()
    db.refresh(preferences)
    return preferences_out(preferences)
