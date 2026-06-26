from sqlalchemy.orm import Session
from ..models import AuditLog, User


def record_audit(
    db: Session,
    *,
    user: User | None,
    action: str,
    entity_type: str,
    entity_id: object | None = None,
    outcome: str = "success",
    details: dict | None = None,
    request_id: str | None = None,
) -> AuditLog:
    entry = AuditLog(
        user_id=user.id if user else None,
        workspace_name=user.workspace_name if user else None,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else None,
        outcome=outcome,
        details=details or {},
        request_id=request_id,
    )
    db.add(entry)
    db.flush()
    return entry
