from sqlalchemy.orm import Session
from .models import User


def account_user_ids(db: Session, user: User) -> list[int]:
    if user.account_type == "company" and user.workspace_name:
        ids = db.query(User.id).filter(
            User.account_type == "company",
            User.workspace_name == user.workspace_name,
            User.is_active.is_(True),
        ).all()
        return [item[0] for item in ids] or [user.id]
    return [user.id]
