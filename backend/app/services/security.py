import time
import uuid
from collections import defaultdict, deque
import redis
from fastapi import Request
from fastapi.responses import JSONResponse
from ..config import get_settings


_local_windows: dict[str, deque[float]] = defaultdict(deque)


def _limit_for(request: Request) -> int | None:
    settings = get_settings()
    if request.url.path in {"/api/auth/login", "/api/auth/signup", "/api/auth/forgot-password", "/api/auth/reset-password"}:
        return settings.rate_limit_auth_per_minute
    if request.url.path.startswith("/api/") and request.method in {"POST", "PUT", "PATCH", "DELETE"}:
        return settings.rate_limit_mutations_per_minute
    return None


def _client_key(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for", "").split(",")[0].strip()
    host = forwarded or (request.client.host if request.client else "unknown")
    return f"{host}:{request.url.path}"


def _allowed(key: str, limit: int) -> tuple[bool, int]:
    now = time.time()
    try:
        client = redis.from_url(get_settings().redis_url, decode_responses=True, socket_timeout=0.25)
        bucket = f"ledgerops:rate:{key}:{int(now // 60)}"
        count = client.incr(bucket)
        if count == 1:
            client.expire(bucket, 65)
        return count <= limit, max(limit - count, 0)
    except redis.RedisError:
        window = _local_windows[key]
        while window and window[0] <= now - 60:
            window.popleft()
        if len(window) >= limit:
            return False, 0
        window.append(now)
        return True, max(limit - len(window), 0)


async def security_middleware(request: Request, call_next):
    request_id = request.headers.get("x-request-id") or str(uuid.uuid4())
    limit = _limit_for(request)
    remaining = None
    if limit:
        allowed, remaining = _allowed(_client_key(request), limit)
        if not allowed:
            response = JSONResponse({"detail": "Too many requests. Please retry shortly."}, status_code=429)
            response.headers["Retry-After"] = "60"
            response.headers["X-Request-ID"] = request_id
            return response
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    if request.url.path in {"/docs", "/redoc", "/openapi.json"}:
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; "
            "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
            "img-src 'self' data: https://fastapi.tiangolo.com; frame-ancestors 'none'; base-uri 'self'"
        )
    else:
        response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'"
    if get_settings().environment == "production":
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    if remaining is not None:
        response.headers["X-RateLimit-Remaining"] = str(remaining)
    return response
