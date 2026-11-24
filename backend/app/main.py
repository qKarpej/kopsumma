import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import errors
from app.routers import auth, imports, portfolio

app = FastAPI(title="Kopsumma API", version="0.1.0")
errors.install(app)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o for o in os.getenv("CORS_ORIGINS", "").split(",") if o],
    # izstrādē: jebkurš localhost ports un lokālais tīkls (flutter run -d chrome, docker web)
    allow_origin_regex=os.getenv(
        "CORS_ORIGIN_REGEX", r"http://(localhost|127\.0\.0\.1|192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+)(:\d+)?"),
    allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
    allow_methods=["GET", "POST", "DELETE"],
    expose_headers=["Content-Disposition"],
)
app.include_router(auth.router)
app.include_router(imports.router)
app.include_router(imports.platforms_router)
app.include_router(portfolio.router)


@app.get("/health")
def health():
    return {"status": "ok"}
