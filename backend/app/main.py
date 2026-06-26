from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .config import get_settings
from .database import SessionLocal, engine
from .routers import auth, intelligence, payment_app, resources, webhooks
from .seed import seed
from .services.security import security_middleware
from .services.readiness import deployment_readiness
from sqlalchemy import text


settings = get_settings()
if settings.environment == "production":
    if settings.jwt_secret in {"dev-secret", "local-dev-change-me", "change-me-in-production"} or len(settings.jwt_secret) < 32:
        raise RuntimeError("Production JWT_SECRET must be a unique value of at least 32 characters")
    if "*" in settings.origins:
        raise RuntimeError("Production CORS_ORIGINS cannot contain a wildcard")

@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.environment != "production" or settings.demo_only:
        db = SessionLocal()
        try:
            seed(db)
        finally:
            db.close()
    yield


app = FastAPI(title="LedgerOps API", version="1.0.0", lifespan=lifespan)
app.middleware("http")(security_middleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok", "service": "backend"}


@app.get("/ready")
def ready():
    db = SessionLocal()
    try:
        db.execute(text("SELECT 1"))
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Database is unavailable") from exc
    finally:
        db.close()
    deployment = deployment_readiness(settings, engine)
    if settings.environment == "production" and not deployment["ready"]:
        raise HTTPException(status_code=503, detail={"message": "Deployment is not production-ready", **deployment})
    return {"status": "ready", "service": "backend", "deployment": deployment}


@app.get("/api/system/readiness")
def system_readiness():
    return deployment_readiness(settings, engine)


app.include_router(auth.router)
app.include_router(resources.router)
app.include_router(payment_app.router)
app.include_router(webhooks.router)
app.include_router(intelligence.router)
