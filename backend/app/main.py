from fastapi import FastAPI

from app import errors
from app.routers import auth, imports

app = FastAPI(title="Kopsumma API", version="0.1.0")
errors.install(app)
app.include_router(auth.router)
app.include_router(imports.router)


@app.get("/health")
def health():
    return {"status": "ok"}
