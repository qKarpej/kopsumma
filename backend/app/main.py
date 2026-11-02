import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import errors
from app.routers import auth, imports, portfolio

app = FastAPI(title="Kopsumma API", version="0.1.0")
errors.install(app)
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:5000").split(","),
    allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
    allow_methods=["GET", "POST", "DELETE"],
)
app.include_router(auth.router)
app.include_router(imports.router)
app.include_router(portfolio.router)


@app.get("/health")
def health():
    return {"status": "ok"}
