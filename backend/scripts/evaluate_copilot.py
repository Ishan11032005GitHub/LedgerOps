"""Measure Copilot grounding against the account data returned by LedgerOps APIs."""

import argparse
import json
import time
from urllib.error import HTTPError
from urllib.request import Request, urlopen


def request_json(base_url: str, path: str, *, token: str | None = None, payload: dict | None = None) -> dict | list:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = Request(
        f"{base_url.rstrip('/')}{path}",
        data=json.dumps(payload).encode() if payload is not None else None,
        headers=headers,
        method="POST" if payload is not None else "GET",
    )
    try:
        with urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode())
    except HTTPError as exc:
        raise RuntimeError(f"{path} returned HTTP {exc.code}: {exc.read().decode()}") from exc


def contains_all(answer: str, values: list[object]) -> bool:
    normalized = answer.replace(",", "").lower()
    for value in values:
        expected = str(value).replace(",", "").lower()
        if expected in normalized:
            continue
        if value == 0 and any(term in normalized for term in {"no ", "none", "zero"}):
            continue
        return False
    return True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://localhost:8000")
    parser.add_argument("--email", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()

    login = request_json(
        args.base_url,
        "/api/auth/login",
        payload={"email": args.email, "password": args.password},
    )
    token = login["access_token"]
    dashboard = request_json(args.base_url, "/api/dashboard", token=token)
    payments = request_json(args.base_url, "/api/payments", token=token)
    invoices = request_json(args.base_url, "/api/invoices", token=token)
    clients = request_json(args.base_url, "/api/customers", token=token)

    pending = sum(item["status"] == "pending" for item in invoices)
    overdue = dashboard["pending_invoices"]
    review_clients = sum(
        item["risk_rating"] in {"Medium", "High"}
        or item["kyc_status"].strip().lower() not in {"verified", "demo verified", "approved", "clear"}
        for item in clients
    )
    cases = [
        ("How many payments are recorded?", [len(payments)]),
        ("How many invoices are pending?", [pending]),
        ("How many clients need risk or KYC review?", [review_clients]),
        ("What is our reporting currency?", [dashboard["reporting_currency"]]),
        ("Summarize the current payment and invoice counts.", [len(payments), overdue]),
    ]

    results = []
    for question, expected in cases:
        started = time.perf_counter()
        response = request_json(
            args.base_url,
            "/api/copilot",
            token=token,
            payload={"question": question, "history": []},
        )
        elapsed_ms = round((time.perf_counter() - started) * 1000, 1)
        passed = contains_all(response["answer"], expected)
        results.append(
            {
                "question": question,
                "expected": expected,
                "passed": passed,
                "latency_ms": elapsed_ms,
                "model": response.get("model"),
                "answer": response["answer"],
            }
        )

    passed = sum(item["passed"] for item in results)
    output = {
        "account": args.email,
        "measurement": "factual grounding against live LedgerOps account API responses",
        "accuracy_percent": round(passed / len(results) * 100, 1),
        "passed": passed,
        "total": len(results),
        "average_latency_ms": round(sum(item["latency_ms"] for item in results) / len(results), 1),
        "results": results,
        "limitations": [
            "This measures factual grounding for a small deterministic question set.",
            "It does not measure financial-advice quality, legal correctness, or unseen real-world questions.",
            "Use imported and independently verified account data for a real-data claim.",
        ],
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
