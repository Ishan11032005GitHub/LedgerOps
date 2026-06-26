from email.message import EmailMessage
import smtplib

from ..config import get_settings


def send_account_email(*, recipient: str, subject: str, heading: str, message: str, action_url: str, action_label: str) -> bool:
    settings = get_settings()
    if not settings.smtp_host or not settings.smtp_from_email:
        return False
    email = EmailMessage()
    email["From"] = settings.smtp_from_email
    email["To"] = recipient
    email["Subject"] = subject
    email.set_content(f"{heading}\n\n{message}\n\n{action_label}: {action_url}\n")
    email.add_alternative(
        f"""<!doctype html>
<html><body style="font-family:Arial,sans-serif;color:#111827">
  <h2>{heading}</h2>
  <p>{message}</p>
  <p><a href="{action_url}" style="background:#0f1720;color:white;padding:12px 18px;text-decoration:none;border-radius:6px">{action_label}</a></p>
  <p style="color:#64748b;font-size:12px">If you did not request this, you can ignore this email.</p>
</body></html>""",
        subtype="html",
    )
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as client:
        if settings.smtp_use_tls:
            client.starttls()
        if settings.smtp_username:
            client.login(settings.smtp_username, settings.smtp_password)
        client.send_message(email)
    return True
