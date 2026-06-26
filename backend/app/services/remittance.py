from datetime import datetime


def _pdf_escape(value: object) -> str:
    return str(value or "").replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def build_remittance_pdf(*, workspace: str, recipient: str, payer: str, payer_email: str, amount: float,
                         currency: str, purpose_code: str, reference: str, paid_at: datetime,
                         payment_rail: str, payment_status: str) -> bytes:
    lines = [
        ("LedgerOps", 20, True),
        ("Remittance advice", 16, True),
        ("", 11, False),
        (f"Workspace: {workspace}", 11, False),
        (f"Recipient: {recipient}", 11, False),
        (f"Payer: {payer or 'Not supplied'}", 11, False),
        (f"Payer email: {payer_email or 'Not supplied'}", 11, False),
        ("", 11, False),
        (f"Amount received: {currency} {amount:,.2f}", 14, True),
        (f"Purpose code: {purpose_code}", 11, False),
        (f"Payment reference: {reference}", 11, False),
        (f"Payment rail: {payment_rail}", 11, False),
        (f"Status: {payment_status.title()}", 11, False),
        (f"Settlement recorded: {paid_at.strftime('%d %b %Y, %H:%M UTC')}", 11, False),
        ("", 11, False),
        ("This document confirms that LedgerOps recorded the payment shown above.", 10, False),
        ("It is a remittance advice, not a bank statement or tax invoice.", 10, False),
    ]

    content = ["BT", "50 790 Td"]
    first = True
    for text, size, bold in lines:
        if not first:
            content.append("0 -24 Td" if size >= 14 else "0 -18 Td")
        first = False
        font = "F2" if bold else "F1"
        content.extend([f"/{font} {size} Tf", f"({_pdf_escape(text)}) Tj"])
    content.append("ET")
    stream = "\n".join(content).encode("latin-1", errors="replace")

    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 842] /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> /Contents 4 0 R >>",
        b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"\nendstream",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>",
    ]
    pdf = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for index, obj in enumerate(objects, start=1):
        offsets.append(len(pdf))
        pdf.extend(f"{index} 0 obj\n".encode())
        pdf.extend(obj)
        pdf.extend(b"\nendobj\n")
    xref = len(pdf)
    pdf.extend(f"xref\n0 {len(objects) + 1}\n".encode())
    pdf.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        pdf.extend(f"{offset:010d} 00000 n \n".encode())
    pdf.extend(f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF".encode())
    return bytes(pdf)


def build_receipt_pdf(*, workspace: str, merchant: str, payer: str, amount: float, currency: str,
                      reference: str, paid_at: datetime, payment_rail: str, purpose: str,
                      refunded_amount: float = 0) -> bytes:
    lines = [
        ("LedgerOps", 20, True),
        ("Payment receipt", 16, True),
        ("", 11, False),
        (f"Workspace: {workspace}", 11, False),
        (f"Merchant: {merchant}", 11, False),
        (f"Payer: {payer}", 11, False),
        ("", 11, False),
        (f"Amount paid: {currency} {amount:,.2f}", 14, True),
        (f"Amount refunded: {currency} {refunded_amount:,.2f}", 11, False),
        (f"Purpose: {purpose}", 11, False),
        (f"Payment reference: {reference}", 11, False),
        (f"Payment rail: {payment_rail}", 11, False),
        (f"Paid at: {paid_at.strftime('%d %b %Y, %H:%M UTC')}", 11, False),
        ("", 11, False),
        ("This receipt reflects the payment state recorded by LedgerOps.", 10, False),
    ]
    content = ["BT", "50 790 Td"]
    first = True
    for text, size, bold in lines:
        if not first:
            content.append("0 -24 Td" if size >= 14 else "0 -18 Td")
        first = False
        content.extend([f"/{'F2' if bold else 'F1'} {size} Tf", f"({_pdf_escape(text)}) Tj"])
    content.append("ET")
    stream = "\n".join(content).encode("latin-1", errors="replace")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 842] /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> /Contents 4 0 R >>",
        b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"\nendstream",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>",
    ]
    pdf = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for index, obj in enumerate(objects, start=1):
        offsets.append(len(pdf))
        pdf.extend(f"{index} 0 obj\n".encode())
        pdf.extend(obj)
        pdf.extend(b"\nendobj\n")
    xref = len(pdf)
    pdf.extend(f"xref\n0 {len(objects) + 1}\n".encode())
    pdf.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        pdf.extend(f"{offset:010d} 00000 n \n".encode())
    pdf.extend(f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF".encode())
    return bytes(pdf)
