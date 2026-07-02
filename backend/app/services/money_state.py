from fastapi import HTTPException


PAYMENT_TRANSITIONS = {
    "processing": {"settled", "failed", "cancelled"},
    "settled": {"partially_refunded", "refunded", "disputed"},
    "partially_refunded": {"refunded", "disputed"},
    "refunded": set(),
    "disputed": {"partially_refunded", "refunded"},
    "failed": set(),
    "cancelled": set(),
}

QUICKLINK_TRANSITIONS = {
    "pending_review": {"active", "disabled", "expired"},
    "active": {"paid", "expired", "disabled"},
    "paid": {"partially_refunded", "refunded", "disputed"},
    "partially_refunded": {"refunded", "disputed"},
    "refunded": set(),
    "disputed": {"partially_refunded", "refunded"},
    "expired": set(),
    "disabled": set(),
}


def transition_payment(payment, target: str) -> None:
    if payment.status == target:
        return
    allowed = PAYMENT_TRANSITIONS.get(payment.status, set())
    if target not in allowed:
        raise HTTPException(status_code=409, detail=f"Invalid payment status transition: {payment.status} -> {target}")
    payment.status = target


def transition_quicklink(link, target: str) -> None:
    if link.status == target:
        return
    allowed = QUICKLINK_TRANSITIONS.get(link.status, set())
    if target not in allowed:
        raise HTTPException(status_code=409, detail=f"Invalid QuickLink status transition: {link.status} -> {target}")
    link.status = target
